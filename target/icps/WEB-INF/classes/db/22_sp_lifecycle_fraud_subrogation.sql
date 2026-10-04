-- =============================================================================
-- 22_sp_lifecycle_fraud_subrogation.sql
-- Insurance Claims Processing System (ICPS)
--
-- Lifecycle business logic procedures: fraud scoring and subrogation.
--
-- LOAD ORDER: Run after 01_ddl_core.sql through 04_ddl_lookup_audit.sql have
-- created all 23 tables, and after 10_sp_crud_*.sql through 14_sp_crud_*.sql
-- have created the CRUD procedure library (this file composes
-- sp_sub_sum_recovered_by_claim and sp_sub_validate_claim_status from
-- 14_sp_crud_document_litigation_subrogation.sql).
--
-- Requirements: 8.3, 8.4, 8.5 (fraud score recompute + Under Fraud Review
-- toggle), 11.2, 11.3, 11.4, 11.5, 11.6 (subrogation record creation with
-- Claim-status eligibility + recovery-amount range validation + net paid
-- amount recomputation).
-- =============================================================================
-- #############################################################################
-- ## sp_fraud_score_recompute
-- ##
-- ## Requirement 8.3: sums score_weight across all active (is_active = 1)
-- ## Fraud_Flag rows for the Claim, on a 0-100 scale (capped at 100 via
-- ## LEAST, since individual score_weight values are already constrained to
-- ## 0-100 but an accumulation of several active flags can exceed 100).
-- ## Requirement 8.4: when the new score exceeds the configured threshold
-- ## (fraud_score_config.FRAUD_REVIEW_THRESHOLD, default 70 if the config
-- ## row is missing), marks the Claim "Under Fraud Review".
-- ## Requirement 8.5: when the new score no longer exceeds the threshold,
-- ## clears the "Under Fraud Review" indicator. Both directions are handled
-- ## by the single UPDATE statement based on the > comparison below.
-- ##
-- ## Guard: if the Claim does not exist, returns p_new_score = 0 and
-- ## p_under_review_flag = 0 without raising a SQL error (no FK violation
-- ## on the fraud_score insert, no-op on the claim update).
-- #############################################################################
DROP PROCEDURE IF EXISTS sp_fraud_score_recompute;
DROP PROCEDURE IF EXISTS sp_subrogation_record_create;
DELIMITER $$
CREATE PROCEDURE sp_fraud_score_recompute(
    IN p_claim_id BIGINT,
    OUT p_new_score INT,
    OUT p_under_review_flag TINYINT(1)
)
BEGIN
    DECLARE v_sum_weight INT;
    DECLARE v_threshold INT;
    DECLARE v_claim_exists TINYINT(1);
    -- Guard: confirm the Claim exists before touching fraud_score (which has
    -- an FK to claim.claim_id) or claim itself. Non-existent claim_id returns
    -- a clean zero result instead of a SQL error.
    SELECT COUNT(*) INTO v_claim_exists FROM claim WHERE claim_id = p_claim_id;
    IF v_claim_exists = 0 THEN
        SET p_new_score = 0;
        SET p_under_review_flag = 0;
    ELSE
        -- Sum score_weight across active Fraud_Flag rows for the Claim.
        -- COALESCE guards against a Claim with no active flags (NULL sum -> 0).
        SELECT COALESCE(SUM(score_weight), 0)
        INTO v_sum_weight
        FROM fraud_flag
        WHERE claim_id = p_claim_id
          AND is_active = 1;
        -- Cap at 100 to respect the 0-100 fraud score scale (Req 8.3).
        SET p_new_score = LEAST(100, v_sum_weight);
        -- Read the configurable threshold; default to 70 if the config row is
        -- missing (Req 8.4's "default 70").
        SELECT COALESCE(
            (SELECT CAST(config_value AS SIGNED)
             FROM fraud_score_config
             WHERE config_key = 'FRAUD_REVIEW_THRESHOLD'),
            70
        )
        INTO v_threshold;
        -- Upsert the fraud_score snapshot row for the Claim.
        INSERT INTO fraud_score (claim_id, score, threshold_used, computed_at)
        VALUES (p_claim_id, p_new_score, v_threshold, NOW())
        ON DUPLICATE KEY UPDATE
            score = p_new_score,
            threshold_used = v_threshold,
            computed_at = NOW();
        -- Determine the Under Fraud Review indicator from the new score vs.
        -- threshold comparison.
        SET p_under_review_flag = IF(p_new_score > v_threshold, 1, 0);
        -- Toggle claim.under_fraud_review accordingly (Req 8.4 set / Req 8.5
        -- clear -- both directions handled by this single UPDATE).
        UPDATE claim
        SET under_fraud_review = p_under_review_flag
        WHERE claim_id = p_claim_id;
    END IF;
END$$
DELIMITER ;
-- #############################################################################
-- ## sp_subrogation_record_create (transactional)
-- ##
-- ## Requirement 11.2/11.3: only creates the Subrogation_Record if the
-- ## Claim's status is 'Settled' or 'Closed' (via sp_sub_validate_claim_status).
-- ## Requirement 11.4/11.5: validates the recovery amount is between 0.01 and
-- ## the Claim's current net_paid_amount, inclusive.
-- ## Requirement 11.6: recomputes claim.net_paid_amount as
-- ## (net_paid_amount - p_recovery_amount) after a successful recording.
-- ##
-- ## net_paid_amount determination: claim.net_paid_amount is populated when
-- ## a Settlement is approved (sp_settlement_approve sets it from the
-- ## Settlement's payout_amount at approval time). This procedure reads
-- ## claim.net_paid_amount directly; if it is NULL (e.g. a Claim moved to
-- ## 'Settled'/'Closed' without net_paid_amount ever being initialized from
-- ## its Settlement), it falls back to the claim's settlement payout_amount
-- ## via sp_settlement_find_by_claim's underlying table so the recovery-
-- ## amount upper bound still has a value to validate against; the simplest
-- ## documented choice (per the task) is: read claim.net_paid_amount first,
-- ## and only fall back to settlement.payout_amount when it is NULL.
-- #############################################################################
DELIMITER $$
CREATE PROCEDURE sp_subrogation_record_create(
    IN p_claim_id BIGINT,
    IN p_third_party_identifier VARCHAR(100),
    IN p_recovery_amount DECIMAL(12,2),
    IN p_recorded_date DATE,
    OUT p_new_id BIGINT,
    OUT p_error_message VARCHAR(1000)
)
BEGIN
    DECLARE v_is_valid_status TINYINT(1);
    DECLARE v_net_paid_amount DECIMAL(12,2);
    DECLARE v_err_msg VARCHAR(1000);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_subrogation_record_create', 'FAILURE', v_err_msg, NOW());
        SET p_new_id = NULL;
        SET p_error_message = v_err_msg;
    END;
    START TRANSACTION;
    -- Requirement 11.2/11.3: Claim status must be 'Settled' or 'Closed'.
    CALL sp_sub_validate_claim_status(p_claim_id, v_is_valid_status);
    IF v_is_valid_status = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Claim status is invalid for subrogation recording; Claim must be Settled or Closed';
    END IF;
    -- Determine the Claim's current net_paid_amount. If it has not yet been
    -- initialized (NULL), fall back to the Claim's Settlement payout_amount.
    SELECT net_paid_amount
    INTO v_net_paid_amount
    FROM claim
    WHERE claim_id = p_claim_id;
    IF v_net_paid_amount IS NULL THEN
        SELECT payout_amount
        INTO v_net_paid_amount
        FROM settlement
        WHERE claim_id = p_claim_id;
    END IF;
    IF v_net_paid_amount IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unable to determine net paid amount for Claim; no Settlement found';
    END IF;
    -- Requirement 11.4/11.5: recovery amount must be between 0.01 and the
    -- Claim's current net paid amount, inclusive.
    IF p_recovery_amount IS NULL OR p_recovery_amount < 0.01 OR p_recovery_amount > v_net_paid_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Recovery amount is invalid; must be between 0.01 and the Claim current net paid amount';
    END IF;
    -- Insert the Subrogation_Record.
    INSERT INTO subrogation_record (
        claim_id, third_party_identifier, recovery_amount, recorded_date, created_at
    ) VALUES (
        p_claim_id, p_third_party_identifier, p_recovery_amount, p_recorded_date, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
    -- Requirement 11.6: recompute net_paid_amount = prior net_paid_amount -
    -- recovery amount.
    UPDATE claim
    SET net_paid_amount = v_net_paid_amount - p_recovery_amount
    WHERE claim_id = p_claim_id;
    COMMIT;
    SET p_error_message = NULL;
    INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
    VALUES ('sp_subrogation_record_create', 'SUCCESS', NULL, NOW());
END$$
DELIMITER ;
