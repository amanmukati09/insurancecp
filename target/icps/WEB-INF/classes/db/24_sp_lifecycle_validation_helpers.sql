-- ============================================================================
-- ICPS Database - 24_sp_lifecycle_validation_helpers.sql
-- Remaining lifecycle procedures: per-entity validation helpers, claim/reporting
-- helper procedures, and additional transactional procedures (26 total).
-- Task 5.5. Combined with tasks 5.1-5.4 (9 procedures), brings the lifecycle
-- category total to 35 (Req 16.3).
--
-- Dialect: MySQL 8.x
--
-- Column names/tables match 01-04_ddl_*.sql exactly:
--     claimant(claimant_id, first_name, last_name, address_line1, address_city,
--               address_state, address_zip, phone, email, created_at)
--     adjuster(adjuster_id, username, first_name, last_name, is_active, created_at)
--     policy_reference(policy_reference_id, policy_number, policy_type,
--               coverage_limit, deductible, effective_start_date, effective_end_date)
--     claim(claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
--               loss_description, status, under_fraud_review, net_paid_amount,
--               version, created_at, updated_at)
--     claim_status_history(history_id, claim_id, prior_status, new_status,
--               changed_by, changed_at, note)
--     damage_assessment(damage_assessment_id, claim_id, estimated_cost,
--               description, assessment_date, created_at)
--     reserve(reserve_id, claim_id, current_amount, recommended_amount, updated_at)
--     reserve_history(reserve_history_id, reserve_id, prior_amount, new_amount,
--               reason, changed_by, changed_at)
--     settlement(settlement_id, claim_id, payout_amount, approved_by, approved_at)
--     fraud_flag(fraud_flag_id, claim_id, flag_reason, score_weight, is_active,
--               created_at, updated_at)
--     document_metadata(document_metadata_id, claim_id, file_name, document_type,
--               file_size_bytes, storage_reference, uploaded_at)
--     document_type_lookup(document_type, description)
--     litigation_record(litigation_record_id, claim_id, case_reference,
--               filing_date, status, attorney_name, created_at)
--     subrogation_record(subrogation_record_id, claim_id, third_party_identifier,
--               recovery_amount, recorded_date, created_at)
--     sp_execution_log(log_id, procedure_name, status, error_message, executed_at)
--
-- NOTE: This file is loaded (not executed) as part of task 5.5. Task 5.6
-- executes all lifecycle procedure files together against the real `icps`
-- schema. sp_fraud_flag_delete_with_rescore (#25 below) calls
-- sp_fraud_score_recompute(IN p_claim_id; OUT p_new_score, OUT p_under_review_flag),
-- which is defined in 22_sp_lifecycle_fraud_subrogation.sql (task 5.3). That
-- file may not exist on disk yet when this file is authored (parallel task
-- execution) -- the CALL below assumes that exact signature and must be
-- verified against the real file before task 5.6 executes this script.
-- ============================================================================

DELIMITER $$

-- ============================================================================
-- PER-ENTITY FIELD VALIDATORS (8 procedures)
-- Simple IN params, OUT is_valid flag + OUT error_message. Basic NOT NULL /
-- length / range checks matching the validation rules from requirements.md.
-- ============================================================================

-- 1. sp_validate_claimant_fields
-- Validates: Requirements 2.3
DROP PROCEDURE IF EXISTS sp_validate_claimant_fields$$
CREATE PROCEDURE sp_validate_claimant_fields(
    IN  p_first_name     VARCHAR(100),
    IN  p_last_name       VARCHAR(100),
    IN  p_address_state   VARCHAR(2),
    IN  p_email           VARCHAR(150),
    OUT p_is_valid         TINYINT,
    OUT p_error_message   VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_first_name IS NULL OR TRIM(p_first_name) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'first_name is required';
    ELSEIF p_last_name IS NULL OR TRIM(p_last_name) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'last_name is required';
    ELSEIF p_address_state IS NULL OR CHAR_LENGTH(p_address_state) <> 2 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'address_state must be exactly 2 characters';
    ELSEIF p_email IS NOT NULL AND p_email <> '' AND p_email NOT LIKE '%_@_%._%' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'email is not a valid email format';
    END IF;
END$$

-- 2. sp_validate_adjuster_fields
-- Validates: Requirements 3.1
DROP PROCEDURE IF EXISTS sp_validate_adjuster_fields$$
CREATE PROCEDURE sp_validate_adjuster_fields(
    IN  p_username        VARCHAR(50),
    IN  p_first_name      VARCHAR(100),
    IN  p_last_name       VARCHAR(100),
    OUT p_is_valid        TINYINT,
    OUT p_error_message   VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'username is required';
    ELSEIF p_first_name IS NULL OR TRIM(p_first_name) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'first_name is required';
    ELSEIF p_last_name IS NULL OR TRIM(p_last_name) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'last_name is required';
    END IF;
END$$

-- 3. sp_validate_policy_reference_fields
-- Validates: Requirements 12.1
DROP PROCEDURE IF EXISTS sp_validate_policy_reference_fields$$
CREATE PROCEDURE sp_validate_policy_reference_fields(
    IN  p_policy_number           VARCHAR(50),
    IN  p_coverage_limit          DECIMAL(12,2),
    IN  p_deductible              DECIMAL(12,2),
    IN  p_effective_start_date    DATE,
    IN  p_effective_end_date      DATE,
    OUT p_is_valid                TINYINT,
    OUT p_error_message           VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_policy_number IS NULL OR TRIM(p_policy_number) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'policy_number is required';
    ELSEIF p_coverage_limit IS NULL OR p_coverage_limit < 0 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'coverage_limit must be a non-negative value';
    ELSEIF p_deductible IS NULL OR p_deductible < 0 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'deductible must be a non-negative value';
    ELSEIF p_effective_start_date IS NULL OR p_effective_end_date IS NULL THEN
        SET p_is_valid = 0;
        SET p_error_message = 'effective_start_date and effective_end_date are required';
    ELSEIF p_effective_end_date < p_effective_start_date THEN
        SET p_is_valid = 0;
        SET p_error_message = 'effective_end_date must be on or after effective_start_date';
    END IF;
END$$

-- 4. sp_validate_damage_assessment_fields
-- Validates: Requirements 4.3, 4.4
DROP PROCEDURE IF EXISTS sp_validate_damage_assessment_fields$$
CREATE PROCEDURE sp_validate_damage_assessment_fields(
    IN  p_estimated_cost   DECIMAL(12,2),
    IN  p_description      VARCHAR(1000),
    IN  p_assessment_date  DATE,
    OUT p_is_valid         TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_estimated_cost IS NULL OR p_estimated_cost <= 0 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'estimated_cost must be greater than 0.00';
    ELSEIF p_estimated_cost > 999999999.99 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'estimated_cost must not exceed 999999999.99';
    ELSEIF p_description IS NULL OR TRIM(p_description) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'description is required';
    ELSEIF p_assessment_date IS NULL THEN
        SET p_is_valid = 0;
        SET p_error_message = 'assessment_date is required';
    ELSEIF p_assessment_date > CURDATE() THEN
        SET p_is_valid = 0;
        SET p_error_message = 'assessment_date must not be later than the current date';
    END IF;
END$$

-- 5. sp_validate_document_metadata_fields
-- Validates: Requirements 9.3
DROP PROCEDURE IF EXISTS sp_validate_document_metadata_fields$$
CREATE PROCEDURE sp_validate_document_metadata_fields(
    IN  p_file_name           VARCHAR(255),
    IN  p_document_type       VARCHAR(50),
    IN  p_file_size_bytes     BIGINT,
    IN  p_storage_reference   VARCHAR(500),
    OUT p_is_valid            TINYINT,
    OUT p_error_message       VARCHAR(500)
)
BEGIN
    DECLARE v_type_exists INT DEFAULT 0;

    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'file_name is required';
    ELSEIF CHAR_LENGTH(p_file_name) > 255 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'file_name must not exceed 255 characters';
    ELSEIF p_storage_reference IS NULL OR TRIM(p_storage_reference) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'storage_reference is required';
    ELSEIF CHAR_LENGTH(p_storage_reference) > 500 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'storage_reference must not exceed 500 characters';
    ELSEIF p_file_size_bytes IS NULL OR p_file_size_bytes < 0 OR p_file_size_bytes > 2147483647 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'file_size_bytes must be between 0 and 2147483647';
    ELSE
        SELECT COUNT(*) INTO v_type_exists
        FROM document_type_lookup
        WHERE document_type = p_document_type;

        IF v_type_exists = 0 THEN
            SET p_is_valid = 0;
            SET p_error_message = 'document_type is not in the system-defined list';
        END IF;
    END IF;
END$$

-- 6. sp_validate_litigation_fields
-- Validates: Requirements 10.3
DROP PROCEDURE IF EXISTS sp_validate_litigation_fields$$
CREATE PROCEDURE sp_validate_litigation_fields(
    IN  p_case_reference   VARCHAR(100),
    IN  p_filing_date      DATE,
    OUT p_is_valid         TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_case_reference IS NULL OR TRIM(p_case_reference) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'case_reference is required';
    ELSEIF CHAR_LENGTH(p_case_reference) > 100 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'case_reference must not exceed 100 characters';
    ELSEIF p_filing_date IS NULL THEN
        SET p_is_valid = 0;
        SET p_error_message = 'filing_date is required';
    END IF;
END$$

-- 7. sp_validate_fraud_flag_fields
-- Validates: Requirements 8.2
DROP PROCEDURE IF EXISTS sp_validate_fraud_flag_fields$$
CREATE PROCEDURE sp_validate_fraud_flag_fields(
    IN  p_flag_reason      VARCHAR(200),
    IN  p_score_weight     INT,
    OUT p_is_valid         TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_flag_reason IS NULL OR TRIM(p_flag_reason) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'flag_reason is required';
    ELSEIF p_score_weight IS NULL OR p_score_weight < 0 OR p_score_weight > 100 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'score_weight must be between 0 and 100';
    END IF;
END$$

-- 8. sp_validate_subrogation_fields
-- Validates: Requirements 11.4, 11.5
DROP PROCEDURE IF EXISTS sp_validate_subrogation_fields$$
CREATE PROCEDURE sp_validate_subrogation_fields(
    IN  p_third_party_identifier   VARCHAR(100),
    IN  p_recovery_amount          DECIMAL(12,2),
    IN  p_recorded_date            DATE,
    OUT p_is_valid                 TINYINT,
    OUT p_error_message            VARCHAR(500)
)
BEGIN
    SET p_is_valid = 1;
    SET p_error_message = NULL;

    IF p_third_party_identifier IS NULL OR TRIM(p_third_party_identifier) = '' THEN
        SET p_is_valid = 0;
        SET p_error_message = 'third_party_identifier is required';
    ELSEIF p_recorded_date IS NULL THEN
        SET p_is_valid = 0;
        SET p_error_message = 'recorded_date is required';
    ELSEIF p_recovery_amount IS NULL OR p_recovery_amount < 0.01 THEN
        SET p_is_valid = 0;
        SET p_error_message = 'recovery_amount must be at least 0.01';
    END IF;
END$$

-- ============================================================================
-- CLAIM/REPORTING HELPER PROCEDURES (14 procedures)
-- ============================================================================

-- 9. sp_claim_age_in_days
-- Validates: Requirements 3.6
DROP PROCEDURE IF EXISTS sp_claim_age_in_days$$
CREATE PROCEDURE sp_claim_age_in_days(
    IN  p_claim_id   BIGINT,
    OUT p_age_days   INT
)
BEGIN
    SELECT DATEDIFF(CURDATE(), created_at) INTO p_age_days
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

-- 10. sp_claim_check_duplicate_settlement
-- Standalone helper equivalent to sp_settlement_exists_for_claim (task 4.4).
-- Validates: Requirements 7.4
DROP PROCEDURE IF EXISTS sp_claim_check_duplicate_settlement$$
CREATE PROCEDURE sp_claim_check_duplicate_settlement(
    IN  p_claim_id        BIGINT,
    OUT p_has_duplicate   TINYINT
)
BEGIN
    SELECT COUNT(*) INTO p_has_duplicate
    FROM settlement
    WHERE claim_id = p_claim_id;
END$$

-- 11. sp_policy_reference_resolve
-- Resolves a policy_number string to its policy_reference_id. Used by FNOL
-- creation (sp_claim_create_with_fnol, task 5.1).
-- Validates: Requirements 12.2, 12.3
DROP PROCEDURE IF EXISTS sp_policy_reference_resolve$$
CREATE PROCEDURE sp_policy_reference_resolve(
    IN  p_policy_number           VARCHAR(50),
    OUT p_policy_reference_id     BIGINT,
    OUT p_found_flag               TINYINT
)
BEGIN
    SELECT policy_reference_id INTO p_policy_reference_id
    FROM policy_reference
    WHERE policy_number = p_policy_number
    LIMIT 1;

    IF p_policy_reference_id IS NULL THEN
        SET p_found_flag = 0;
    ELSE
        SET p_found_flag = 1;
    END IF;
END$$

-- 12. sp_fraud_review_flag_set
-- Validates: Requirements 8.4
DROP PROCEDURE IF EXISTS sp_fraud_review_flag_set$$
CREATE PROCEDURE sp_fraud_review_flag_set(
    IN  p_claim_id   BIGINT
)
BEGIN
    UPDATE claim
    SET under_fraud_review = 1
    WHERE claim_id = p_claim_id;
END$$

-- 13. sp_fraud_review_flag_clear
-- Validates: Requirements 8.5
DROP PROCEDURE IF EXISTS sp_fraud_review_flag_clear$$
CREATE PROCEDURE sp_fraud_review_flag_clear(
    IN  p_claim_id   BIGINT
)
BEGIN
    UPDATE claim
    SET under_fraud_review = 0
    WHERE claim_id = p_claim_id;
END$$

-- 14. sp_claim_status_history_append
-- Shared composed helper: performs the claim_status_history INSERT and
-- returns the new history_id. Intentionally callable from multiple other
-- procedures (composition, Req 16.6) even though tasks 5.1/5.2 inline their
-- own INSERTs for clarity -- this is an additional standalone reusable
-- version of that same insert, available for any procedure (including the
-- ones below in this file) that needs to append a history row without
-- duplicating the INSERT statement.
-- Validates: Requirements 16.6, 14.1
DROP PROCEDURE IF EXISTS sp_claim_status_history_append$$
CREATE PROCEDURE sp_claim_status_history_append(
    IN  p_claim_id         BIGINT,
    IN  p_prior_status     VARCHAR(20),
    IN  p_new_status       VARCHAR(20),
    IN  p_changed_by       VARCHAR(50),
    IN  p_note             VARCHAR(500),
    OUT p_new_history_id   BIGINT
)
BEGIN
    INSERT INTO claim_status_history (
        claim_id, prior_status, new_status, changed_by, changed_at, note
    ) VALUES (
        p_claim_id, p_prior_status, p_new_status, p_changed_by, NOW(), p_note
    );
    SET p_new_history_id = LAST_INSERT_ID();
END$$

-- 15. sp_claim_count_by_adjuster
DROP PROCEDURE IF EXISTS sp_claim_count_by_adjuster$$
CREATE PROCEDURE sp_claim_count_by_adjuster(
    IN  p_adjuster_id   BIGINT,
    OUT p_total         INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM claim
    WHERE adjuster_id = p_adjuster_id;
END$$

-- 16. sp_claim_count_under_fraud_review
-- Validates: Requirements 8.6
DROP PROCEDURE IF EXISTS sp_claim_count_under_fraud_review$$
CREATE PROCEDURE sp_claim_count_under_fraud_review(
    OUT p_total   INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM claim
    WHERE under_fraud_review = 1;
END$$

-- 17. sp_reserve_history_total_adjustments
-- COUNT of reserve_history rows for a claim's reserve.
DROP PROCEDURE IF EXISTS sp_reserve_history_total_adjustments$$
CREATE PROCEDURE sp_reserve_history_total_adjustments(
    IN  p_claim_id          BIGINT,
    OUT p_total_changes     INT
)
BEGIN
    SELECT COUNT(*) INTO p_total_changes
    FROM reserve_history rh
    INNER JOIN reserve r ON r.reserve_id = rh.reserve_id
    WHERE r.claim_id = p_claim_id;
END$$

-- 18. sp_claim_days_since_last_status_change
DROP PROCEDURE IF EXISTS sp_claim_days_since_last_status_change$$
CREATE PROCEDURE sp_claim_days_since_last_status_change(
    IN  p_claim_id   BIGINT,
    OUT p_days       INT
)
BEGIN
    SELECT DATEDIFF(CURDATE(), MAX(changed_at)) INTO p_days
    FROM claim_status_history
    WHERE claim_id = p_claim_id;
END$$

-- 19. sp_claim_validate_exists
-- Simple existence check with a standard error message, reusable validation
-- helper.
-- Validates: Requirements 6.4
DROP PROCEDURE IF EXISTS sp_claim_validate_exists$$
CREATE PROCEDURE sp_claim_validate_exists(
    IN  p_claim_id        BIGINT,
    OUT p_exists_flag     TINYINT,
    OUT p_error_message   VARCHAR(500)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_count
    FROM claim
    WHERE claim_id = p_claim_id;

    IF v_count = 0 THEN
        SET p_exists_flag = 0;
        SET p_error_message = 'Claim not found';
    ELSE
        SET p_exists_flag = 1;
        SET p_error_message = NULL;
    END IF;
END$$

-- 20. sp_adjuster_validate_assignable
-- Checks existence AND is_active=1, combining into one reusable check.
-- Validates: Requirements 3.4
DROP PROCEDURE IF EXISTS sp_adjuster_validate_assignable$$
CREATE PROCEDURE sp_adjuster_validate_assignable(
    IN  p_adjuster_id      BIGINT,
    OUT p_is_assignable    TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    DECLARE v_is_active TINYINT DEFAULT NULL;

    SELECT is_active INTO v_is_active
    FROM adjuster
    WHERE adjuster_id = p_adjuster_id;

    IF v_is_active IS NULL THEN
        SET p_is_assignable = 0;
        SET p_error_message = 'Adjuster not found';
    ELSEIF v_is_active = 0 THEN
        SET p_is_assignable = 0;
        SET p_error_message = 'Adjuster is inactive and cannot be assigned';
    ELSE
        SET p_is_assignable = 1;
        SET p_error_message = NULL;
    END IF;
END$$

-- 21. sp_claim_get_claimant_and_policy
-- Convenience lookup: returns a result set with claimant_id, policy_reference_id.
DROP PROCEDURE IF EXISTS sp_claim_get_claimant_and_policy$$
CREATE PROCEDURE sp_claim_get_claimant_and_policy(
    IN  p_claim_id   BIGINT
)
BEGIN
    SELECT claimant_id, policy_reference_id
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

-- 22. sp_settlement_validate_claim_approved
-- Standalone reusable check for Req 7.3.
-- Validates: Requirements 7.3
DROP PROCEDURE IF EXISTS sp_settlement_validate_claim_approved$$
CREATE PROCEDURE sp_settlement_validate_claim_approved(
    IN  p_claim_id        BIGINT,
    OUT p_is_approved     TINYINT,
    OUT p_error_message   VARCHAR(500)
)
BEGIN
    DECLARE v_status VARCHAR(20) DEFAULT NULL;

    SELECT status INTO v_status
    FROM claim
    WHERE claim_id = p_claim_id;

    IF v_status IS NULL THEN
        SET p_is_approved = 0;
        SET p_error_message = 'Claim not found';
    ELSEIF v_status <> 'Approved' THEN
        SET p_is_approved = 0;
        SET p_error_message = CONCAT('Claim status is ', v_status, '; only Claims in Approved status may be settled');
    ELSE
        SET p_is_approved = 1;
        SET p_error_message = NULL;
    END IF;
END$$

-- ============================================================================
-- ADDITIONAL TRANSACTIONAL PROCEDURES (4 procedures)
-- Real START TRANSACTION/COMMIT/ROLLBACK + exit handler + sp_execution_log
-- write. Combined with the transactional procedures in tasks 5.1/5.2/5.3,
-- brings the transactional-procedure count to >= 5 (Req 16.5).
-- ============================================================================

-- 23. sp_document_metadata_delete_safe (transactional)
-- Transactional delete with existence check first.
-- Validates: Requirements 9.4, 16.5
DROP PROCEDURE IF EXISTS sp_document_metadata_delete_safe$$
CREATE PROCEDURE sp_document_metadata_delete_safe(
    IN  p_document_metadata_id   BIGINT,
    OUT p_success_flag           TINYINT,
    OUT p_error_message          VARCHAR(500)
)
BEGIN
    DECLARE v_exists_count INT DEFAULT 0;
    DECLARE v_sqlstate_text VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_sqlstate_text = MESSAGE_TEXT;
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = CONCAT('Unexpected error deleting document_metadata: ', v_sqlstate_text);
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_document_metadata_delete_safe', 'FAILURE', p_error_message, NOW());
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_exists_count
    FROM document_metadata
    WHERE document_metadata_id = p_document_metadata_id;

    IF v_exists_count = 0 THEN
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = 'Document_Metadata record was not found';
    ELSE
        DELETE FROM document_metadata WHERE document_metadata_id = p_document_metadata_id;
        COMMIT;
        SET p_success_flag = 1;
        SET p_error_message = NULL;
    END IF;
END$$

-- 24. sp_litigation_record_create_validated (transactional, composed)
-- Calls sp_validate_litigation_fields (composition) before inserting.
-- Validates: Requirements 10.2, 10.3, 16.5, 16.6
DROP PROCEDURE IF EXISTS sp_litigation_record_create_validated$$
CREATE PROCEDURE sp_litigation_record_create_validated(
    IN  p_claim_id          BIGINT,
    IN  p_case_reference    VARCHAR(100),
    IN  p_filing_date       DATE,
    IN  p_status            VARCHAR(30),
    IN  p_attorney_name     VARCHAR(150),
    OUT p_new_id             BIGINT,
    OUT p_error_message     VARCHAR(500)
)
BEGIN
    DECLARE v_is_valid       TINYINT DEFAULT 1;
    DECLARE v_validation_msg VARCHAR(500) DEFAULT NULL;
    DECLARE v_sqlstate_text  VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_sqlstate_text = MESSAGE_TEXT;
        ROLLBACK;
        SET p_new_id = NULL;
        SET p_error_message = CONCAT('Unexpected error creating litigation_record: ', v_sqlstate_text);
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_litigation_record_create_validated', 'FAILURE', p_error_message, NOW());
    END;

    CALL sp_validate_litigation_fields(p_case_reference, p_filing_date, v_is_valid, v_validation_msg);

    IF v_is_valid = 0 THEN
        SET p_new_id = NULL;
        SET p_error_message = v_validation_msg;
    ELSE
        START TRANSACTION;

        INSERT INTO litigation_record (
            claim_id, case_reference, filing_date, status, attorney_name, created_at
        ) VALUES (
            p_claim_id, p_case_reference, p_filing_date, p_status, p_attorney_name, NOW()
        );

        SET p_new_id = LAST_INSERT_ID();
        COMMIT;
        SET p_error_message = NULL;
    END IF;
END$$

-- 25. sp_fraud_flag_delete_with_rescore (transactional, composed)
-- Looks up the flag's claim_id, deletes the fraud_flag row, then calls
-- sp_fraud_score_recompute(claim_id, @score, @review) to keep the fraud score
-- consistent with the remaining active flags (Req 16.6 composition).
--
-- DEPENDENCY NOTE: sp_fraud_score_recompute(IN p_claim_id; OUT p_new_score,
-- OUT p_under_review_flag) is defined in 22_sp_lifecycle_fraud_subrogation.sql
-- (task 5.3), authored in parallel with this file. If that procedure has not
-- yet been loaded into the schema when this file is executed, this CALL will
-- fail with a "procedure does not exist" error -- 22_sp_lifecycle_fraud_subrogation.sql
-- MUST be loaded before this file during task 5.6's execution pass. The exact
-- signature assumed here must be re-verified against that file before 5.6 runs.
-- Validates: Requirements 8.3, 16.5, 16.6
DROP PROCEDURE IF EXISTS sp_fraud_flag_delete_with_rescore$$
CREATE PROCEDURE sp_fraud_flag_delete_with_rescore(
    IN  p_fraud_flag_id    BIGINT,
    OUT p_success_flag     TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    DECLARE v_claim_id        BIGINT DEFAULT NULL;
    DECLARE v_new_score       INT DEFAULT NULL;
    DECLARE v_under_review    TINYINT DEFAULT NULL;
    DECLARE v_sqlstate_text   VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_sqlstate_text = MESSAGE_TEXT;
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = CONCAT('Unexpected error deleting fraud_flag: ', v_sqlstate_text);
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_fraud_flag_delete_with_rescore', 'FAILURE', p_error_message, NOW());
    END;

    START TRANSACTION;

    SELECT claim_id INTO v_claim_id
    FROM fraud_flag
    WHERE fraud_flag_id = p_fraud_flag_id;

    IF v_claim_id IS NULL THEN
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = 'Fraud_Flag record was not found';
    ELSE
        DELETE FROM fraud_flag WHERE fraud_flag_id = p_fraud_flag_id;

        CALL sp_fraud_score_recompute(v_claim_id, v_new_score, v_under_review);

        COMMIT;
        SET p_success_flag = 1;
        SET p_error_message = NULL;
    END IF;
END$$

-- 26. sp_claim_delete_cascade_admin (transactional, admin-only, internal/test-utility)
--
-- IMPORTANT: This procedure is NOT exposed via any REST/JSP endpoint
-- (Requirement 14 reserves Claim deletion as an internal/test-utility
-- operation only; no application code path invokes this procedure). It
-- exists solely to allow test teardown / administrative cleanup of a Claim
-- and all of its dependent rows in one transaction. It removes dependent
-- rows in FK-safe order (damage_assessment, reserve_history then reserve,
-- fraud_flag, document_metadata, litigation_record, subrogation_record,
-- claim_adjuster_assignment_history) before deleting the claim itself and
-- claim_status_history last, with rollback on any error.
-- Validates: Requirements 14.3 (does not provide an application-exposed
-- deletion path for claim_status_history/reserve_history; this procedure is
-- the sole, non-application-exposed exception for full-claim teardown)
DROP PROCEDURE IF EXISTS sp_claim_delete_cascade_admin$$
CREATE PROCEDURE sp_claim_delete_cascade_admin(
    IN  p_claim_id         BIGINT,
    OUT p_success_flag     TINYINT,
    OUT p_error_message    VARCHAR(500)
)
BEGIN
    DECLARE v_exists_count   INT DEFAULT 0;
    DECLARE v_sqlstate_text  VARCHAR(128);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_sqlstate_text = MESSAGE_TEXT;
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = CONCAT('Unexpected error during cascade delete of claim: ', v_sqlstate_text);
        INSERT INTO sp_execution_log (procedure_name, status, error_message, executed_at)
        VALUES ('sp_claim_delete_cascade_admin', 'FAILURE', p_error_message, NOW());
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_exists_count
    FROM claim
    WHERE claim_id = p_claim_id;

    IF v_exists_count = 0 THEN
        ROLLBACK;
        SET p_success_flag = 0;
        SET p_error_message = 'Claim not found';
    ELSE
        DELETE FROM damage_assessment WHERE claim_id = p_claim_id;

        DELETE rh FROM reserve_history rh
            INNER JOIN reserve r ON r.reserve_id = rh.reserve_id
            WHERE r.claim_id = p_claim_id;
        DELETE FROM reserve WHERE claim_id = p_claim_id;

        DELETE FROM fraud_flag WHERE claim_id = p_claim_id;
        DELETE FROM fraud_score WHERE claim_id = p_claim_id;
        DELETE FROM document_metadata WHERE claim_id = p_claim_id;
        DELETE FROM litigation_record WHERE claim_id = p_claim_id;
        DELETE FROM subrogation_record WHERE claim_id = p_claim_id;
        DELETE FROM settlement WHERE claim_id = p_claim_id;
        DELETE FROM claim_adjuster_assignment_history WHERE claim_id = p_claim_id;

        DELETE FROM claim WHERE claim_id = p_claim_id;
        DELETE FROM claim_status_history WHERE claim_id = p_claim_id;

        COMMIT;
        SET p_success_flag = 1;
        SET p_error_message = NULL;
    END IF;
END$$

DELIMITER ;
