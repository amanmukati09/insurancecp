-- =============================================================================
-- 21_sp_lifecycle_cursor_integrity.sql
-- Insurance Claims Processing System (ICPS)
--
-- Cursor-based batch integrity sweep over `claim` rows.
--
-- Satisfies Requirement 16.4: "THE ICPS_Database SHALL include at least one
-- stored procedure that uses a cursor to iterate over result rows."
--
-- Dialect: MySQL 8.x.
--
-- Procedure: sp_claim_integrity_sweep
--   A nightly/batch consistency-check procedure. Iterates every row in
--   `claim` (not just non-Closed claims, to keep the sweep simple and
--   complete) via an explicit cursor, and for each claim:
--     1. Ensures a `reserve` row exists for the claim; if missing, inserts
--        a default reserve row (current_amount = 1.00, matching the
--        minimal-default convention used by sp_claim_create_with_fnol) and
--        increments p_reserves_created.
--     2. For claims in 'Settled' or 'Closed' status that have an existing
--        `settlement` row, recomputes `claim.net_paid_amount` as
--        settlement.payout_amount minus the sum of recovered
--        subrogation_record.recovery_amount for the claim, and increments
--        p_net_paid_recomputed. Claims without a settlement row are
--        skipped for this step (nothing to recompute from).
--     3. Increments p_claims_checked for every claim visited by the cursor.
--
-- DECLARE ordering (required by MySQL): variables first, then the cursor,
-- then the NOT FOUND handler. Handler must come after the cursor it
-- depends on, and after all variables it may reference.
-- =============================================================================

DELIMITER $$

CREATE PROCEDURE sp_claim_integrity_sweep(
    OUT p_claims_checked        INT,
    OUT p_reserves_created      INT,
    OUT p_net_paid_recomputed   INT
)
BEGIN
    -- -------------------------------------------------------------------
    -- 1. Variable declarations (must come first)
    -- -------------------------------------------------------------------
    DECLARE done                INT DEFAULT FALSE;
    DECLARE v_claim_id           BIGINT;
    DECLARE v_status             VARCHAR(20);
    DECLARE v_reserve_count       INT;
    DECLARE v_settlement_payout   DECIMAL(12,2);
    DECLARE v_settlement_count    INT;
    DECLARE v_total_recovered      DECIMAL(12,2);
    DECLARE v_new_net_paid          DECIMAL(12,2);

    -- -------------------------------------------------------------------
    -- 2. Cursor declaration (must come after variables, before handlers)
    -- -------------------------------------------------------------------
    DECLARE claim_cursor CURSOR FOR
        SELECT claim_id, status
        FROM claim;

    -- -------------------------------------------------------------------
    -- 3. Handler declaration (must come after the cursor it watches)
    -- -------------------------------------------------------------------
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- -------------------------------------------------------------------
    -- Initialize OUT parameters
    -- -------------------------------------------------------------------
    SET p_claims_checked = 0;
    SET p_reserves_created = 0;
    SET p_net_paid_recomputed = 0;

    OPEN claim_cursor;

    FETCH claim_cursor INTO v_claim_id, v_status;

    WHILE done = FALSE DO

        -- 3a. Ensure a reserve row exists for this claim.
        SELECT COUNT(*) INTO v_reserve_count
        FROM reserve
        WHERE claim_id = v_claim_id;

        IF v_reserve_count = 0 THEN
            INSERT INTO reserve (claim_id, current_amount, recommended_amount, updated_at)
            VALUES (v_claim_id, 1.00, NULL, NOW());

            SET p_reserves_created = p_reserves_created + 1;
        END IF;

        -- 3b. Recompute net_paid_amount for Settled/Closed claims that have
        -- an existing settlement row. Claims without a settlement are
        -- skipped since there is nothing to recompute from.
        IF v_status IN ('Settled', 'Closed') THEN
            SELECT COUNT(*), MAX(payout_amount)
            INTO v_settlement_count, v_settlement_payout
            FROM settlement
            WHERE claim_id = v_claim_id;

            IF v_settlement_count > 0 THEN
                SELECT COALESCE(SUM(recovery_amount), 0.00)
                INTO v_total_recovered
                FROM subrogation_record
                WHERE claim_id = v_claim_id;

                SET v_new_net_paid = v_settlement_payout - v_total_recovered;

                UPDATE claim
                SET net_paid_amount = v_new_net_paid
                WHERE claim_id = v_claim_id;

                SET p_net_paid_recomputed = p_net_paid_recomputed + 1;
            END IF;
        END IF;

        -- 3c. Every claim visited by the cursor counts as checked.
        SET p_claims_checked = p_claims_checked + 1;

        FETCH claim_cursor INTO v_claim_id, v_status;

    END WHILE;

    CLOSE claim_cursor;
END$$

DELIMITER ;
