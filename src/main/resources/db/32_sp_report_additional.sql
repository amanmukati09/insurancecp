-- =============================================================================
-- 32_sp_report_additional.sql
-- Insurance Claims Processing System (ICPS)
--
-- 9 additional reporting/utility procedures that round out the reporting
-- category to 23 total (Requirement 16.3), complementing the 6 primary
-- (30_sp_report_primary.sql) and 17 supporting (31_sp_report_supporting.sql)
-- reporting procedures.
--
-- Dialect: MySQL 8.x.
--
-- LOAD ORDER: This file MUST be loaded AFTER 01_ddl_core.sql,
-- 02_ddl_financial.sql, 03_ddl_fraud_doc_litigation_subrogation.sql, and
-- 04_ddl_lookup_audit.sql (depends on claim, claimant, adjuster,
-- policy_reference, reserve, settlement, damage_assessment, fraud_flag,
-- audit_log).
--
-- All procedures below are read-only SELECT-based reports. A SELECT that
-- matches zero rows naturally returns an empty result set without raising
-- an error, satisfying Requirement 13.6.
--
-- Procedures in this file:
--   1. sp_report_claim_full_detail
--   2. sp_report_claims_by_adjuster_and_status
--   3. sp_report_damage_assessment_summary
--   4. sp_report_claimant_claim_count
--   5. sp_report_policy_reference_utilization
--   6. sp_report_settlement_vs_reserve_variance
--   7. sp_report_open_claims_without_adjuster
--   8. sp_report_fraud_flags_by_reason
--   9. sp_report_audit_log_recent
-- =============================================================================
DELIMITER $$
-- -----------------------------------------------------------------------------
-- 1. sp_report_claim_full_detail
--
-- "Detail page" style report: one comprehensive result set for a single
-- Claim joining claimant, adjuster, policy_reference, and reserve. Uses
-- LEFT JOINs for adjuster and reserve (may be unassigned / not yet set up)
-- and INNER JOINs for claimant and policy_reference (always present).
-- Returns an empty result set if the claim does not exist (Req 13.6).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claim_full_detail(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT
        c.claim_id,
        c.loss_date,
        c.loss_description,
        c.status,
        c.under_fraud_review,
        c.net_paid_amount,
        c.created_at,
        c.updated_at,
        cl.claimant_id,
        cl.first_name AS claimant_first_name,
        cl.last_name AS claimant_last_name,
        cl.phone AS claimant_phone,
        cl.email AS claimant_email,
        a.adjuster_id,
        a.first_name AS adjuster_first_name,
        a.last_name AS adjuster_last_name,
        pr.policy_reference_id,
        pr.policy_number,
        pr.policy_type,
        pr.coverage_limit,
        pr.deductible,
        r.reserve_id,
        r.current_amount AS reserve_current_amount,
        r.recommended_amount AS reserve_recommended_amount
    FROM claim c
    INNER JOIN claimant cl ON cl.claimant_id = c.claimant_id
    INNER JOIN policy_reference pr ON pr.policy_reference_id = c.policy_reference_id
    LEFT JOIN adjuster a ON a.adjuster_id = c.adjuster_id
    LEFT JOIN reserve r ON r.claim_id = c.claim_id
    WHERE c.claim_id = p_claim_id;
END$$
-- -----------------------------------------------------------------------------
-- 2. sp_report_claims_by_adjuster_and_status
--
-- Filtered claim list for a given Adjuster and Claim status.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_by_adjuster_and_status(
    IN p_adjuster_id BIGINT,
    IN p_status VARCHAR(20)
)
BEGIN
    SELECT
        c.claim_id,
        c.claimant_id,
        c.policy_reference_id,
        c.adjuster_id,
        c.loss_date,
        c.loss_description,
        c.status,
        c.under_fraud_review,
        c.net_paid_amount,
        c.created_at,
        c.updated_at
    FROM claim c
    WHERE c.adjuster_id = p_adjuster_id
      AND c.status = p_status
    ORDER BY c.created_at ASC;
END$$
-- -----------------------------------------------------------------------------
-- 3. sp_report_damage_assessment_summary
--
-- Per-claim count and total estimated_cost of Damage_Assessment rows,
-- across all claims that have at least one assessment.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_damage_assessment_summary()
BEGIN
    SELECT
        da.claim_id,
        COUNT(*) AS assessment_count,
        SUM(da.estimated_cost) AS total_estimated_cost
    FROM damage_assessment da
    GROUP BY da.claim_id
    ORDER BY da.claim_id;
END$$
-- -----------------------------------------------------------------------------
-- 4. sp_report_claimant_claim_count
--
-- Claimant_id, name, and COUNT of claims per claimant. Uses a LEFT JOIN so
-- claimants with zero claims still appear with a count of 0 (Req 13.6
-- graceful empty-bucket handling).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claimant_claim_count()
BEGIN
    SELECT
        cl.claimant_id,
        cl.first_name,
        cl.last_name,
        COUNT(c.claim_id) AS claim_count
    FROM claimant cl
    LEFT JOIN claim c ON c.claimant_id = cl.claimant_id
    GROUP BY cl.claimant_id, cl.first_name, cl.last_name
    ORDER BY cl.claimant_id;
END$$
-- -----------------------------------------------------------------------------
-- 5. sp_report_policy_reference_utilization
--
-- Policy_reference_id, policy_number, and COUNT of claims referencing each
-- policy. Uses a LEFT JOIN so policies with zero claims still appear with a
-- count of 0.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_policy_reference_utilization()
BEGIN
    SELECT
        pr.policy_reference_id,
        pr.policy_number,
        COUNT(c.claim_id) AS claim_count
    FROM policy_reference pr
    LEFT JOIN claim c ON c.policy_reference_id = pr.policy_reference_id
    GROUP BY pr.policy_reference_id, pr.policy_number
    ORDER BY pr.policy_reference_id;
END$$
-- -----------------------------------------------------------------------------
-- 6. sp_report_settlement_vs_reserve_variance
--
-- For each Claim that has both a Reserve and a Settlement, the difference
-- between reserve.current_amount and settlement.payout_amount. Inner-joins
-- claim to reserve and settlement since the variance is only meaningful
-- when both exist for the claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_settlement_vs_reserve_variance()
BEGIN
    SELECT
        c.claim_id,
        r.current_amount AS reserve_current_amount,
        s.payout_amount AS settlement_payout_amount,
        r.current_amount - s.payout_amount AS variance_amount
    FROM claim c
    INNER JOIN reserve r ON r.claim_id = c.claim_id
    INNER JOIN settlement s ON s.claim_id = c.claim_id
    ORDER BY c.claim_id;
END$$
-- -----------------------------------------------------------------------------
-- 7. sp_report_open_claims_without_adjuster
--
-- Unassigned-claims report: Claims where adjuster_id IS NULL and status is
-- not 'Closed'.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_open_claims_without_adjuster()
BEGIN
    SELECT
        c.claim_id,
        c.claimant_id,
        c.policy_reference_id,
        c.loss_date,
        c.loss_description,
        c.status,
        c.created_at
    FROM claim c
    WHERE c.adjuster_id IS NULL
      AND c.status <> 'Closed'
    ORDER BY c.created_at ASC;
END$$
-- -----------------------------------------------------------------------------
-- 8. sp_report_fraud_flags_by_reason
--
-- Flag_reason and COUNT(*) grouped, across all Fraud_Flag rows (both active
-- and inactive).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_fraud_flags_by_reason()
BEGIN
    SELECT
        ff.flag_reason,
        COUNT(*) AS flag_count
    FROM fraud_flag ff
    GROUP BY ff.flag_reason
    ORDER BY flag_count DESC;
END$$
-- -----------------------------------------------------------------------------
-- 9. sp_report_audit_log_recent
--
-- Parameterized recent-activity report: the most recent p_limit rows from
-- Audit_Log ordered by performed_at descending.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_audit_log_recent(
    IN p_limit INT
)
BEGIN
    SELECT
        al.audit_id,
        al.entity_name,
        al.entity_id,
        al.action,
        al.performed_by,
        al.performed_at,
        al.detail
    FROM audit_log al
    ORDER BY al.performed_at DESC
    LIMIT p_limit;
END$$
DELIMITER ;
