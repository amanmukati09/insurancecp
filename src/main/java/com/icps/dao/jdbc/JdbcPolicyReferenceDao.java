package com.icps.dao.jdbc;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Map;
import javax.annotation.PostConstruct;
import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;
import com.icps.dao.PolicyReferenceDao;
import com.icps.model.PolicyReference;
import com.icps.model.rowmapper.PolicyReferenceRowMapper;
/**
 * {@code SimpleJdbcCall}-backed implementation of {@link PolicyReferenceDao}.
 *
 * Result-set-returning procedures ({@code sp_policy_reference_read},
 * {@code sp_policy_reference_find_by_number}, {@code sp_policy_reference_list})
 * are invoked via {@link JdbcTemplate#query} with raw {@code CALL} syntax and
 * a {@link PolicyReferenceRowMapper}, which is more reliable against MySQL
 * than {@code SimpleJdbcCall} for result-set procedures. The OUT-param-only
 * procedures ({@code sp_policy_reference_validate_date_range},
 * {@code sp_policy_reference_create}) and the no-result-set
 * {@code sp_policy_reference_update}/{@code sp_policy_reference_delete}
 * procedures use {@code SimpleJdbcCall}. No inline business SQL is used
 * (Requirement 15.4).
 */
@Repository
public class JdbcPolicyReferenceDao implements PolicyReferenceDao {
    @Autowired
    private DataSource dataSource;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    private SimpleJdbcCall validateDateRangeCall;
    private SimpleJdbcCall createCall;
    private SimpleJdbcCall updateCall;
    private SimpleJdbcCall deleteCall;
    @PostConstruct
    private void init() {
        validateDateRangeCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_policy_reference_validate_date_range");
        createCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_policy_reference_create");
        updateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_policy_reference_update")
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames("p_policy_reference_id", "p_policy_number", "p_policy_type",
                        "p_coverage_limit", "p_deductible", "p_effective_start_date", "p_effective_end_date");
        deleteCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_policy_reference_delete")
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames("p_policy_reference_id");
    }
    @Override
    public PolicyReference findById(Long id) {
        List<PolicyReference> results = jdbcTemplate.query(
                "CALL sp_policy_reference_read(?)",
                new Object[] { id },
                new PolicyReferenceRowMapper());
        return results.isEmpty() ? null : results.get(0);
    }
    @Override
    public PolicyReference findByNumber(String policyNumber) {
        List<PolicyReference> results = jdbcTemplate.query(
                "CALL sp_policy_reference_find_by_number(?)",
                new Object[] { policyNumber },
                new PolicyReferenceRowMapper());
        return results.isEmpty() ? null : results.get(0);
    }
    @Override
    public List<PolicyReference> findAll() {
        return jdbcTemplate.query(
                "CALL sp_policy_reference_list()",
                new PolicyReferenceRowMapper());
    }
    @Override
    public Boolean validateDateRange(Long policyReferenceId, Date lossDate) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_policy_reference_id", policyReferenceId)
                .addValue("p_loss_date", lossDate);
        Map<String, Object> out = validateDateRangeCall.execute(params);
        Number isValidFlag = (Number) out.get("p_is_valid_flag");
        return isValidFlag != null && isValidFlag.intValue() != 0;
    }
    @Override
    public Long create(String policyNumber, String policyType, BigDecimal coverageLimit,
            BigDecimal deductible, Date effectiveStartDate, Date effectiveEndDate) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_policy_number", policyNumber)
                .addValue("p_policy_type", policyType)
                .addValue("p_coverage_limit", coverageLimit)
                .addValue("p_deductible", deductible)
                .addValue("p_effective_start_date", effectiveStartDate)
                .addValue("p_effective_end_date", effectiveEndDate);
        Map<String, Object> out = createCall.execute(params);
        Number newId = (Number) out.get("p_new_id");
        return newId == null ? null : newId.longValue();
    }
    @Override
    public void update(Long id, String policyNumber, String policyType, BigDecimal coverageLimit,
            BigDecimal deductible, Date effectiveStartDate, Date effectiveEndDate) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_policy_reference_id", id)
                .addValue("p_policy_number", policyNumber)
                .addValue("p_policy_type", policyType)
                .addValue("p_coverage_limit", coverageLimit)
                .addValue("p_deductible", deductible)
                .addValue("p_effective_start_date", effectiveStartDate)
                .addValue("p_effective_end_date", effectiveEndDate);
        updateCall.execute(params);
    }
    @Override
    public void delete(Long id) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_policy_reference_id", id);
        deleteCall.execute(params);
    }
}
