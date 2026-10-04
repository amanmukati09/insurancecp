-- =============================================================================
-- 31_sp_report_supporting.sql
-- Insurance Claims Processing System (ICPS)
--
-- Remaining 17 supporting reporting procedures (task 6.2). These complement
-- the 6 primary reporting procedures (task 6.1 / 30_sp_report_primary.sql)
-- to total 23 reporting procedures (Req 16.3).
--
-- All procedures here are simple, read-only, SELECT-based reports. None of
-- them mutate data, and all return a result set gracefully (including an
-- empty result set, never an error) when no rows match the criteria —
-- satisfying Req 13.6.
--
-- Dialect: MySQL 8.x.
-- Requirements: 16.3, 13.6.
-- =============================================================================
DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. sp_report_claims_by_status_count
-- Count of claims grouped by status. All 6 fixed statuses are represented,
-- even those with zero claims, via a derived table of status literals
-- LEFT JOINed to `claim` (Req 13.6 - graceful empty-bucket handling).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_by_status_count()
BEGIN
    SELECT s.status, COUNT(c.claim_id) AS claim_count
    FROM (
        SELECT 'Open' AS status
        UNION ALL SELECT 'Investigating'
        UNION ALL SELECT 'Approved'
        UNION ALL SELECT 'Denied'
        UNION ALL SELECT 'Settled'
        UNION ALL SELECT 'Closed'
    ) s
    LEFT JOIN claim c ON c.status = s.status
    GROUP BY s.status;
END$$

-- -----------------------------------------------------------------------------
-- 2. sp_report_claims_by_policy_type
-- Count of claims grouped by the policy type of their linked Policy_Reference.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_by_policy_type()
BEGIN
    SELECT pr.policy_type, COUNT(c.claim_id) AS claim_count
    FROM claim c
    JOIN policy_reference pr ON pr.policy_reference_id = c.policy_reference_id
    GROUP BY pr.policy_type;
END$$

-- -----------------------------------------------------------------------------
-- 3. sp_report_settlement_summary
-- Single-row summary of all Settlement payouts.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_settlement_summary()
BEGIN
    SELECT
        COUNT(*)            AS settlement_count,
        AVG(payout_amount)  AS avg_payout_amount,
        MIN(payout_amount)  AS min_payout_amount,
        MAX(payout_amount)  AS max_payout_amount,
        SUM(payout_amount)  AS total_payout_amount
    FROM settlement;
END$$

-- -----------------------------------------------------------------------------
-- 4. sp_report_litigation_summary
-- Count of Litigation_Record rows grouped by status.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_litigation_summary()
BEGIN
    SELECT status, COUNT(*) AS record_count
    FROM litigation_record
    GROUP BY status;
END$$

-- -----------------------------------------------------------------------------
-- 5. sp_report_document_counts_by_type
-- Count of Document_Metadata rows grouped by document type.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_document_counts_by_type()
BEGIN
    SELECT document_type, COUNT(*) AS document_count
    FROM document_metadata
    GROUP BY document_type;
END$$

-- -----------------------------------------------------------------------------
-- 6. sp_report_claim_status_history_audit
-- Full chronological (oldest-first) audit trail of status changes for one
-- Claim. Returns an empty result set if the claim has no history rows or
-- does not exist (Req 13.6).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claim_status_history_audit(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT history_id, claim_id, prior_status, new_status, changed_by, changed_at, note
    FROM claim_status_history
    WHERE claim_id = p_claim_id
    ORDER BY changed_at ASC;
END$$

-- -----------------------------------------------------------------------------
-- 7. sp_report_reserve_history_audit
-- Full chronological (oldest-first) audit trail of Reserve amount changes
-- for one Claim's Reserve, resolved via reserve.claim_id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_reserve_history_audit(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT rh.reserve_history_id, rh.reserve_id, rh.prior_amount, rh.new_amount,
           rh.reason, rh.changed_by, rh.changed_at
    FROM reserve_history rh
    JOIN reserve r ON r.reserve_id = rh.reserve_id
    WHERE r.claim_id = p_claim_id
    ORDER BY rh.changed_at ASC;
END$$

-- -----------------------------------------------------------------------------
-- 8. sp_report_claims_created_by_date_range
-- Claims created within a given date/time range.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_created_by_date_range(
    IN p_start_date DATETIME,
    IN p_end_date   DATETIME
)
BEGIN
    SELECT claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
           loss_description, status, under_fraud_review, net_paid_amount,
           version, created_at, updated_at
    FROM claim
    WHERE created_at BETWEEN p_start_date AND p_end_date
    ORDER BY created_at ASC;
END$$

-- -----------------------------------------------------------------------------
-- 9. sp_report_average_settlement_by_policy_type
-- Average Settlement payout amount grouped by policy type.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_average_settlement_by_policy_type()
BEGIN
    SELECT pr.policy_type, AVG(s.payout_amount) AS avg_payout_amount
    FROM claim c
    JOIN policy_reference pr ON pr.policy_reference_id = c.policy_reference_id
    JOIN settlement s ON s.claim_id = c.claim_id
    GROUP BY pr.policy_type;
END$$

-- -----------------------------------------------------------------------------
-- 10. sp_report_fraud_review_claims
-- All claims currently under fraud review, with claimant and adjuster names.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_fraud_review_claims()
BEGIN
    SELECT c.claim_id, c.status, c.under_fraud_review, c.net_paid_amount,
           c.created_at,
           cl.claimant_id, cl.first_name AS claimant_first_name, cl.last_name AS claimant_last_name,
           a.adjuster_id, a.first_name AS adjuster_first_name, a.last_name AS adjuster_last_name
    FROM claim c
    JOIN claimant cl ON cl.claimant_id = c.claimant_id
    LEFT JOIN adjuster a ON a.adjuster_id = c.adjuster_id
    WHERE c.under_fraud_review = 1;
END$$

-- -----------------------------------------------------------------------------
-- 11. sp_report_adjuster_performance
-- Per-adjuster count of Settled/Closed claims and average days-to-settle.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_adjuster_performance()
BEGIN
    SELECT a.adjuster_id,
           a.first_name,
           a.last_name,
           COUNT(c.claim_id) AS settled_closed_count,
           AVG(DATEDIFF(s.approved_at, c.created_at)) AS avg_days_to_settle
    FROM adjuster a
    JOIN claim c ON c.adjuster_id = a.adjuster_id AND c.status IN ('Settled', 'Closed')
    LEFT JOIN settlement s ON s.claim_id = c.claim_id
    GROUP BY a.adjuster_id, a.first_name, a.last_name;
END$$

-- -----------------------------------------------------------------------------
-- 12. sp_report_claims_without_reserve
-- Data-integrity report: claims that have no matching Reserve row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_without_reserve()
BEGIN
    SELECT c.claim_id, c.claimant_id, c.policy_reference_id, c.adjuster_id,
           c.loss_date, c.status, c.created_at
    FROM claim c
    LEFT JOIN reserve r ON r.claim_id = c.claim_id
    WHERE r.reserve_id IS NULL;
END$$

-- -----------------------------------------------------------------------------
-- 13. sp_report_claims_without_settlement_in_settled_status
-- Data-integrity report: claims marked 'Settled' with no matching Settlement
-- row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_without_settlement_in_settled_status()
BEGIN
    SELECT c.claim_id, c.claimant_id, c.policy_reference_id, c.adjuster_id,
           c.loss_date, c.status, c.created_at
    FROM claim c
    LEFT JOIN settlement s ON s.claim_id = c.claim_id
    WHERE c.status = 'Settled'
      AND s.settlement_id IS NULL;
END$$

-- -----------------------------------------------------------------------------
-- 14. sp_report_total_reserves_outstanding
-- Single-value summary: total current Reserve amount for all claims that are
-- not yet Settled or Closed.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_total_reserves_outstanding()
BEGIN
    SELECT COALESCE(SUM(r.current_amount), 0.00) AS total_reserves_outstanding
    FROM reserve r
    JOIN claim c ON c.claim_id = r.claim_id
    WHERE c.status NOT IN ('Settled', 'Closed');
END$$

-- -----------------------------------------------------------------------------
-- 15. sp_report_total_recovered_subrogation
-- Single-value summary: total subrogation recovery amount across all claims.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_total_recovered_subrogation()
BEGIN
    SELECT COALESCE(SUM(recovery_amount), 0.00) AS total_recovered_subrogation
    FROM subrogation_record;
END$$

-- -----------------------------------------------------------------------------
-- 16. sp_report_claims_aging_detail
-- Claim-level detail (not just counts) for a single aging bucket, using the
-- same DATEDIFF/CASE bucketing logic as sp_report_claims_aging.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_aging_detail(
    IN p_bucket VARCHAR(10)
)
BEGIN
    SELECT claim_id, claimant_id, policy_reference_id, adjuster_id, loss_date,
           status, created_at,
           DATEDIFF(CURDATE(), loss_date) AS age_in_days
    FROM claim
    WHERE
        CASE
            WHEN DATEDIFF(CURDATE(), loss_date) BETWEEN 0 AND 30 THEN '0-30'
            WHEN DATEDIFF(CURDATE(), loss_date) BETWEEN 31 AND 60 THEN '31-60'
            WHEN DATEDIFF(CURDATE(), loss_date) BETWEEN 61 AND 90 THEN '61-90'
            ELSE '91+'
        END = p_bucket
    ORDER BY loss_date ASC;
END$$

-- -----------------------------------------------------------------------------
-- 17. sp_report_execution_errors
-- Ops visibility report: all FAILURE rows from sp_execution_log, most recent
-- first.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_execution_errors()
BEGIN
    SELECT log_id, procedure_name, status, error_message, executed_at
    FROM sp_execution_log
    WHERE status = 'FAILURE'
    ORDER BY executed_at DESC;
END$$

DELIMITER ;
