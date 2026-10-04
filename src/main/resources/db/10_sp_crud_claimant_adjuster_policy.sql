-- =============================================================================
-- ICPS Database - 10_sp_crud_claimant_adjuster_policy.sql
-- CRUD stored procedures for: claimant, adjuster, policy_reference (30 total,
-- 10 per entity). Task 4.1.
--
-- Dialect: MySQL 8.x
--
-- NOTE: These are simple CRUD/lookup procedures. Full transactional error
-- handling (DECLARE ... HANDLER FOR SQLEXCEPTION, rollback, sp_execution_log)
-- is reserved for the lifecycle procedures in task 5. Basic NULL/not-found
-- handling is included where sensible.
--
-- Column names/tables match 01_ddl_core.sql exactly:
--   claimant(claimant_id, first_name, last_name, address_line1, address_city,
--            address_state, address_zip, phone, email, created_at)
--   adjuster(adjuster_id, username, first_name, last_name, is_active, created_at)
--   policy_reference(policy_reference_id, policy_number, policy_type,
--            coverage_limit, deductible, effective_start_date, effective_end_date)
--   claim(claim_id, claimant_id, policy_reference_id, adjuster_id, ...)
--
-- This file is loaded (not executed) as part of task 4.1. Task 4.6 executes
-- all CRUD procedure files together against the real `icps` schema.
-- =============================================================================

-- =============================================================================
-- CLAIMANT (10 procedures)
-- =============================================================================

DELIMITER $$

-- 1. sp_claimant_create
DROP PROCEDURE IF EXISTS sp_claimant_create$$
CREATE PROCEDURE sp_claimant_create(
    IN  p_first_name     VARCHAR(100),
    IN  p_last_name       VARCHAR(100),
    IN  p_address_line1   VARCHAR(200),
    IN  p_address_city     VARCHAR(100),
    IN  p_address_state    VARCHAR(2),
    IN  p_address_zip       VARCHAR(10),
    IN  p_phone              VARCHAR(20),
    IN  p_email               VARCHAR(150),
    OUT p_new_id              BIGINT
)
BEGIN
    INSERT INTO claimant (
        first_name, last_name, address_line1, address_city,
        address_state, address_zip, phone, email, created_at
    ) VALUES (
        p_first_name, p_last_name, p_address_line1, p_address_city,
        p_address_state, p_address_zip, p_phone, p_email, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- 2. sp_claimant_read
DROP PROCEDURE IF EXISTS sp_claimant_read$$
CREATE PROCEDURE sp_claimant_read(
    IN p_claimant_id BIGINT
)
BEGIN
    SELECT claimant_id, first_name, last_name, address_line1, address_city,
           address_state, address_zip, phone, email, created_at
    FROM claimant
    WHERE claimant_id = p_claimant_id;
END$$

-- 3. sp_claimant_update
DROP PROCEDURE IF EXISTS sp_claimant_update$$
CREATE PROCEDURE sp_claimant_update(
    IN p_claimant_id      BIGINT,
    IN p_first_name       VARCHAR(100),
    IN p_last_name        VARCHAR(100),
    IN p_address_line1    VARCHAR(200),
    IN p_address_city     VARCHAR(100),
    IN p_address_state    VARCHAR(2),
    IN p_address_zip      VARCHAR(10),
    IN p_phone            VARCHAR(20),
    IN p_email            VARCHAR(150)
)
BEGIN
    UPDATE claimant
    SET first_name    = p_first_name,
        last_name     = p_last_name,
        address_line1 = p_address_line1,
        address_city  = p_address_city,
        address_state = p_address_state,
        address_zip   = p_address_zip,
        phone         = p_phone,
        email         = p_email
    WHERE claimant_id = p_claimant_id;
END$$

-- 4. sp_claimant_delete
DROP PROCEDURE IF EXISTS sp_claimant_delete$$
CREATE PROCEDURE sp_claimant_delete(
    IN p_claimant_id BIGINT
)
BEGIN
    DELETE FROM claimant WHERE claimant_id = p_claimant_id;
END$$

-- 5. sp_claimant_list
DROP PROCEDURE IF EXISTS sp_claimant_list$$
CREATE PROCEDURE sp_claimant_list()
BEGIN
    SELECT claimant_id, first_name, last_name, address_line1, address_city,
           address_state, address_zip, phone, email, created_at
    FROM claimant
    ORDER BY claimant_id;
END$$

-- 6. sp_claimant_exists
DROP PROCEDURE IF EXISTS sp_claimant_exists$$
CREATE PROCEDURE sp_claimant_exists(
    IN  p_claimant_id BIGINT,
    OUT p_exists_flag TINYINT
)
BEGIN
    SELECT COUNT(*) INTO p_exists_flag
    FROM claimant
    WHERE claimant_id = p_claimant_id;

    IF p_exists_flag > 1 THEN
        SET p_exists_flag = 1;
    END IF;
END$$

-- 7. sp_claimant_search_by_state
DROP PROCEDURE IF EXISTS sp_claimant_search_by_state$$
CREATE PROCEDURE sp_claimant_search_by_state(
    IN p_address_state VARCHAR(2)
)
BEGIN
    SELECT claimant_id, first_name, last_name, address_line1, address_city,
           address_state, address_zip, phone, email, created_at
    FROM claimant
    WHERE address_state = p_address_state
    ORDER BY claimant_id;
END$$

-- 8. sp_claimant_count
DROP PROCEDURE IF EXISTS sp_claimant_count$$
CREATE PROCEDURE sp_claimant_count(
    OUT p_total BIGINT
)
BEGIN
    SELECT COUNT(*) INTO p_total FROM claimant;
END$$

-- 9. sp_claimant_find_by_email
DROP PROCEDURE IF EXISTS sp_claimant_find_by_email$$
CREATE PROCEDURE sp_claimant_find_by_email(
    IN p_email VARCHAR(150)
)
BEGIN
    SELECT claimant_id, first_name, last_name, address_line1, address_city,
           address_state, address_zip, phone, email, created_at
    FROM claimant
    WHERE email = p_email;
END$$

-- 10. sp_claimant_has_claims (backs Req 2.5's delete-guard)
DROP PROCEDURE IF EXISTS sp_claimant_has_claims$$
CREATE PROCEDURE sp_claimant_has_claims(
    IN  p_claimant_id   BIGINT,
    OUT p_has_claims_flag TINYINT
)
BEGIN
    DECLARE v_count BIGINT;

    SELECT COUNT(*) INTO v_count
    FROM claim
    WHERE claimant_id = p_claimant_id;

    IF v_count > 0 THEN
        SET p_has_claims_flag = 1;
    ELSE
        SET p_has_claims_flag = 0;
    END IF;
END$$

DELIMITER ;

-- =============================================================================
-- ADJUSTER (10 procedures)
-- =============================================================================

DELIMITER $$

-- 1. sp_adjuster_create
DROP PROCEDURE IF EXISTS sp_adjuster_create$$
CREATE PROCEDURE sp_adjuster_create(
    IN  p_username     VARCHAR(50),
    IN  p_first_name   VARCHAR(100),
    IN  p_last_name    VARCHAR(100),
    IN  p_is_active    TINYINT(1),
    OUT p_new_id        BIGINT
)
BEGIN
    INSERT INTO adjuster (
        username, first_name, last_name, is_active, created_at
    ) VALUES (
        p_username, p_first_name, p_last_name, IFNULL(p_is_active, 1), NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- 2. sp_adjuster_read
DROP PROCEDURE IF EXISTS sp_adjuster_read$$
CREATE PROCEDURE sp_adjuster_read(
    IN p_adjuster_id BIGINT
)
BEGIN
    SELECT adjuster_id, username, first_name, last_name, is_active, created_at
    FROM adjuster
    WHERE adjuster_id = p_adjuster_id;
END$$

-- 3. sp_adjuster_update
DROP PROCEDURE IF EXISTS sp_adjuster_update$$
CREATE PROCEDURE sp_adjuster_update(
    IN p_adjuster_id BIGINT,
    IN p_username     VARCHAR(50),
    IN p_first_name   VARCHAR(100),
    IN p_last_name    VARCHAR(100),
    IN p_is_active    TINYINT(1)
)
BEGIN
    UPDATE adjuster
    SET username   = p_username,
        first_name = p_first_name,
        last_name  = p_last_name,
        is_active  = p_is_active
    WHERE adjuster_id = p_adjuster_id;
END$$

-- 4. sp_adjuster_delete
DROP PROCEDURE IF EXISTS sp_adjuster_delete$$
CREATE PROCEDURE sp_adjuster_delete(
    IN p_adjuster_id BIGINT
)
BEGIN
    DELETE FROM adjuster WHERE adjuster_id = p_adjuster_id;
END$$

-- 5. sp_adjuster_list
DROP PROCEDURE IF EXISTS sp_adjuster_list$$
CREATE PROCEDURE sp_adjuster_list()
BEGIN
    SELECT adjuster_id, username, first_name, last_name, is_active, created_at
    FROM adjuster
    ORDER BY adjuster_id;
END$$

-- 6. sp_adjuster_set_active
DROP PROCEDURE IF EXISTS sp_adjuster_set_active$$
CREATE PROCEDURE sp_adjuster_set_active(
    IN p_adjuster_id BIGINT,
    IN p_is_active   TINYINT(1)
)
BEGIN
    UPDATE adjuster
    SET is_active = p_is_active
    WHERE adjuster_id = p_adjuster_id;
END$$

-- 7. sp_adjuster_find_by_username
DROP PROCEDURE IF EXISTS sp_adjuster_find_by_username$$
CREATE PROCEDURE sp_adjuster_find_by_username(
    IN p_username VARCHAR(50)
)
BEGIN
    SELECT adjuster_id, username, first_name, last_name, is_active, created_at
    FROM adjuster
    WHERE username = p_username;
END$$

-- 8. sp_adjuster_count_active
DROP PROCEDURE IF EXISTS sp_adjuster_count_active$$
CREATE PROCEDURE sp_adjuster_count_active(
    OUT p_total BIGINT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM adjuster
    WHERE is_active = 1;
END$$

-- 9. sp_adjuster_exists
DROP PROCEDURE IF EXISTS sp_adjuster_exists$$
CREATE PROCEDURE sp_adjuster_exists(
    IN  p_adjuster_id BIGINT,
    OUT p_exists_flag TINYINT
)
BEGIN
    SELECT COUNT(*) INTO p_exists_flag
    FROM adjuster
    WHERE adjuster_id = p_adjuster_id;

    IF p_exists_flag > 1 THEN
        SET p_exists_flag = 1;
    END IF;
END$$

-- 10. sp_adjuster_is_active (backs Req 3.4's inactive-adjuster check)
DROP PROCEDURE IF EXISTS sp_adjuster_is_active$$
CREATE PROCEDURE sp_adjuster_is_active(
    IN  p_adjuster_id BIGINT,
    OUT p_is_active_flag TINYINT
)
BEGIN
    DECLARE v_is_active TINYINT;

    SELECT is_active INTO v_is_active
    FROM adjuster
    WHERE adjuster_id = p_adjuster_id;

    IF v_is_active IS NULL THEN
        SET p_is_active_flag = 0;
    ELSE
        SET p_is_active_flag = v_is_active;
    END IF;
END$$

DELIMITER ;

-- =============================================================================
-- POLICY_REFERENCE (10 procedures)
-- =============================================================================

DELIMITER $$

-- 1. sp_policy_reference_create
DROP PROCEDURE IF EXISTS sp_policy_reference_create$$
CREATE PROCEDURE sp_policy_reference_create(
    IN  p_policy_number          VARCHAR(50),
    IN  p_policy_type             VARCHAR(30),
    IN  p_coverage_limit          DECIMAL(12,2),
    IN  p_deductible              DECIMAL(12,2),
    IN  p_effective_start_date    DATE,
    IN  p_effective_end_date      DATE,
    OUT p_new_id                   BIGINT
)
BEGIN
    INSERT INTO policy_reference (
        policy_number, policy_type, coverage_limit, deductible,
        effective_start_date, effective_end_date
    ) VALUES (
        p_policy_number, p_policy_type, p_coverage_limit, p_deductible,
        p_effective_start_date, p_effective_end_date
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- 2. sp_policy_reference_read
DROP PROCEDURE IF EXISTS sp_policy_reference_read$$
CREATE PROCEDURE sp_policy_reference_read(
    IN p_policy_reference_id BIGINT
)
BEGIN
    SELECT policy_reference_id, policy_number, policy_type, coverage_limit,
           deductible, effective_start_date, effective_end_date
    FROM policy_reference
    WHERE policy_reference_id = p_policy_reference_id;
END$$

-- 3. sp_policy_reference_update
DROP PROCEDURE IF EXISTS sp_policy_reference_update$$
CREATE PROCEDURE sp_policy_reference_update(
    IN p_policy_reference_id    BIGINT,
    IN p_policy_number           VARCHAR(50),
    IN p_policy_type             VARCHAR(30),
    IN p_coverage_limit          DECIMAL(12,2),
    IN p_deductible              DECIMAL(12,2),
    IN p_effective_start_date    DATE,
    IN p_effective_end_date      DATE
)
BEGIN
    UPDATE policy_reference
    SET policy_number        = p_policy_number,
        policy_type          = p_policy_type,
        coverage_limit       = p_coverage_limit,
        deductible           = p_deductible,
        effective_start_date = p_effective_start_date,
        effective_end_date   = p_effective_end_date
    WHERE policy_reference_id = p_policy_reference_id;
END$$

-- 4. sp_policy_reference_delete
DROP PROCEDURE IF EXISTS sp_policy_reference_delete$$
CREATE PROCEDURE sp_policy_reference_delete(
    IN p_policy_reference_id BIGINT
)
BEGIN
    DELETE FROM policy_reference WHERE policy_reference_id = p_policy_reference_id;
END$$

-- 5. sp_policy_reference_list
DROP PROCEDURE IF EXISTS sp_policy_reference_list$$
CREATE PROCEDURE sp_policy_reference_list()
BEGIN
    SELECT policy_reference_id, policy_number, policy_type, coverage_limit,
           deductible, effective_start_date, effective_end_date
    FROM policy_reference
    ORDER BY policy_reference_id;
END$$

-- 6. sp_policy_reference_find_by_number
DROP PROCEDURE IF EXISTS sp_policy_reference_find_by_number$$
CREATE PROCEDURE sp_policy_reference_find_by_number(
    IN p_policy_number VARCHAR(50)
)
BEGIN
    SELECT policy_reference_id, policy_number, policy_type, coverage_limit,
           deductible, effective_start_date, effective_end_date
    FROM policy_reference
    WHERE policy_number = p_policy_number;
END$$

-- 7. sp_policy_reference_exists
DROP PROCEDURE IF EXISTS sp_policy_reference_exists$$
CREATE PROCEDURE sp_policy_reference_exists(
    IN  p_policy_reference_id BIGINT,
    OUT p_exists_flag          TINYINT
)
BEGIN
    SELECT COUNT(*) INTO p_exists_flag
    FROM policy_reference
    WHERE policy_reference_id = p_policy_reference_id;

    IF p_exists_flag > 1 THEN
        SET p_exists_flag = 1;
    END IF;
END$$

-- 8. sp_policy_reference_validate_date_range (backs Req 12.4/12.5)
DROP PROCEDURE IF EXISTS sp_policy_reference_validate_date_range$$
CREATE PROCEDURE sp_policy_reference_validate_date_range(
    IN  p_policy_reference_id BIGINT,
    IN  p_loss_date             DATE,
    OUT p_is_valid_flag          TINYINT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date   DATE;

    SELECT effective_start_date, effective_end_date
    INTO v_start_date, v_end_date
    FROM policy_reference
    WHERE policy_reference_id = p_policy_reference_id;

    IF v_start_date IS NULL OR v_end_date IS NULL THEN
        SET p_is_valid_flag = 0;
    ELSEIF p_loss_date BETWEEN v_start_date AND v_end_date THEN
        SET p_is_valid_flag = 1;
    ELSE
        SET p_is_valid_flag = 0;
    END IF;
END$$

-- 9. sp_policy_reference_get_coverage_terms
DROP PROCEDURE IF EXISTS sp_policy_reference_get_coverage_terms$$
CREATE PROCEDURE sp_policy_reference_get_coverage_terms(
    IN p_policy_reference_id BIGINT
)
BEGIN
    SELECT policy_reference_id, policy_number, coverage_limit, deductible
    FROM policy_reference
    WHERE policy_reference_id = p_policy_reference_id;
END$$

-- 10. sp_policy_reference_count
DROP PROCEDURE IF EXISTS sp_policy_reference_count$$
CREATE PROCEDURE sp_policy_reference_count(
    OUT p_total BIGINT
)
BEGIN
    SELECT COUNT(*) INTO p_total FROM policy_reference;
END$$

DELIMITER ;
