package com.icps.dao.jdbc;

import java.math.BigDecimal;
import java.sql.Types;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.sql.DataSource;

import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.icps.dao.ReserveDao;
import com.icps.model.Reserve;
import com.icps.model.rowmapper.ReserveRowMapper;

/**
 * {@code SimpleJdbcCall}-backed implementation of {@link ReserveDao}.
 *
 * {@link #findByClaimId} invokes the plain CRUD procedure
 * {@code sp_reserve_find_by_claim} ({@code 12_sp_crud_damage_reserve.sql}).
 * {@link #setAmount} and {@link #recalculateFromAssessments} invoke the
 * business-rule-heavy, transactional/composed lifecycle procedures
 * {@code sp_reserve_set_amount} and {@code sp_reserve_recalculate_from_assessments}
 * ({@code 23_sp_lifecycle_reserve_settlement.sql}). No inline SQL is used
 * (Requirement 15.4, 17.2).
 */
@Repository
public class JdbcReserveDao implements ReserveDao {

    @Resource(name = "dataSource")
    private DataSource dataSource;

    private SimpleJdbcCall findByClaimCall;
    private SimpleJdbcCall setAmountCall;
    private SimpleJdbcCall recalculateCall;

    @javax.annotation.PostConstruct
    public void init() {
        findByClaimCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_reserve_find_by_claim")
                .returningResultSet("#result-set-1", new ReserveRowMapper())
                .declareParameters(new SqlParameter("p_claim_id", Types.BIGINT));

        // sp_reserve_set_amount: transactional lifecycle procedure
        // (23_sp_lifecycle_reserve_settlement.sql). Validates the amount,
        // enforces the settlement floor, updates reserve, and appends a
        // Reserve_History row, all atomically.
        setAmountCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_reserve_set_amount")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_new_amount", Types.DECIMAL),
                        new SqlParameter("p_reason", Types.VARCHAR),
                        new SqlParameter("p_changed_by", Types.VARCHAR),
                        new SqlOutParameter("p_success_flag", Types.TINYINT),
                        new SqlOutParameter("p_error_message", Types.VARCHAR));

        // sp_reserve_recalculate_from_assessments: composed lifecycle
        // procedure that itself calls sp_da_sum_by_claim.
        recalculateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_reserve_recalculate_from_assessments")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_recommended_amount", Types.DECIMAL));
    }

    @Override
    @SuppressWarnings("unchecked")
    public Reserve findByClaimId(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = findByClaimCall.execute(params);
        List<Reserve> rows = (List<Reserve>) out.get("#result-set-1");
        return (rows == null || rows.isEmpty()) ? null : rows.get(0);
    }

    @Override
    public Map<String, Object> setAmount(Long claimId, BigDecimal newAmount, String reason, String changedBy) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_new_amount", newAmount);
        params.put("p_reason", reason);
        params.put("p_changed_by", changedBy);
        Map<String, Object> out = setAmountCall.execute(params);

        Object rawFlag = out.get("p_success_flag");
        boolean successFlag;
        if (rawFlag instanceof Boolean) {
            successFlag = (Boolean) rawFlag;
        } else if (rawFlag instanceof Number) {
            successFlag = ((Number) rawFlag).intValue() != 0;
        } else {
            successFlag = false;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("successFlag", successFlag);
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }

    @Override
    public BigDecimal recalculateFromAssessments(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = recalculateCall.execute(params);
        BigDecimal recommended = (BigDecimal) out.get("p_recommended_amount");
        return recommended == null ? BigDecimal.ZERO : recommended;
    }
}
