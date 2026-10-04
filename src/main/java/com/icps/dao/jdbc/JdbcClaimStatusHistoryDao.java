package com.icps.dao.jdbc;

import java.util.List;
import java.util.Map;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

import com.icps.dao.ClaimStatusHistoryDao;
import com.icps.model.ClaimStatusHistory;
import com.icps.model.rowmapper.ClaimStatusHistoryRowMapper;

/**
 * {@code SimpleJdbcCall}-backed implementation of {@link ClaimStatusHistoryDao}.
 *
 * {@code sp_csh_create} has only an OUT parameter besides its INs, so it is
 * invoked via {@code SimpleJdbcCall}. {@code sp_csh_list_by_claim} returns a
 * result set and is invoked via {@link JdbcTemplate#query} with raw
 * {@code CALL} syntax and a {@link ClaimStatusHistoryRowMapper}. No
 * update/delete methods are provided, matching the append-only stored
 * procedure library (Requirement 14.3).
 */
@Repository
public class JdbcClaimStatusHistoryDao implements ClaimStatusHistoryDao {

    @Autowired
    private DataSource dataSource;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private SimpleJdbcCall createCall;

    @PostConstruct
    private void init() {
        createCall = new SimpleJdbcCall(dataSource).withProcedureName("sp_csh_create");
    }

    @Override
    public Long create(Long claimId, String priorStatus, String newStatus, String changedBy, String note) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("p_claim_id", claimId)
                .addValue("p_prior_status", priorStatus)
                .addValue("p_new_status", newStatus)
                .addValue("p_changed_by", changedBy)
                .addValue("p_note", note);
        Map<String, Object> out = createCall.execute(params);
        Number historyId = (Number) out.get("p_history_id");
        return historyId == null ? null : historyId.longValue();
    }

    @Override
    public List<ClaimStatusHistory> findByClaim(Long claimId) {
        return jdbcTemplate.query(
                "CALL sp_csh_list_by_claim(?)",
                new Object[] { claimId },
                new ClaimStatusHistoryRowMapper());
    }
}
