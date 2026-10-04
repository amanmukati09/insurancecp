package com.icps.dao;

import java.util.List;
import java.util.Map;

/**
 * DAO interface exposing the primary reporting stored procedures.
 *
 * Each method delegates directly to a single reporting stored procedure
 * (Requirement 15.4) via {@code JdbcTemplate.queryForList}, which returns a
 * generic {@code List<Map<String,Object>>} row representation. This avoids
 * needing a dedicated POJO/RowMapper per report shape, since report rows are
 * ad-hoc projections (not full entities) computed entirely in the stored
 * procedure (Requirement 13).
 */
public interface ReportingDao {

    /**
     * CALL sp_report_adjuster_caseload() -- Requirement 13.1.
     */
    List<Map<String, Object>> getAdjusterCaseload();

    /**
     * CALL sp_report_claims_aging() -- Requirement 13.2.
     */
    List<Map<String, Object>> getClaimsAging();

    /**
     * CALL sp_report_reserve_adequacy() -- Requirement 13.3.
     */
    List<Map<String, Object>> getReserveAdequacy();

    /**
     * CALL sp_report_fraud_summary() -- Requirement 13.4 / 8.6.
     */
    List<Map<String, Object>> getFraudSummary();

    /**
     * CALL sp_report_subrogation_tracking() -- Requirement 13.5 / 11.7.
     */
    List<Map<String, Object>> getSubrogationTracking();

    /**
     * CALL sp_report_adjuster_worklist(?) -- Requirement 3.5 / 3.6.
     */
    List<Map<String, Object>> getAdjusterWorklist(Long adjusterId);
}
