-- =============================================================================
-- 30_sp_report_primary.sql
-- Insurance Claims Processing System (ICPS)
--
-- The 6 primary reporting stored procedures (Requirement 16.3 reporting
-- category; task 6.1 of 23 total reporting procedures).
--
-- Dialect: MySQL 8.x.
--
-- LOAD ORDER: This file MUST be loaded AFTER 01_ddl_core.sql,
-- 02_ddl_financial.sql, 03_ddl_fraud_doc_litigation_subrogation.sql, and
-- 04_ddl_lookup_audit.sql (depends on claim, adjuster, reserve,
-- damage_assessment, fraud_score, fraud_flag, subrogation_record,
-- settlement, report_cache_adjuster_caseload, report_cache_claims_aging).
--
-- Every procedure below returns its result set via a plain SELECT. A
-- SELECT that matches zero rows naturally returns an empty result set
-- without raising an error, satisfying Requirement 13.6.
--
-- Procedures in this file:
--   1. sp_report_adjuster_caseload       - Req 13.1
--   2. sp_report_claims_aging            - Req 13.2
--   3. sp_report_reserve_adequacy        - Req 13.3
--   4. sp_report_fraud_summary           - Req 8.6 / 13.4
--   5. sp_report_subrogation_tracking    - Req 11.7 / 13.5
--   6. sp_report_adjuster_worklist       - Req 3.6
-- =============================================================================
DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. sp_report_adjuster_caseload
--
-- Req 13.1: open-Claim count grouped by Adjuster. "Open" here means any
-- Claim status other than 'Closed' (consistent with the worklist definition
-- in Req 3.5/3.6). Adjusters with zero open claims still appear in the
-- result with a count of 0 (LEFT JOIN from adjuster to claim).
--
-- Side effect (per design.md): truncates and repopulates
-- report_cache_adjuster_caseload with the freshly computed counts before
-- returning the result set, so the cache always reflects the latest run.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_adjuster_caseload()
BEGIN
    TRUNCATE TABLE report_cache_adjuster_caseload;

    INSERT INTO report_cache_adjuster_caseload (adjuster_id, open_claim_count, generated_at)
    SELECT
        a.adjuster_id,
        COUNT(c.claim_id) AS open_claim_count,
        NOW() AS generated_at
    FROM adjuster a
    LEFT JOIN claim c
        ON c.adjuster_id = a.adjuster_id
        AND c.status <> 'Closed'
    GROUP BY a.adjuster_id;

    SELECT
        a.adjuster_id,
        a.first_name,
        a.last_name,
        COUNT(c.claim_id) AS open_claim_count
    FROM adjuster a
    LEFT JOIN claim c
        ON c.adjuster_id = a.adjuster_id
        AND c.status <> 'Closed'
    GROUP BY a.adjuster_id, a.first_name, a.last_name
    ORDER BY a.adjuster_id;
END$$

-- -----------------------------------------------------------------------------
-- 2. sp_report_claims_aging
--
-- Req 13.2: buckets Claims into 0-30 / 31-60 / 61-90 / 91+ days elapsed
-- "since FNOL" -- i.e. since claim.created_at (the FNOL/claim-creation
-- timestamp), not loss_date. Uses a derived table with a CASE expression to
-- compute the bucket per claim, then groups by bucket.
--
-- Side effect: truncates and repopulates report_cache_claims_aging with the
-- freshly computed bucket counts before returning the result set.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_claims_aging()
BEGIN
    TRUNCATE TABLE report_cache_claims_aging;

    INSERT INTO report_cache_claims_aging (aging_bucket, claim_count, generated_at)
    SELECT
        bucketed.aging_bucket,
        COUNT(*) AS claim_count,
        NOW() AS generated_at
    FROM (
        SELECT
            CASE
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 0 AND 30 THEN '0-30'
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 31 AND 60 THEN '31-60'
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 61 AND 90 THEN '61-90'
                ELSE '91+'
            END AS aging_bucket
        FROM claim c
    ) bucketed
    GROUP BY bucketed.aging_bucket;

    SELECT
        bucketed.aging_bucket,
        COUNT(*) AS claim_count
    FROM (
        SELECT
            CASE
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 0 AND 30 THEN '0-30'
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 31 AND 60 THEN '31-60'
                WHEN DATEDIFF(CURDATE(), c.created_at) BETWEEN 61 AND 90 THEN '61-90'
                ELSE '91+'
            END AS aging_bucket
        FROM claim c
    ) bucketed
    GROUP BY bucketed.aging_bucket
    ORDER BY
        CASE bucketed.aging_bucket
            WHEN '0-30' THEN 1
            WHEN '31-60' THEN 2
            WHEN '61-90' THEN 3
            ELSE 4
        END;
END$$

-- -----------------------------------------------------------------------------
-- 3. sp_report_reserve_adequacy
--
-- Req 13.3: for each Claim with a Reserve, returns the current reserve
-- amount, the total of associated Damage_Assessment estimated costs, and
-- the numeric difference (reserve - damage total). Uses a LEFT JOIN from
-- claim -> reserve and a derived-table aggregate over damage_assessment
-- (equivalent to the sp_da_sum_by_claim aggregation) joined per claim.
-- Claims with no damage assessments show a damage total of 0.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_reserve_adequacy()
BEGIN
    SELECT
        c.claim_id,
        r.current_amount AS current_reserve_amount,
        COALESCE(da_totals.damage_assessment_total, 0.00) AS damage_assessment_total,
        r.current_amount - COALESCE(da_totals.damage_assessment_total, 0.00) AS numeric_difference
    FROM claim c
    LEFT JOIN reserve r
        ON r.claim_id = c.claim_id
    LEFT JOIN (
        SELECT
            da.claim_id,
            SUM(da.estimated_cost) AS damage_assessment_total
        FROM damage_assessment da
        GROUP BY da.claim_id
    ) da_totals
        ON da_totals.claim_id = c.claim_id
    ORDER BY c.claim_id;
END$$

-- -----------------------------------------------------------------------------
-- 4. sp_report_fraud_summary
--
-- Req 8.6 / 13.4: for each Claim, returns the current fraud score (LEFT
-- JOIN to fraud_score so claims never scored show NULL), the Claim's
-- under_fraud_review flag, and a count of currently active fraud_flag rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_fraud_summary()
BEGIN
    SELECT
        c.claim_id,
        fs.score AS fraud_score,
        c.under_fraud_review,
        COUNT(ff.fraud_flag_id) AS active_fraud_flag_count
    FROM claim c
    LEFT JOIN fraud_score fs
        ON fs.claim_id = c.claim_id
    LEFT JOIN fraud_flag ff
        ON ff.claim_id = c.claim_id
        AND ff.is_active = 1
    GROUP BY c.claim_id, fs.score, c.under_fraud_review
    ORDER BY c.claim_id;
END$$

-- -----------------------------------------------------------------------------
-- 5. sp_report_subrogation_tracking
--
-- Req 11.7 / 13.5: one row per subrogation_record, joined to its parent
-- Claim to surface the third-party identifier, recovery amount, date
-- recorded, and the Claim's current net_paid_amount (post-recovery value).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_subrogation_tracking()
BEGIN
    SELECT
        sr.claim_id,
        sr.third_party_identifier,
        sr.recovery_amount,
        sr.recorded_date,
        c.net_paid_amount
    FROM subrogation_record sr
    INNER JOIN claim c
        ON c.claim_id = sr.claim_id
    ORDER BY sr.claim_id, sr.recorded_date DESC;
END$$

-- -----------------------------------------------------------------------------
-- 6. sp_report_adjuster_worklist
--
-- Req 3.6: all non-Closed Claims assigned to the given Adjuster, ordered by
-- Claim age (days elapsed since created_at, i.e. since FNOL) descending, so
-- the oldest/longest-outstanding claims appear first.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_report_adjuster_worklist(
    IN p_adjuster_id BIGINT
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
        c.version,
        c.created_at,
        c.updated_at,
        DATEDIFF(CURDATE(), c.created_at) AS claim_age_days
    FROM claim c
    WHERE c.adjuster_id = p_adjuster_id
        AND c.status <> 'Closed'
    ORDER BY DATEDIFF(CURDATE(), c.created_at) DESC;
END$$

DELIMITER ;
