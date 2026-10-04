package com.icps.dao.jdbc;

import java.util.List;
import java.util.Map;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import com.icps.dao.ReportingDao;

/**
 * {@code JdbcTemplate}-backed implementation of {@link ReportingDao}.
 *
 * All six primary reporting procedures are result-set-returning (no OUT
 * params), so each method is invoked via {@link JdbcTemplate#queryForList}
 * with raw {@code CALL} syntax, matching the pattern used by the other
 * result-set-returning procedures in {@code JdbcClaimDao} and friends. No
 * inline business SQL/aggregation logic is used (Requirement 15.4,
 * Requirement 13) -- every method delegates to a single reporting stored
 * procedure from task 6.1.
 */
@Repository
public class JdbcReportingDao implements ReportingDao {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public List<Map<String, Object>> getAdjusterCaseload() {
        return jdbcTemplate.queryForList("CALL sp_report_adjuster_caseload()");
    }

    @Override
    public List<Map<String, Object>> getClaimsAging() {
        return jdbcTemplate.queryForList("CALL sp_report_claims_aging()");
    }

    @Override
    public List<Map<String, Object>> getReserveAdequacy() {
        return jdbcTemplate.queryForList("CALL sp_report_reserve_adequacy()");
    }

    @Override
    public List<Map<String, Object>> getFraudSummary() {
        return jdbcTemplate.queryForList("CALL sp_report_fraud_summary()");
    }

    @Override
    public List<Map<String, Object>> getSubrogationTracking() {
        return jdbcTemplate.queryForList("CALL sp_report_subrogation_tracking()");
    }

    @Override
    public List<Map<String, Object>> getAdjusterWorklist(Long adjusterId) {
        return jdbcTemplate.queryForList("CALL sp_report_adjuster_worklist(?)", adjusterId);
    }
}
