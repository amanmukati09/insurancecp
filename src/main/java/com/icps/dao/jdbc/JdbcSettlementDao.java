package com.icps.dao.jdbc;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.stereotype.Repository;

import com.icps.dao.SettlementDao;
import com.icps.model.Settlement;
import com.icps.model.rowmapper.SettlementRowMapper;

import java.sql.Types;

/**
 * {@link SimpleJdbcCall}-backed implementation of {@link SettlementDao}.
 *
 * All operations go through the {@code sp_settlement_*} stored procedure
 * library (no inline business SQL); result-set-returning procedures are
 * invoked via {@code JdbcTemplate.query(...)} with {@link SettlementRowMapper},
 * and OUT-parameter procedures are invoked via {@link SimpleJdbcCall}.
 */
@Repository
public class JdbcSettlementDao implements SettlementDao {

    @Resource(name = "dataSource")
    private DataSource dataSource;

    @Resource(name = "jdbcTemplate")
    private JdbcTemplate jdbcTemplate;

    @Override
    public Settlement findByClaimId(Long claimId) {
        List<Settlement> results = jdbcTemplate.query(
                "CALL sp_settlement_find_by_claim(?)",
                new SettlementRowMapper(),
                claimId);
        return results.isEmpty() ? null : results.get(0);
    }

    @Override
    public Boolean existsForClaim(Long claimId) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_settlement_exists_for_claim")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_exists_flag", Types.TINYINT));
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = call.execute(params);
        Object flag = out.get("p_exists_flag");
        return flag != null && ((Number) flag).intValue() != 0;
    }

    @Override
    public Map<String, Object> calculate(Long claimId) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_settlement_calculate")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_payout_amount", Types.DECIMAL),
                        new SqlOutParameter("p_error_message", Types.VARCHAR));
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = call.execute(params);
        Map<String, Object> result = new HashMap<>();
        result.put("payoutAmount", (BigDecimal) out.get("p_payout_amount"));
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }

    @Override
    public Map<String, Object> approve(Long claimId, String approvedBy) {
        SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_settlement_approve")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_approved_by", Types.VARCHAR),
                        new SqlOutParameter("p_new_settlement_id", Types.BIGINT),
                        new SqlOutParameter("p_error_message", Types.VARCHAR));
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_approved_by", approvedBy);
        Map<String, Object> out = call.execute(params);
        Map<String, Object> result = new HashMap<>();
        result.put("newSettlementId", out.get("p_new_settlement_id"));
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }

    @Override
    public List<Settlement> findAll() {
        return jdbcTemplate.query("CALL sp_settlement_list()", new SettlementRowMapper());
    }
}
