package com.icps.dao.jdbc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.icps.dao.FraudFlagDao;
import com.icps.model.FraudFlag;
import com.icps.model.rowmapper.FraudFlagRowMapper;

import java.sql.Types;

/**
 * {@link SimpleJdbcCall}-backed implementation of {@link FraudFlagDao}.
 *
 * All operations go through the {@code sp_ff_*} / {@code sp_fraud_score_recompute}
 * stored procedure library (no inline business SQL); result-set-returning
 * procedures are invoked via {@code JdbcTemplate.query(...)} with
 * {@link FraudFlagRowMapper}, and OUT-parameter procedures are invoked via
 * {@link SimpleJdbcCall}.
 */
@Repository
public class JdbcFraudFlagDao implements FraudFlagDao {

    @Resource(name = "dataSource")
    private DataSource dataSource;

    @Resource(name = "jdbcTemplate")
    private JdbcTemplate jdbcTemplate;

    @Override
    public Long create(Long claimId, String flagReason, Integer scoreWeight) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_ff_create")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_flag_reason", Types.VARCHAR),
                        new SqlParameter("p_score_weight", Types.INTEGER),
                        new SqlOutParameter("p_new_id", Types.BIGINT));
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_flag_reason", flagReason);
        params.put("p_score_weight", scoreWeight);
        Map<String, Object> out = call.execute(params);
        Object newId = out.get("p_new_id");
        return newId == null ? null : ((Number) newId).longValue();
    }

    @Override
    public FraudFlag findById(Long id) {
        List<FraudFlag> results = jdbcTemplate.query(
                "CALL sp_ff_read(?)",
                new FraudFlagRowMapper(),
                id);
        return results.isEmpty() ? null : results.get(0);
    }

    @Override
    public List<FraudFlag> findByClaim(Long claimId) {
        return jdbcTemplate.query(
                "CALL sp_ff_list_by_claim(?)",
                new FraudFlagRowMapper(),
                claimId);
    }

    @Override
    public List<FraudFlag> findActiveByClaim(Long claimId) {
        return jdbcTemplate.query(
                "CALL sp_ff_list_active_by_claim(?)",
                new FraudFlagRowMapper(),
                claimId);
    }

    @Override
    public void update(Long id, String flagReason, Integer scoreWeight, Boolean isActive) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_ff_update")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_fraud_flag_id", Types.BIGINT),
                        new SqlParameter("p_flag_reason", Types.VARCHAR),
                        new SqlParameter("p_score_weight", Types.INTEGER),
                        new SqlParameter("p_is_active", Types.TINYINT));
        Map<String, Object> params = new HashMap<>();
        params.put("p_fraud_flag_id", id);
        params.put("p_flag_reason", flagReason);
        params.put("p_score_weight", scoreWeight);
        params.put("p_is_active", isActive == null ? null : (isActive ? 1 : 0));
        call.execute(params);
    }

    @Override
    public void delete(Long id) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_ff_delete")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(new SqlParameter("p_fraud_flag_id", Types.BIGINT));
        Map<String, Object> params = new HashMap<>();
        params.put("p_fraud_flag_id", id);
        call.execute(params);
    }

    @Override
    public Map<String, Object> recomputeScore(Long claimId) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_fraud_score_recompute")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_new_score", Types.INTEGER),
                        new SqlOutParameter("p_under_review_flag", Types.TINYINT));
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = call.execute(params);
        Map<String, Object> result = new HashMap<>();
        Object newScore = out.get("p_new_score");
        result.put("newScore", newScore == null ? null : ((Number) newScore).intValue());
        Object underReview = out.get("p_under_review_flag");
        result.put("underReviewFlag", underReview != null && ((Number) underReview).intValue() != 0);
        return result;
    }
}
