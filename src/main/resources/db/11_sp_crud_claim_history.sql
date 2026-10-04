-- =============================================================================
-- ICPS Database - 11_sp_crud_claim_history.sql
-- CRUD stored procedures for: claim (11), claim_status_history (10)
--
-- Dialect: MySQL 8.x
--
-- IMPORTANT (Req 14.3): claim_status_history is an append-only audit trail.
-- This file intentionally contains NO update or delete procedure for
-- claim_status_history. Only sp_csh_create (INSERT) and read/finder
-- procedures are provided below.
--
-- NOTE: sp_claim_create below is a simple raw CRUD insert (no validation,
-- no history row, no reserve row) used internally/for seeding. The full
-- FNOL business-logic creation procedure with validation + history +
-- reserve insert in a single transaction is sp_claim_create_with_fnol,
-- implemented separately under task 5 (lifecycle procedures).
--
-- sp_claim_update below only allows updating core non-status fields
-- (policy_reference_id, adjuster_id, loss_date, loss_description).
-- Direct status updates are intentionally NOT supported here; status
-- changes must go through sp_claim_transition_status (task 5) so that
-- the transition-rule validation, optimistic-concurrency check, and
-- claim_status_history insert all happen atomically.
--
-- LOAD ORDER NOTE: Requires 01_ddl_core.sql (claim, claim_status_history)
-- to have been executed first.
-- =============================================================================
SET NAMES utf8mb4;

-- =============================================================================
-- SECTION 1: claim (11 procedures)
-- =============================================================================

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_claim_create
-- Raw CRUD insert for claim. No FNOL validation, no history/reserve rows.
-- Used internally for seeding / low-level inserts only.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_create$$
CREATE PROCEDURE sp_claim_create(
    IN  p_claimant_id          BIGINT,
    IN  p_policy_reference_id  BIGINT,
    IN  p_adjuster_id          BIGINT,
    IN  p_loss_date            DATE,
    IN  p_loss_description     VARCHAR(2000),
    IN  p_status               VARCHAR(20),
    OUT p_claim_id             BIGINT
)
BEGIN
    INSERT INTO claim (
        claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    ) VALUES (
        p_claimant_id, p_policy_reference_id, p_adjuster_id, p_loss_date,
        p_loss_description, p_status, 0, NULL,
        0, NOW(), NOW()
    );

    SET p_claim_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_read
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_read$$
CREATE PROCEDURE sp_claim_read(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT
        claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_update
-- Updates only core, non-status fields. Status is intentionally excluded;
-- status changes must go through sp_claim_transition_status (task 5).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_update$$
CREATE PROCEDURE sp_claim_update(
    IN p_claim_id             BIGINT,
    IN p_policy_reference_id  BIGINT,
    IN p_adjuster_id          BIGINT,
    IN p_loss_date            DATE,
    IN p_loss_description     VARCHAR(2000)
)
BEGIN
    UPDATE claim
    SET policy_reference_id = p_policy_reference_id,
        adjuster_id          = p_adjuster_id,
        loss_date            = p_loss_date,
        loss_description     = p_loss_description,
        updated_at           = NOW()
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_delete
-- Raw, admin-only hard delete. Not exposed through normal application flow;
-- see sp_claim_delete_cascade_admin (task 5) for the guarded admin path.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_delete$$
CREATE PROCEDURE sp_claim_delete(
    IN p_claim_id BIGINT
)
BEGIN
    DELETE FROM claim WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_list
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_list$$
CREATE PROCEDURE sp_claim_list()
BEGIN
    SELECT
        claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    FROM claim
    ORDER BY claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_find_by_claimant
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_find_by_claimant$$
CREATE PROCEDURE sp_claim_find_by_claimant(
    IN p_claimant_id BIGINT
)
BEGIN
    SELECT
        claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    FROM claim
    WHERE claimant_id = p_claimant_id
    ORDER BY claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_find_by_adjuster
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_find_by_adjuster$$
CREATE PROCEDURE sp_claim_find_by_adjuster(
    IN p_adjuster_id BIGINT
)
BEGIN
    SELECT
        claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    FROM claim
    WHERE adjuster_id = p_adjuster_id
    ORDER BY claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_find_by_status
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_find_by_status$$
CREATE PROCEDURE sp_claim_find_by_status(
    IN p_status VARCHAR(20)
)
BEGIN
    SELECT
        claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
        loss_description, status, under_fraud_review, net_paid_amount,
        version, created_at, updated_at
    FROM claim
    WHERE status = p_status
    ORDER BY claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_exists
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_exists$$
CREATE PROCEDURE sp_claim_exists(
    IN  p_claim_id BIGINT,
    OUT p_exists   TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_exists
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_get_current_status
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_get_current_status$$
CREATE PROCEDURE sp_claim_get_current_status(
    IN  p_claim_id BIGINT,
    OUT p_status   VARCHAR(20)
)
BEGIN
    SELECT status INTO p_status
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_claim_get_version
-- Backs the optimistic concurrency check in Req 6.7.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_claim_get_version$$
CREATE PROCEDURE sp_claim_get_version(
    IN  p_claim_id BIGINT,
    OUT p_version  INT
)
BEGIN
    SELECT version INTO p_version
    FROM claim
    WHERE claim_id = p_claim_id;
END$$

DELIMITER ;

-- =============================================================================
-- SECTION 2: claim_status_history (10 procedures, INSERT-ONLY)
--
-- Per Req 14.3, this table is append-only. NO update or delete procedure
-- is defined for claim_status_history anywhere in this file.
-- =============================================================================

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_csh_create
-- The only write path for this table.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_create$$
CREATE PROCEDURE sp_csh_create(
    IN  p_claim_id      BIGINT,
    IN  p_prior_status  VARCHAR(20),
    IN  p_new_status    VARCHAR(20),
    IN  p_changed_by    VARCHAR(50),
    IN  p_note          VARCHAR(500),
    OUT p_history_id    BIGINT
)
BEGIN
    INSERT INTO claim_status_history (
        claim_id, prior_status, new_status, changed_by, changed_at, note
    ) VALUES (
        p_claim_id, p_prior_status, p_new_status, p_changed_by, NOW(), p_note
    );

    SET p_history_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_read
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_read$$
CREATE PROCEDURE sp_csh_read(
    IN p_history_id BIGINT
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE history_id = p_history_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_list_by_claim
-- Most-recent-first, per Req 5.6/6.6 display ordering convention.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_list_by_claim$$
CREATE PROCEDURE sp_csh_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE claim_id = p_claim_id
    ORDER BY changed_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_find_latest
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_find_latest$$
CREATE PROCEDURE sp_csh_find_latest(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE claim_id = p_claim_id
    ORDER BY changed_at DESC
    LIMIT 1;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_count_by_claim
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_count_by_claim$$
CREATE PROCEDURE sp_csh_count_by_claim(
    IN  p_claim_id BIGINT,
    OUT p_total    INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM claim_status_history
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_find_by_date_range
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_find_by_date_range$$
CREATE PROCEDURE sp_csh_find_by_date_range(
    IN p_claim_id   BIGINT,
    IN p_start_date DATETIME,
    IN p_end_date   DATETIME
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE claim_id = p_claim_id
      AND changed_at BETWEEN p_start_date AND p_end_date
    ORDER BY changed_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_find_by_user
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_find_by_user$$
CREATE PROCEDURE sp_csh_find_by_user(
    IN p_changed_by VARCHAR(50)
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE changed_by = p_changed_by
    ORDER BY changed_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_exists_for_claim
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_exists_for_claim$$
CREATE PROCEDURE sp_csh_exists_for_claim(
    IN  p_claim_id BIGINT,
    OUT p_exists   TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_exists
    FROM claim_status_history
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_find_by_status_pair
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_find_by_status_pair$$
CREATE PROCEDURE sp_csh_find_by_status_pair(
    IN p_prior_status VARCHAR(20),
    IN p_new_status   VARCHAR(20)
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    WHERE (p_prior_status IS NULL AND prior_status IS NULL
           OR prior_status = p_prior_status)
      AND new_status = p_new_status
    ORDER BY changed_at DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_csh_list_all
-- Paginated listing via LIMIT/OFFSET params.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_csh_list_all$$
CREATE PROCEDURE sp_csh_list_all(
    IN p_limit  INT,
    IN p_offset INT
)
BEGIN
    SELECT
        history_id, claim_id, prior_status, new_status, changed_by,
        changed_at, note
    FROM claim_status_history
    ORDER BY changed_at DESC
    LIMIT p_limit OFFSET p_offset;
END$$

DELIMITER ;
