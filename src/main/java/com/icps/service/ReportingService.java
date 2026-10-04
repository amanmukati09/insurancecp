package com.icps.service;

import java.util.List;
import java.util.Map;

/**
 * The ICPS component responsible for generating claims reports.
 *
 * Per design.md, every method delegates to a {@code SimpleJdbcCall}/
 * {@code JdbcTemplate}-backed reporting stored procedure -- no reporting
 * SQL or aggregation logic lives in Java (Requirement 13).
 */
public interface ReportingService {

    /**
     * Requirement 3.5, 3.6: the adjuster's assigned, non-Closed Claims
     * ordered by Claim age descending.
     */
    List<Map<String, Object>> getAdjusterWorklist(Long adjusterId);

    /**
     * Requirement 13.1: open Claim counts per Adjuster.
     */
    List<Map<String, Object>> getAdjusterCaseload();

    /**
     * Requirement 13.2: Claims grouped into aging buckets.
     */
    List<Map<String, Object>> getAgingReport();

    /**
     * Requirement 13.3: Reserve amount vs. total Damage_Assessment cost per
     * Claim.
     */
    List<Map<String, Object>> getReserveAdequacy();

    /**
     * Requirement 13.4 / 8.6: fraud flag summary report.
     */
    List<Map<String, Object>> getFraudSummary();

    /**
     * Requirement 11.7, 13.5: subrogation recovery tracking report.
     */
    List<Map<String, Object>> getSubrogationReport();
}
