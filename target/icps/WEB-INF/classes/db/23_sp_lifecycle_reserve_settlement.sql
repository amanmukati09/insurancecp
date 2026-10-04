-- =============================================================================
-- 23_sp_lifecycle_reserve_settlement.sql
-- Insurance Claims Processing System (ICPS)
--
-- Lifecycle stored procedures for Reserve and Settlement calculation
-- (task 5.2 of the implementation plan).
--
-- Contains:
--   1. sp_reserve_set_amount                   (transactional)
--   2. sp_reserve_recalculate_from_assessments  (composed: calls sp_da_sum_by_claim)
--   3. sp_settlement_calculate                  (pure calculation, no transaction needed)
--   4. sp_settlement_approve                    (transactional, composed: calls
--                                                 sp_settlement_calculate and
--                                                 sp_claim_transition_status)
--
-- LOAD ORDER: Run after 01_ddl_core.sql, 02_ddl_financial.sql, and
-- 04_ddl_lookup_audit.sql (sp_execution_log) have created their tables, and
-- after 12_sp_crud_damage_reserve.sql (sp_da_sum_by_claim), 13_sp_crud_settlement_fraud.sql
-- (sp_settlement_exists_for_claim), and 20_sp_lifecycle_claim_transitions.sql
-- (sp_claim_transition_status) have defined the procedures composed below.
--
-- Requirements: 16.5 (transactional + error handling), 16.6 (procedure
-- composition), 5.1, 5.4, 5.5, 4.5, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7.
-- =============================================================================

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_reserve_set_amount: validate and persist a Reserve amount change,
-- appending a Reserve_History row, atomically.
--
-- Requirement 5.1: amount must be numeric, > 0.00, and <= 999999999.99.
-- Requirement 5.4: on success, persists the change and inserts a
-- Reserve_History row recording prior amount, new amount, reason, user,
-- and timestamp.
-- Requirement 5.5: rejects an adjustment that would reduce the Reserve
-- below an existing Settlement's payout_amount (the settlement floor).
-- Requirement 16.5: transactional with explicit error handling; on any
-- SQLEXCEPTION the transaction is rolled back and the failure is logged to
-- sp_execution_log.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_set_amount(
    IN p_claim_id BIGINT,
    IN p_new_amount DECIMAL(12,2),
    IN p_reason VARCHAR(500),
    IN p_changed_by VARCHAR(50),
    OUT p_success_flag TINYINT(1),
    OUT p_error_message VARCHAR(1000)
)
BEGIN
    DECLARE v_reserve_id BIGINT;
    DECLARE v_prior_amount DECIMAL(12,2);
    DECLARE v_settlement_payout DECIMAL(12,2);
    DECLARE v_new_history_id BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success_flag = 0;
        IF p_error_message IS NULL THEN
            SET p_error_message = 'An unexpected database error occurred while setting the reserve amount.';
        END IF;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_reserve_set_amount', 'FAILURE', p_error_message, NOW());
    END;

    SET p_success_flag = 0;
    SET p_error_message = NULL;

    START TRANSACTION;

    -- Requirement 5.1: numeric range validation.
    IF p_new_amount IS NULL OR p_new_amount <= 0.00 OR p_new_amount > 999999999.99 THEN
        SET p_error_message = 'Reserve amount must be greater than 0.00 and must not exceed 999999999.99.';
        ROLLBACK;
    ELSE
        -- Lock the Claim's Reserve row for update to serialize concurrent changes.
        SELECT reserve_id, current_amount
        INTO v_reserve_id, v_prior_amount
        FROM reserve
        WHERE claim_id = p_claim_id
        FOR UPDATE;

        IF v_reserve_id IS NULL THEN
            SET p_error_message = 'No Reserve record exists for the specified Claim.';
            ROLLBACK;
        ELSE
            -- Requirement 5.5: settlement-floor check.
            SELECT payout_amount
            INTO v_settlement_payout
            FROM settlement
            WHERE claim_id = p_claim_id;

            IF v_settlement_payout IS NOT NULL AND p_new_amount < v_settlement_payout THEN
                SET p_error_message = CONCAT(
                    'Reserve cannot be reduced below the existing Settlement payout amount. ',
                    'Minimum allowable Reserve amount is ', v_settlement_payout, '.'
                );
                ROLLBACK;
            ELSE
                UPDATE reserve
                SET current_amount = p_new_amount,
                    updated_at = NOW()
                WHERE claim_id = p_claim_id;

                INSERT INTO reserve_history (
                    reserve_id, prior_amount, new_amount, reason, changed_by, changed_at
                ) VALUES (
                    v_reserve_id, v_prior_amount, p_new_amount, p_reason, p_changed_by, NOW()
                );
                SET v_new_history_id = LAST_INSERT_ID();

                COMMIT;
                SET p_success_flag = 1;
                SET p_error_message = NULL;
            END IF;
        END IF;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_recalculate_from_assessments: recompute a Claim's recommended
-- Reserve amount as the sum of its Damage_Assessment estimated costs.
--
-- Requirement 4.5: recommended Reserve amount equals the sum of estimated
-- costs of all Damage_Assessment rows for the Claim.
-- Requirement 16.6: composition — invokes sp_da_sum_by_claim (defined in
-- 12_sp_crud_damage_reserve.sql) to obtain the sum, demonstrating a
-- procedure that calls another procedure.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_recalculate_from_assessments(
    IN p_claim_id BIGINT,
    OUT p_recommended_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_total DECIMAL(12,2);

    -- Composition: delegate the summation to sp_da_sum_by_claim rather than
    -- duplicating the SUM(...) query here.
    CALL sp_da_sum_by_claim(p_claim_id, v_total);

    UPDATE reserve
    SET recommended_amount = v_total,
        updated_at = NOW()
    WHERE claim_id = p_claim_id;

    SET p_recommended_amount = v_total;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_calculate: compute the Settlement payout amount for a Claim
-- from its Policy_Reference deductible/coverage limit and current Reserve
-- amount, without persisting anything.
--
-- Requirement 7.2: payout = GREATEST(0, reserve.current_amount - deductible)
-- (floored at zero, never negative).
-- Requirement 7.5: if the Policy_Reference is missing a deductible or
-- coverage limit (or the Claim has no Reserve), reject with an error
-- indicating incomplete policy data; p_payout_amount is set to NULL.
-- Requirement 7.7: payout is capped at the Policy_Reference's coverage
-- limit.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_calculate(
    IN p_claim_id BIGINT,
    OUT p_payout_amount DECIMAL(12,2),
    OUT p_error_message VARCHAR(1000)
)
BEGIN
    DECLARE v_deductible DECIMAL(12,2);
    DECLARE v_coverage_limit DECIMAL(12,2);
    DECLARE v_current_amount DECIMAL(12,2);
    DECLARE v_payout DECIMAL(12,2);

    SET p_payout_amount = NULL;
    SET p_error_message = NULL;

    SELECT pr.deductible, pr.coverage_limit, r.current_amount
    INTO v_deductible, v_coverage_limit, v_current_amount
    FROM claim c
    JOIN policy_reference pr ON pr.policy_reference_id = c.policy_reference_id
    LEFT JOIN reserve r ON r.claim_id = c.claim_id
    WHERE c.claim_id = p_claim_id;

    -- Requirement 7.5: incomplete policy data (or missing Reserve) rejects
    -- the calculation.
    IF v_deductible IS NULL OR v_coverage_limit IS NULL OR v_current_amount IS NULL THEN
        SET p_payout_amount = NULL;
        SET p_error_message = 'Policy_Reference data is incomplete; deductible, coverage limit, and a Reserve amount are all required to calculate a Settlement.';
    ELSE
        -- Requirement 7.2: floor at zero.
        SET v_payout = GREATEST(0.00, v_current_amount - v_deductible);
        -- Requirement 7.7: cap at coverage limit.
        SET v_payout = LEAST(v_payout, v_coverage_limit);

        SET p_payout_amount = v_payout;
        SET p_error_message = NULL;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_approve: approve a Settlement for a Claim — validates the
-- Claim is "Approved" and has no existing Settlement, calculates the payout,
-- inserts the Settlement row, and transitions the Claim to "Settled", all
-- atomically.
--
-- Requirement 7.3: only Claims in "Approved" status may be settled.
-- Requirement 7.4: rejects a Settlement submission if one already exists
-- for the Claim.
-- Requirement 7.6: on approval, transitions the Claim to "Settled" and
-- records the Settlement amount, approving user, and approval timestamp.
-- Requirement 16.5: transactional with explicit error handling; on any
-- SQLEXCEPTION the transaction is rolled back and the failure is logged to
-- sp_execution_log.
-- Requirement 16.6: composition — invokes sp_settlement_calculate to derive
-- the payout amount and sp_claim_transition_status (20_sp_lifecycle_claim_transitions.sql)
-- to move the Claim to "Settled".
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_approve(
    IN p_claim_id BIGINT,
    IN p_approved_by VARCHAR(50),
    OUT p_new_settlement_id BIGINT,
    OUT p_error_message VARCHAR(1000)
)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_current_version INT;
    DECLARE v_existing_settlement_count INT;
    DECLARE v_payout DECIMAL(12,2);
    DECLARE v_calc_err VARCHAR(1000);
    DECLARE v_transition_success TINYINT(1);
    DECLARE v_transition_err VARCHAR(1000);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_new_settlement_id = NULL;
        IF p_error_message IS NULL THEN
            SET p_error_message = 'An unexpected database error occurred while approving the settlement.';
        END IF;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_settlement_approve', 'FAILURE', p_error_message, NOW());
    END;

    SET p_new_settlement_id = NULL;
    SET p_error_message = NULL;

    START TRANSACTION;

    -- Requirement 7.3: only "Approved" Claims may be settled.
    SELECT status, version
    INTO v_current_status, v_current_version
    FROM claim
    WHERE claim_id = p_claim_id
    FOR UPDATE;

    IF v_current_status IS NULL THEN
        SET p_error_message = 'The specified Claim was not found.';
        ROLLBACK;
    ELSEIF v_current_status <> 'Approved' THEN
        SET p_error_message = CONCAT(
            'Claim is currently in status ''', v_current_status,
            '''; only Claims in ''Approved'' status may be settled.'
        );
        ROLLBACK;
    ELSE
        -- Requirement 7.4: reject if a Settlement already exists for the Claim.
        SELECT COUNT(*)
        INTO v_existing_settlement_count
        FROM settlement
        WHERE claim_id = p_claim_id;

        IF v_existing_settlement_count > 0 THEN
            SET p_error_message = 'A Settlement already exists for this Claim.';
            ROLLBACK;
        ELSE
            -- Composition: delegate payout calculation to sp_settlement_calculate.
            CALL sp_settlement_calculate(p_claim_id, v_payout, v_calc_err);

            IF v_calc_err IS NOT NULL THEN
                SET p_error_message = v_calc_err;
                ROLLBACK;
            ELSE
                INSERT INTO settlement (
                    claim_id, payout_amount, approved_by, approved_at
                ) VALUES (
                    p_claim_id, v_payout, p_approved_by, NOW()
                );
                SET p_new_settlement_id = LAST_INSERT_ID();

                -- Composition: delegate the status transition (and its own
                -- optimistic-concurrency / history-append logic) to
                -- sp_claim_transition_status (task 5.1).
                CALL sp_claim_transition_status(
                    p_claim_id, 'Settled', p_approved_by, v_current_version,
                    v_transition_success, v_transition_err
                );

                IF v_transition_success = 0 THEN
                    SET p_new_settlement_id = NULL;
                    SET p_error_message = v_transition_err;
                    ROLLBACK;
                ELSE
                    COMMIT;
                    SET p_error_message = NULL;
                END IF;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;
