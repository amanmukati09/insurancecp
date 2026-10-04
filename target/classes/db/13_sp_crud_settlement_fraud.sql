-- =============================================================================
-- 13_sp_crud_settlement_fraud.sql
-- Insurance Claims Processing System (ICPS)
--
-- CRUD + finder stored procedures for: settlement, fraud_flag
-- (20 procedures total, 10 per entity).
--
-- LOAD ORDER: Run after 01_ddl_core.sql through 04_ddl_lookup_audit.sql have
-- created all 23 tables (settlement is defined in 02_ddl_financial.sql;
-- fraud_flag is defined in 03_ddl_fraud_doc_litigation_subrogation.sql).
--
-- Requirement 7.4: sp_settlement_exists_for_claim backs the "no duplicate
-- Settlement for a Claim" business rule enforced in Settlement_Service /
-- sp_settlement_approve (task 5.2), in addition to the uq_settlement_claim
-- UNIQUE constraint already enforcing this at the DB level.
--
-- Requirements: 16.3 (>=10 CRUD procedures per entity), 7.1 (Settlement
-- CRUD + approval screen support), 8.1 (Fraud_Flag CRUD with active/inactive
-- status).
-- =============================================================================

-- #############################################################################
-- ## SETTLEMENT (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_settlement_create: insert a new Settlement row for a Claim.
-- Requirement 7.1 / 7.6: records payout amount, approving user, and approval
-- timestamp. Callers (e.g. sp_settlement_approve, task 5.2) are responsible
-- for enforcing the "Approved status only" and "no duplicate Settlement"
-- rules before calling this procedure.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_create(
    IN p_claim_id BIGINT,
    IN p_payout_amount DECIMAL(12,2),
    IN p_approved_by VARCHAR(50),
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO settlement (
        claim_id, payout_amount, approved_by, approved_at
    ) VALUES (
        p_claim_id, p_payout_amount, p_approved_by, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_read: fetch a single Settlement by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_read(
    IN p_settlement_id BIGINT
)
BEGIN
    SELECT settlement_id, claim_id, payout_amount, approved_by, approved_at
    FROM settlement
    WHERE settlement_id = p_settlement_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_update: update the payout amount of an existing Settlement.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_update(
    IN p_settlement_id BIGINT,
    IN p_payout_amount DECIMAL(12,2)
)
BEGIN
    UPDATE settlement
    SET payout_amount = p_payout_amount
    WHERE settlement_id = p_settlement_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_delete: delete a Settlement by id (admin-only operation; not
-- exposed through the ICPS_Web_Application's normal CRUD endpoints).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_delete(
    IN p_settlement_id BIGINT
)
BEGIN
    DELETE FROM settlement WHERE settlement_id = p_settlement_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_list: list all Settlement rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_list()
BEGIN
    SELECT settlement_id, claim_id, payout_amount, approved_by, approved_at
    FROM settlement
    ORDER BY approved_at DESC, settlement_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_find_by_claim: fetch the Settlement row for a given Claim
-- (at most one row per Claim per uq_settlement_claim).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_find_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT settlement_id, claim_id, payout_amount, approved_by, approved_at
    FROM settlement
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_exists_for_claim: check whether a Settlement already exists
-- for a Claim.
-- Requirement 7.4: backs the "Settlement already exists for the Claim"
-- duplicate-submission rejection rule enforced by Settlement_Service /
-- sp_settlement_approve.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_exists_for_claim(
    IN p_claim_id BIGINT,
    OUT p_exists_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_exists_flag
    FROM settlement
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_get_payout: fetch just the payout_amount for a Claim's
-- Settlement, if one exists.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_get_payout(
    IN p_claim_id BIGINT,
    OUT p_payout_amount DECIMAL(12,2)
)
BEGIN
    SELECT payout_amount
    INTO p_payout_amount
    FROM settlement
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_find_by_approver: list Settlement rows approved by a given
-- user.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_find_by_approver(
    IN p_approved_by VARCHAR(50)
)
BEGIN
    SELECT settlement_id, claim_id, payout_amount, approved_by, approved_at
    FROM settlement
    WHERE approved_by = p_approved_by
    ORDER BY approved_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_settlement_find_by_date_range: list Settlement rows approved within an
-- inclusive date range.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_settlement_find_by_date_range(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT settlement_id, claim_id, payout_amount, approved_by, approved_at
    FROM settlement
    WHERE DATE(approved_at) BETWEEN p_start_date AND p_end_date
    ORDER BY approved_at DESC;
END$$

DELIMITER ;

-- #############################################################################
-- ## FRAUD_FLAG (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_ff_create: insert a new Fraud_Flag row for a Claim. New flags default
-- to active (is_active = 1).
-- Requirement 8.1 / 8.2: callers are responsible for validating required
-- fields and Claim existence before invoking this procedure.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_create(
    IN p_claim_id BIGINT,
    IN p_flag_reason VARCHAR(200),
    IN p_score_weight INT,
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO fraud_flag (
        claim_id, flag_reason, score_weight, is_active, created_at, updated_at
    ) VALUES (
        p_claim_id, p_flag_reason, p_score_weight, 1, NOW(), NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_read: fetch a single Fraud_Flag by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_read(
    IN p_fraud_flag_id BIGINT
)
BEGIN
    SELECT fraud_flag_id, claim_id, flag_reason, score_weight, is_active,
           created_at, updated_at
    FROM fraud_flag
    WHERE fraud_flag_id = p_fraud_flag_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_update: update the mutable fields of a Fraud_Flag.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_update(
    IN p_fraud_flag_id BIGINT,
    IN p_flag_reason VARCHAR(200),
    IN p_score_weight INT,
    IN p_is_active TINYINT(1)
)
BEGIN
    UPDATE fraud_flag
    SET flag_reason = p_flag_reason,
        score_weight = p_score_weight,
        is_active = p_is_active,
        updated_at = NOW()
    WHERE fraud_flag_id = p_fraud_flag_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_delete: delete a Fraud_Flag by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_delete(
    IN p_fraud_flag_id BIGINT
)
BEGIN
    DELETE FROM fraud_flag WHERE fraud_flag_id = p_fraud_flag_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_list_by_claim: list all Fraud_Flag rows (active and inactive) for a
-- Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT fraud_flag_id, claim_id, flag_reason, score_weight, is_active,
           created_at, updated_at
    FROM fraud_flag
    WHERE claim_id = p_claim_id
    ORDER BY created_at DESC, fraud_flag_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_list_active_by_claim: list only active Fraud_Flag rows for a Claim.
-- Requirement 8.3: feeds Fraud_Scoring_Service's score recomputation, which
-- sums only active Fraud_Flag conditions.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_list_active_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT fraud_flag_id, claim_id, flag_reason, score_weight, is_active,
           created_at, updated_at
    FROM fraud_flag
    WHERE claim_id = p_claim_id
      AND is_active = 1
    ORDER BY created_at DESC, fraud_flag_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_count_active_by_claim: count active Fraud_Flag rows for a Claim.
-- Requirement 8.6: feeds the fraud flag summary report's "count of active
-- Fraud_Flag records" column.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_count_active_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_total
    FROM fraud_flag
    WHERE claim_id = p_claim_id
      AND is_active = 1;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_deactivate: mark a Fraud_Flag inactive without deleting it.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_deactivate(
    IN p_fraud_flag_id BIGINT
)
BEGIN
    UPDATE fraud_flag
    SET is_active = 0,
        updated_at = NOW()
    WHERE fraud_flag_id = p_fraud_flag_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_find_by_reason: list Fraud_Flag rows matching an exact flag_reason.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_find_by_reason(
    IN p_flag_reason VARCHAR(200)
)
BEGIN
    SELECT fraud_flag_id, claim_id, flag_reason, score_weight, is_active,
           created_at, updated_at
    FROM fraud_flag
    WHERE flag_reason = p_flag_reason
    ORDER BY created_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_ff_exists: check whether a Fraud_Flag with the given id exists.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_ff_exists(
    IN p_fraud_flag_id BIGINT,
    OUT p_exists_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_exists_flag
    FROM fraud_flag
    WHERE fraud_flag_id = p_fraud_flag_id;
END$$

DELIMITER ;
