package com.icps.dao.jdbc;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

import com.icps.dao.ClaimDao;
import com.icps.model.Claim;
import com.icps.model.rowmapper.ClaimRowMapper;

/**
 * {@code SimpleJdbcCall}-backed implementation of {@link ClaimDao}.
 *
 * Result-set-returning CRUD procedures ({@code sp_claim_read},
 * {@code sp_claim_list}, {@code sp_claim_find_by_claimant},
 * {@code sp_claim_find_by_adjuster}, {@code sp_claim_find_by_status}) are
 * invoked via {@link JdbcTemplate#query} with raw {@code CALL} syntax and a
 * {@link ClaimRowMapper}. OUT-param-only procedures ({@code sp_claim_create},
 * {@code sp_claim_get_version}, {@code sp_claim_get_current_status}, and the
 * lifecycle procedures {@code sp_claim_create_with_fnol},
 * {@code sp_claim_transition_status}, {@code sp_claim_assign_adjuster}) are
 * invoked via {@code SimpleJdbcCall}. No inline business SQL is used
 * (Requirement 15.4) -- every method delegates to a stored procedure from
 * tasks 4.2/5.1.
 */
@Repository
public class JdbcClaimDao implements ClaimDao {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private SimpleJdbcCall createClaimCall;
    private SimpleJdbcCall getVersionCall;
    private SimpleJdbcCall getCurrentStatusCall;
    private SimpleJdbcCall createWithFnolCall;
    private SimpleJdbcCall transitionStatusCall;
    private SimpleJdbcCall assignAdjusterCall;

    @PostConstruct
    private void init() {
        createClaimCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_create");
        getVersionCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_get_version");
        getCurrentStatusCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_get_current_status");
        createWithFnolCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_create_with_fnol");
        transitionStatusCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_transition_status");
        assignAdjusterCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_claim_assign_adjuster");
    }

    @Override
    public Long createClaim(Long claimantId, Long policyReferenceId, Date lossDate, String lossDescription) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_claimant_id", claimantId)
                .addValue("p_policy_reference_id", policyReferenceId)
                .addValue("p_adjuster_id", null)
                .addValue("p_loss_date", lossDate)
                .addValue("p_loss_description", lossDescription)
                .addValue("p_status", "Open");
        Map<String, Object> out = createClaimCall.execute(params);
        Number claimId = (Number) out.get("p_claim_id");
        return claimId == null ? null : claimId.longValue();
    }

    @Override
    public Claim findById(Long id) {
        List<Claim> results = jdbcTemplate.query(
                "CALL sp_claim_read(?)",
                new Object[] { id },
                new ClaimRowMapper());
        return results.isEmpty() ? null : results.get(0);
    }

    @Override
    public List<Claim> findAll() {
        return jdbcTemplate.query("CALL sp_claim_list()", new ClaimRowMapper());
    }

    @Override
    public List<Claim> findByClaimant(Long claimantId) {
        return jdbcTemplate.query(
                "CALL sp_claim_find_by_claimant(?)",
                new Object[] { claimantId },
                new ClaimRowMapper());
    }

    @Override
    public List<Claim> findByAdjuster(Long adjusterId) {
        return jdbcTemplate.query(
                "CALL sp_claim_find_by_adjuster(?)",
                new Object[] { adjusterId },
                new ClaimRowMapper());
    }

    @Override
    public List<Claim> findByStatus(String status) {
        return jdbcTemplate.query(
                "CALL sp_claim_find_by_status(?)",
                new Object[] { status },
                new ClaimRowMapper());
    }

    @Override
    public Integer getVersion(Long claimId) {
        MapSqlParameterSource params = new MapSqlParameterSource().addValue("p_claim_id", claimId);
        Map<String, Object> out = getVersionCall.execute(params);
        Number version = (Number) out.get("p_version");
        return version == null ? null : version.intValue();
    }

    @Override
    public String getCurrentStatus(Long claimId) {
        MapSqlParameterSource params = new MapSqlParameterSource().addValue("p_claim_id", claimId);
        Map<String, Object> out = getCurrentStatusCall.execute(params);
        return (String) out.get("p_status");
    }

    @Override
    public Map<String, Object> createClaimWithFnol(Long claimantId, Long policyReferenceId, Date lossDate, String lossDescription) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_claimant_id", claimantId)
                .addValue("p_policy_reference_id", policyReferenceId)
                .addValue("p_loss_date", lossDate)
                .addValue("p_loss_description", lossDescription);
        Map<String, Object> out = createWithFnolCall.execute(params);
        Number newClaimId = (Number) out.get("p_new_claim_id");
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("newClaimId", newClaimId == null ? null : newClaimId.longValue());
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }

    @Override
    public Map<String, Object> transitionStatus(Long claimId, String newStatus, String changedBy, Integer expectedVersion) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_claim_id", claimId)
                .addValue("p_new_status", newStatus)
                .addValue("p_changed_by", changedBy)
                .addValue("p_expected_version", expectedVersion);
        Map<String, Object> out = transitionStatusCall.execute(params);
        Number successFlag = (Number) out.get("p_success_flag");
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("successFlag", successFlag != null && successFlag.intValue() != 0);
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }

    @Override
    public Map<String, Object> assignAdjuster(Long claimId, Long newAdjusterId, String changedBy) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_claim_id", claimId)
                .addValue("p_new_adjuster_id", newAdjusterId)
                .addValue("p_changed_by", changedBy);
        Map<String, Object> out = assignAdjusterCall.execute(params);
        Number successFlag = (Number) out.get("p_success_flag");
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("successFlag", successFlag != null && successFlag.intValue() != 0);
        result.put("errorMessage", out.get("p_error_message"));
        return result;
    }
}
