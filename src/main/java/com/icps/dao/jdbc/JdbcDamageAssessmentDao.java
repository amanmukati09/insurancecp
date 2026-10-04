package com.icps.dao.jdbc;

import java.math.BigDecimal;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.sql.DataSource;

import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.icps.dao.DamageAssessmentDao;
import com.icps.model.DamageAssessment;
import com.icps.model.rowmapper.DamageAssessmentRowMapper;

/**
 * {@code SimpleJdbcCall}-backed implementation of {@link DamageAssessmentDao}.
 *
 * All operations invoke the stored procedures defined in
 * {@code 12_sp_crud_damage_reserve.sql}; no inline SQL is used
 * (Requirement 15.4, 17.2). One {@link SimpleJdbcCall} instance is configured
 * per procedure at construction time via {@code @Resource}-injected
 * {@link DataSource}, following the same pattern as the other JDBC DAOs in
 * this package.
 */
@Repository
public class JdbcDamageAssessmentDao implements DamageAssessmentDao {

    @Resource(name = "dataSource")
    private DataSource dataSource;

    private SimpleJdbcCall createCall;
    private SimpleJdbcCall readCall;
    private SimpleJdbcCall updateCall;
    private SimpleJdbcCall deleteCall;
    private SimpleJdbcCall listByClaimCall;
    private SimpleJdbcCall sumByClaimCall;

    @javax.annotation.PostConstruct
    public void init() {
        createCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_create")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_estimated_cost", Types.DECIMAL),
                        new SqlParameter("p_description", Types.VARCHAR),
                        new SqlParameter("p_assessment_date", Types.DATE),
                        new SqlOutParameter("p_new_id", Types.BIGINT));

        readCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_read")
                .returningResultSet("#result-set-1", new DamageAssessmentRowMapper())
                .declareParameters(new SqlParameter("p_damage_assessment_id", Types.BIGINT));

        updateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_update")
                .declareParameters(
                        new SqlParameter("p_damage_assessment_id", Types.BIGINT),
                        new SqlParameter("p_estimated_cost", Types.DECIMAL),
                        new SqlParameter("p_description", Types.VARCHAR),
                        new SqlParameter("p_assessment_date", Types.DATE));

        deleteCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_delete")
                .declareParameters(new SqlParameter("p_damage_assessment_id", Types.BIGINT));

        listByClaimCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_list_by_claim")
                .returningResultSet("#result-set-1", new DamageAssessmentRowMapper())
                .declareParameters(new SqlParameter("p_claim_id", Types.BIGINT));

        sumByClaimCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_da_sum_by_claim")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_total_cost", Types.DECIMAL));
    }

    @Override
    public Long create(Long claimId, BigDecimal estimatedCost, String description, Date assessmentDate) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_estimated_cost", estimatedCost);
        params.put("p_description", description);
        params.put("p_assessment_date", assessmentDate);
        Map<String, Object> out = createCall.execute(params);
        Number newId = (Number) out.get("p_new_id");
        return newId == null ? null : newId.longValue();
    }

    @Override
    @SuppressWarnings("unchecked")
    public DamageAssessment findById(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_damage_assessment_id", id);
        Map<String, Object> out = readCall.execute(params);
        List<DamageAssessment> rows = (List<DamageAssessment>) out.get("#result-set-1");
        return (rows == null || rows.isEmpty()) ? null : rows.get(0);
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<DamageAssessment> findByClaim(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = listByClaimCall.execute(params);
        List<DamageAssessment> rows = (List<DamageAssessment>) out.get("#result-set-1");
        return rows == null ? new ArrayList<>() : rows;
    }

    @Override
    public void update(Long id, BigDecimal estimatedCost, String description, Date assessmentDate) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_damage_assessment_id", id);
        params.put("p_estimated_cost", estimatedCost);
        params.put("p_description", description);
        params.put("p_assessment_date", assessmentDate);
        updateCall.execute(params);
    }

    @Override
    public void delete(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_damage_assessment_id", id);
        deleteCall.execute(params);
    }

    @Override
    public BigDecimal sumByClaim(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = sumByClaimCall.execute(params);
        BigDecimal total = (BigDecimal) out.get("p_total_cost");
        return total == null ? BigDecimal.ZERO : total;
    }
}
