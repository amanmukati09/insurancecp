-- =============================================================================
-- 12_sp_crud_damage_reserve.sql
-- Insurance Claims Processing System (ICPS)
--
-- CRUD + finder stored procedures for: damage_assessment, reserve,
-- reserve_history (30 procedures total, 10 per entity).
--
-- LOAD ORDER: Run after 01_ddl_core.sql through 04_ddl_lookup_audit.sql have
-- created all 23 tables (damage_assessment / reserve / reserve_history are
-- defined in 02_ddl_financial.sql).
--
-- Requirement 14.2 / 14.3: reserve_history is INSERT-ONLY. No UPDATE or
-- DELETE procedure is defined for reserve_history in this file, and none
-- should ever be added.
--
-- Requirements: 16.3 (>=10 CRUD procedures per entity), 14.3 (no update/delete
-- for insert-only audit tables), 4.1 (damage assessment validation/recording),
-- 5.1 (reserve amount validation).
-- =============================================================================

-- #############################################################################
-- ## DAMAGE_ASSESSMENT (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_da_create: insert a new Damage_Assessment row for a Claim.
-- Requirement 4.1: estimated_cost > 0 and <= 999,999,999.99 is enforced by the
-- chk_da_estimated_cost CHECK constraint on the table; this procedure performs
-- the insert and returns the new identifier.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_create(
    IN p_claim_id BIGINT,
    IN p_estimated_cost DECIMAL(12,2),
    IN p_description VARCHAR(1000),
    IN p_assessment_date DATE,
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO damage_assessment (
        claim_id, estimated_cost, description, assessment_date, created_at
    ) VALUES (
        p_claim_id, p_estimated_cost, p_description, p_assessment_date, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_da_read: fetch a single Damage_Assessment by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_read(
    IN p_damage_assessment_id BIGINT
)
BEGIN
    SELECT damage_assessment_id, claim_id, estimated_cost, description,
           assessment_date, created_at
    FROM damage_assessment
    WHERE damage_assessment_id = p_damage_assessment_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_update: update the mutable fields of a Damage_Assessment.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_update(
    IN p_damage_assessment_id BIGINT,
    IN p_estimated_cost DECIMAL(12,2),
    IN p_description VARCHAR(1000),
    IN p_assessment_date DATE
)
BEGIN
    UPDATE damage_assessment
    SET estimated_cost = p_estimated_cost,
        description = p_description,
        assessment_date = p_assessment_date
    WHERE damage_assessment_id = p_damage_assessment_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_delete: delete a Damage_Assessment by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_delete(
    IN p_damage_assessment_id BIGINT
)
BEGIN
    DELETE FROM damage_assessment WHERE damage_assessment_id = p_damage_assessment_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_list_by_claim: list all Damage_Assessment rows for a Claim.
-- Requirement 4.2 (Claim detail view displays all Damage_Assessment records).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT damage_assessment_id, claim_id, estimated_cost, description,
           assessment_date, created_at
    FROM damage_assessment
    WHERE claim_id = p_claim_id
    ORDER BY assessment_date DESC, damage_assessment_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_sum_by_claim: sum estimated_cost for a Claim's Damage_Assessment rows.
-- Requirement 4.5 / 16.6: this procedure is composed/called by
-- sp_reserve_recalculate_from_assessments (task 5.2) to derive the Claim's
-- recommended Reserve amount. Returns 0.00 (not NULL) when the Claim has no
-- Damage_Assessment rows so the caller can safely use the OUT value directly.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_sum_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total_cost DECIMAL(12,2)
)
BEGIN
    SELECT COALESCE(SUM(estimated_cost), 0.00)
    INTO p_total_cost
    FROM damage_assessment
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_find_by_date_range: list a Claim's Damage_Assessment rows whose
-- assessment_date falls within [p_start_date, p_end_date] inclusive.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_find_by_date_range(
    IN p_claim_id BIGINT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT damage_assessment_id, claim_id, estimated_cost, description,
           assessment_date, created_at
    FROM damage_assessment
    WHERE claim_id = p_claim_id
      AND assessment_date BETWEEN p_start_date AND p_end_date
    ORDER BY assessment_date DESC, damage_assessment_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_count_by_claim: count Damage_Assessment rows for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_count_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM damage_assessment
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_exists: check whether a Damage_Assessment id exists.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_exists(
    IN p_damage_assessment_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_flag
    FROM damage_assessment
    WHERE damage_assessment_id = p_damage_assessment_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_da_latest_by_claim: fetch the single most recent Damage_Assessment for a
-- Claim (highest assessment_date, ties broken by highest id).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_da_latest_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT damage_assessment_id, claim_id, estimated_cost, description,
           assessment_date, created_at
    FROM damage_assessment
    WHERE claim_id = p_claim_id
    ORDER BY assessment_date DESC, damage_assessment_id DESC
    LIMIT 1;
END$$

DELIMITER ;

-- #############################################################################
-- ## RESERVE (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_reserve_create: insert the (exactly one) Reserve row for a Claim.
-- Requirement 5.1: current_amount validation (>0.00, <=999,999,999.99, up to
-- 2 decimal places) is enforced by the chk_reserve_current_amount CHECK
-- constraint and the DECIMAL(12,2) column type; this procedure performs the
-- insert and returns the new identifier.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_create(
    IN p_claim_id BIGINT,
    IN p_current_amount DECIMAL(12,2),
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO reserve (
        claim_id, current_amount, recommended_amount, updated_at
    ) VALUES (
        p_claim_id, p_current_amount, NULL, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_read: fetch a single Reserve by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_read(
    IN p_reserve_id BIGINT
)
BEGIN
    SELECT reserve_id, claim_id, current_amount, recommended_amount, updated_at
    FROM reserve
    WHERE reserve_id = p_reserve_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_update: update the current_amount of a Reserve by id.
-- Requirement 5.4: callers must separately write a Reserve_History row (via
-- sp_rh_create) when invoking this procedure as part of a Reserve change.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_update(
    IN p_reserve_id BIGINT,
    IN p_current_amount DECIMAL(12,2)
)
BEGIN
    UPDATE reserve
    SET current_amount = p_current_amount,
        updated_at = NOW()
    WHERE reserve_id = p_reserve_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_list: list all Reserve rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_list()
BEGIN
    SELECT reserve_id, claim_id, current_amount, recommended_amount, updated_at
    FROM reserve
    ORDER BY reserve_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_find_by_claim: fetch the Reserve row for a Claim (claim_id is
-- UNIQUE on this table, so at most one row is returned).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_find_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT reserve_id, claim_id, current_amount, recommended_amount, updated_at
    FROM reserve
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_get_current_amount: return a Claim's current Reserve amount.
-- Requirement 5.5: used by sp_reserve_set_amount (task 5.2) to compare against
-- the settlement payout floor before allowing a reduction.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_get_current_amount(
    IN p_claim_id BIGINT,
    OUT p_amount DECIMAL(12,2)
)
BEGIN
    SELECT current_amount INTO p_amount
    FROM reserve
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_exists: check whether a Reserve row exists for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_exists(
    IN p_claim_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_flag
    FROM reserve
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_set_recommended: set the recommended_amount for a Claim's
-- Reserve. Requirement 4.5: invoked after sp_da_sum_by_claim computes the sum
-- of Damage_Assessment estimated costs.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_set_recommended(
    IN p_claim_id BIGINT,
    IN p_recommended_amount DECIMAL(12,2)
)
BEGIN
    UPDATE reserve
    SET recommended_amount = p_recommended_amount,
        updated_at = NOW()
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_get_recommended: return a Claim's recommended Reserve amount.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_get_recommended(
    IN p_claim_id BIGINT,
    OUT p_amount DECIMAL(12,2)
)
BEGIN
    SELECT recommended_amount INTO p_amount
    FROM reserve
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_reserve_delete: delete a Reserve row by id. Admin-only; not exposed via
-- normal adjuster-facing application flows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reserve_delete(
    IN p_reserve_id BIGINT
)
BEGIN
    DELETE FROM reserve WHERE reserve_id = p_reserve_id;
END$$

DELIMITER ;

-- #############################################################################
-- ## RESERVE_HISTORY (10 procedures, INSERT-ONLY)
-- ##
-- ## Requirement 14.2 / 14.3: Reserve_History rows are permanently retained.
-- ## NO sp_rh_update and NO sp_rh_delete procedure exists in this file, and
-- ## none must ever be added for this table.
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_rh_create: insert a new Reserve_History row (insert-only audit trail).
-- Requirement 5.4: records the prior amount, new amount, reason, user, and
-- timestamp of a Reserve change.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_create(
    IN p_reserve_id BIGINT,
    IN p_prior_amount DECIMAL(12,2),
    IN p_new_amount DECIMAL(12,2),
    IN p_reason VARCHAR(500),
    IN p_changed_by VARCHAR(50),
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO reserve_history (
        reserve_id, prior_amount, new_amount, reason, changed_by, changed_at
    ) VALUES (
        p_reserve_id, p_prior_amount, p_new_amount, p_reason, p_changed_by, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_read: fetch a single Reserve_History row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_read(
    IN p_reserve_history_id BIGINT
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    WHERE reserve_history_id = p_reserve_history_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_list_by_reserve: list all Reserve_History rows for a Reserve, most
-- recent first. Requirement 5.6: Claim detail view displays Reserve_History
-- ordered from most recent to oldest.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_list_by_reserve(
    IN p_reserve_id BIGINT
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    WHERE reserve_id = p_reserve_id
    ORDER BY changed_at DESC, reserve_history_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_find_latest: fetch the single most recent Reserve_History row for a
-- Reserve.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_find_latest(
    IN p_reserve_id BIGINT
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    WHERE reserve_id = p_reserve_id
    ORDER BY changed_at DESC, reserve_history_id DESC
    LIMIT 1;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_count_by_reserve: count Reserve_History rows for a Reserve.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_count_by_reserve(
    IN p_reserve_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM reserve_history
    WHERE reserve_id = p_reserve_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_find_by_date_range: list a Reserve's Reserve_History rows whose
-- changed_at falls within [p_start_date, p_end_date] inclusive (date-only
-- bounds; p_end_date is treated as end-of-day).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_find_by_date_range(
    IN p_reserve_id BIGINT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    WHERE reserve_id = p_reserve_id
      AND changed_at >= p_start_date
      AND changed_at < DATE_ADD(p_end_date, INTERVAL 1 DAY)
    ORDER BY changed_at DESC, reserve_history_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_find_by_user: list Reserve_History rows recorded by a given user.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_find_by_user(
    IN p_changed_by VARCHAR(50)
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    WHERE changed_by = p_changed_by
    ORDER BY changed_at DESC, reserve_history_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_sum_changes_by_claim: sum the net Reserve movement (new_amount -
-- prior_amount) across all Reserve_History rows for a Claim, joining
-- reserve_history to reserve on reserve_id and filtering by reserve.claim_id.
-- Returns 0.00 (not NULL) when the Claim's Reserve has no history rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_sum_changes_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total DECIMAL(12,2)
)
BEGIN
    SELECT COALESCE(SUM(rh.new_amount - rh.prior_amount), 0.00)
    INTO p_total
    FROM reserve_history rh
    INNER JOIN reserve r ON r.reserve_id = rh.reserve_id
    WHERE r.claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_exists_for_reserve: check whether a Reserve has at least one
-- Reserve_History row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_exists_for_reserve(
    IN p_reserve_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0 INTO p_flag
    FROM reserve_history
    WHERE reserve_id = p_reserve_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_rh_list_all: paginated listing of all Reserve_History rows, most recent
-- first.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_rh_list_all(
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT reserve_history_id, reserve_id, prior_amount, new_amount, reason,
           changed_by, changed_at
    FROM reserve_history
    ORDER BY changed_at DESC, reserve_history_id DESC
    LIMIT p_limit OFFSET p_offset;
END$$

DELIMITER ;
