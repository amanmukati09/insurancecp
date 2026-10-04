-- =============================================================================
-- ICPS Database - 20_sp_lifecycle_claim_transitions.sql
-- Lifecycle procedures (task 5.1): claim creation (FNOL) and status/adjuster
-- transition procedures.
--
-- Dialect: MySQL 8.x
--
-- Procedures in this file:
--   1. sp_claim_create_with_fnol   - transactional, composed, error-handled
--   2. sp_claim_transition_status  - transactional, optimistic concurrency
--   3. sp_claim_assign_adjuster    - transactional
--
-- Column/table names match 01_ddl_core.sql, 02_ddl_financial.sql, and
-- 04_ddl_lookup_audit.sql exactly:
--   claim(claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
--         loss_description, status, under_fraud_review, net_paid_amount,
--         version, created_at, updated_at)
--   claim_status_history(history_id, claim_id, prior_status, new_status,
--         changed_by, changed_at, note)
--   claim_adjuster_assignment_history(assignment_id, claim_id,
--         prior_adjuster_id, new_adjuster_id, assigned_at)
--   reserve(reserve_id, claim_id, current_amount, recommended_amount, updated_at)
--   policy_reference(policy_reference_id, policy_number, policy_type,
--         coverage_limit, deductible, effective_start_date, effective_end_date)
--   adjuster(adjuster_id, username, first_name, last_name, is_active, created_at)
--   claim_status_transition_rule(prior_status, new_status)
--   sp_execution_log(log_id, procedure_name, status, error_message, executed_at)
--
-- Procedures invoked (composition, Req 16.6):
--   sp_policy_reference_validate_date_range (10_sp_crud_claimant_adjuster_policy.sql)
--   sp_adjuster_is_active (10_sp_crud_claimant_adjuster_policy.sql)
--   sp_csh_create logic is inlined directly (rather than CALLed) inside each
--   procedure below so that the INSERT participates in the same transaction/
--   handler scope without nested-handler complications; sp_claim_create_with_fnol
--   additionally demonstrates composition by CALLing sp_policy_reference_validate_date_range.
--
-- Reserve default note: sp_claim_create_with_fnol inserts a default `reserve`
-- row with current_amount = 1.00. The `reserve.current_amount` column has a
-- CHECK (current_amount > 0 ...), so a true zero default is not permitted.
-- 1.00 is used as a clearly-a-placeholder minimum reserve to be set properly
-- by an Adjuster via sp_reserve_set_amount once damage assessments exist.
--
-- LOAD ORDER NOTE: Requires 01_ddl_core.sql, 02_ddl_financial.sql, and
-- 04_ddl_lookup_audit.sql to have been executed first (claim, reserve,
-- claim_status_history, sp_execution_log), and 10_sp_crud_claimant_adjuster_policy.sql
-- to have been loaded first (sp_policy_reference_validate_date_range,
-- sp_adjuster_is_active). This file is loaded (not executed) as part of
-- task 5.1. Task 5.6 executes all lifecycle procedure files together
-- against the real `icps` schema.
-- =============================================================================
SET NAMES utf8mb4;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_claim_create_with_fnol
--
-- Req 1.2, 1.3, 1.5, 12.2, 12.3, 12.4, 12.5, 16.5, 16.6.
--
-- Validates the referenced Policy_Reference exists and that the loss date
-- falls within its effective date range (via sp_policy_reference_validate_date_range),
-- then atomically inserts the claim (status='Open', version=0), the initial
-- claim_status_history row (prior_status NULL -> new_status 'Open'), and a
-- default reserve row, all within a single transaction. On any SQL error the
-- exit handler rolls back, writes a FAILURE row to sp_execution_log, and
-- returns a descriptive error message via p_error_message with p_new_claim_id
-- set to NULL.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_create_with_fnol$$
CREATE PROCEDURE sp_claim_create_with_fnol(
    IN  p_claimant_id          BIGINT,
    IN  p_policy_reference_id  BIGINT,
    IN  p_loss_date            DATE,
    IN  p_loss_description     VARCHAR(2000),
    OUT p_new_claim_id         BIGINT,
    OUT p_error_message        VARCHAR(1000)
)
BEGIN
    DECLARE v_policy_exists      TINYINT   DEFAULT 0;
    DECLARE v_date_in_range_flag TINYINT   DEFAULT 0;
    DECLARE v_history_id         BIGINT;
    DECLARE v_err_message         VARCHAR(1000);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_message = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_claim_create_with_fnol', 'FAILURE', v_err_message, NOW());
        SET p_error_message = v_err_message;
        SET p_new_claim_id = NULL;
    END;

    START TRANSACTION;

    -- Validate the Policy_Reference exists (Req 12.2, 12.3).
    SELECT COUNT(*) INTO v_policy_exists
    FROM policy_reference
    WHERE policy_reference_id = p_policy_reference_id;

    IF v_policy_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Referenced Policy_Reference could not be found';
    END IF;

    -- Validate the loss date falls within the Policy_Reference's effective
    -- date range (Req 12.4, 12.5), composing sp_policy_reference_validate_date_range.
    CALL sp_policy_reference_validate_date_range(
        p_policy_reference_id, p_loss_date, v_date_in_range_flag
    );

    IF v_date_in_range_flag = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Loss date is outside the Policy_Reference effective date range';
    END IF;

    -- Insert the Claim with status='Open', version=0 (Req 1.2).
    INSERT INTO claim (
        claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    ) VALUES (
        p_claimant_id, p_policy_reference_id, NULL, p_loss_date,
        p_loss_description, 'Open', 0, NULL,
        0, NOW(), NOW()
    );
    SET p_new_claim_id = LAST_INSERT_ID();

    -- Insert the initial Claim_Status_History row (Req 1.3): prior_status
    -- NULL, new_status 'Open'. (sp_csh_create logic inlined to stay within
    -- this transaction/handler scope.)
    INSERT INTO claim_status_history (
        claim_id, prior_status, new_status, changed_by, changed_at, note
    ) VALUES (
        p_new_claim_id, NULL, 'Open', 'SYSTEM', NOW(), 'Claim created via FNOL intake'
    );
    SET v_history_id = LAST_INSERT_ID();

    -- Insert a default Reserve row for the new Claim. current_amount uses a
    -- placeholder of 1.00 (the reserve.current_amount CHECK requires > 0),
    -- to be properly set by an Adjuster via sp_reserve_set_amount.
    INSERT INTO reserve (
        claim_id, current_amount, recommended_amount, updated_at
    ) VALUES (
        p_new_claim_id, 1.00, NULL, NOW()
    );

    COMMIT;

    SET p_error_message = NULL;

    INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
    VALUES ('sp_claim_create_with_fnol', 'SUCCESS', NULL, NOW());
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_transition_status
--
-- Req 6.2, 6.3, 6.5, 6.7, 16.5.
--
-- Transactionally validates and applies a Claim status transition. Locks the
-- claim row (SELECT ... FOR UPDATE), checks the claim exists, checks the
-- caller's expected version against the current version for optimistic
-- concurrency (Req 6.7), validates the (current_status, p_new_status) pair
-- against claim_status_transition_rule (Req 6.2), and -- if valid -- updates
-- the claim and appends a claim_status_history row atomically (Req 6.5).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_transition_status$$
CREATE PROCEDURE sp_claim_transition_status(
    IN  p_claim_id          BIGINT,
    IN  p_new_status        VARCHAR(20),
    IN  p_changed_by        VARCHAR(50),
    IN  p_expected_version  INT,
    OUT p_success_flag      TINYINT,
    OUT p_error_message     VARCHAR(1000)
)
BEGIN
    DECLARE v_current_status  VARCHAR(20);
    DECLARE v_current_version INT;
    DECLARE v_rule_count       INT DEFAULT 0;
    DECLARE v_err_message      VARCHAR(1000);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_message = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_claim_transition_status', 'FAILURE', v_err_message, NOW());
        SET p_success_flag = 0;
        SET p_error_message = v_err_message;
    END;

    START TRANSACTION;

    -- Lock the claim row and read its current status/version.
    SELECT status, version
    INTO v_current_status, v_current_version
    FROM claim
    WHERE claim_id = p_claim_id
    FOR UPDATE;

    IF v_current_status IS NULL THEN
        -- Claim does not exist (Req 6.4).
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = 'Claim not found';
    ELSEIF p_expected_version IS NOT NULL AND p_expected_version <> v_current_version THEN
        -- Optimistic concurrency conflict (Req 6.7): the Claim's status/version
        -- has changed since the caller last read it.
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = CONCAT(
            'Claim status has changed since the request was issued (expected version ',
            p_expected_version, ', current version ', v_current_version, ')'
        );
    ELSE
        -- Validate the requested transition against the allowed lifecycle
        -- sequence (Req 6.2, 6.3).
        SELECT COUNT(*) INTO v_rule_count
        FROM claim_status_transition_rule
        WHERE prior_status = v_current_status
          AND new_status = p_new_status;

        IF v_rule_count = 0 THEN
            ROLLBACK;
            SET p_success_flag = 0;
            SET p_error_message = CONCAT(
                'Transition from ''', v_current_status, ''' to ''', p_new_status,
                ''' is not an allowed transition'
            );
        ELSE
            -- Apply the transition atomically: update claim + append history.
            UPDATE claim
            SET status = p_new_status,
                version = version + 1,
                updated_at = NOW()
            WHERE claim_id = p_claim_id;

            INSERT INTO claim_status_history (
                claim_id, prior_status, new_status, changed_by, changed_at, note
            ) VALUES (
                p_claim_id, v_current_status, p_new_status, p_changed_by, NOW(), NULL
            );

            COMMIT;

            SET p_success_flag = 1;
            SET p_error_message = NULL;

            INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
            VALUES ('sp_claim_transition_status', 'SUCCESS', NULL, NOW());
        END IF;
    END IF;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_assign_adjuster
--
-- Req 3.2, 3.3, 3.4, 16.5.
--
-- Transactionally assigns (or reassigns) an Adjuster to a Claim. Rejects the
-- assignment if the target Adjuster is inactive or does not exist (Req 3.4,
-- composing sp_adjuster_is_active), leaving any existing assignment
-- unchanged. On success, updates claim.adjuster_id, records the prior/new
-- adjuster in claim_adjuster_assignment_history, and appends a
-- claim_status_history note row (no actual status change) documenting the
-- assignment (Req 3.2, 3.3).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_assign_adjuster$$
CREATE PROCEDURE sp_claim_assign_adjuster(
    IN  p_claim_id          BIGINT,
    IN  p_new_adjuster_id   BIGINT,
    IN  p_changed_by        VARCHAR(50),
    OUT p_success_flag      TINYINT,
    OUT p_error_message     VARCHAR(1000)
)
BEGIN
    DECLARE v_adjuster_active_flag TINYINT;
    DECLARE v_prior_adjuster_id     BIGINT;
    DECLARE v_current_status        VARCHAR(20);
    DECLARE v_err_message            VARCHAR(1000);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_message = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_claim_assign_adjuster', 'FAILURE', v_err_message, NOW());
        SET p_success_flag = 0;
        SET p_error_message = v_err_message;
    END;

    START TRANSACTION;

    -- Check the target Adjuster is active (Req 3.4), composing sp_adjuster_is_active.
    CALL sp_adjuster_is_active(p_new_adjuster_id, v_adjuster_active_flag);

    IF v_adjuster_active_flag IS NULL OR v_adjuster_active_flag = 0 THEN
        -- Adjuster is inactive or does not exist: reject, leave any existing
        -- assignment unchanged.
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = 'Adjuster is inactive and cannot be assigned';
    ELSE
        -- Capture current adjuster_id (may be NULL) and current status, and
        -- lock the claim row.
        SELECT adjuster_id, status
        INTO v_prior_adjuster_id, v_current_status
        FROM claim
        WHERE claim_id = p_claim_id
        FOR UPDATE;

        IF v_current_status IS NULL THEN
            ROLLBACK;
            SET p_success_flag = 0;
            SET p_error_message = 'Claim not found';
        ELSE
            UPDATE claim
            SET adjuster_id = p_new_adjuster_id,
                updated_at = NOW()
            WHERE claim_id = p_claim_id;

            INSERT INTO claim_adjuster_assignment_history (
                claim_id, prior_adjuster_id, new_adjuster_id, assigned_at
            ) VALUES (
                p_claim_id, v_prior_adjuster_id, p_new_adjuster_id, NOW()
            );

            INSERT INTO claim_status_history (
                claim_id, prior_status, new_status, changed_by, changed_at, note
            ) VALUES (
                p_claim_id, v_current_status, v_current_status, p_changed_by, NOW(),
                CONCAT('Adjuster assigned/reassigned: prior_adjuster_id=',
                       IFNULL(v_prior_adjuster_id, 'NULL'),
                       ', new_adjuster_id=', p_new_adjuster_id)
            );

            COMMIT;

            SET p_success_flag = 1;
            SET p_error_message = NULL;

            INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
            VALUES ('sp_claim_assign_adjuster', 'SUCCESS', NULL, NOW());
        END IF;
    END IF;
END$$

DELIMITER ;
