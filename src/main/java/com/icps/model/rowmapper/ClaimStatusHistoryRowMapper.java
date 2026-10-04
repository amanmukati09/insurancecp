package com.icps.model.rowmapper;

import com.icps.model.ClaimStatusHistory;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code claim_status_history} result set to a
 * {@link ClaimStatusHistory}.
 */
public class ClaimStatusHistoryRowMapper implements RowMapper<ClaimStatusHistory> {

    @Override
    public ClaimStatusHistory mapRow(ResultSet rs, int rowNum) throws SQLException {
        ClaimStatusHistory history = new ClaimStatusHistory();
        history.setHistoryId(rs.getLong("history_id"));
        history.setClaimId(rs.getLong("claim_id"));

        String priorStatus = rs.getString("prior_status");
        history.setPriorStatus(rs.wasNull() ? null : priorStatus);

        history.setNewStatus(rs.getString("new_status"));
        history.setChangedBy(rs.getString("changed_by"));

        Timestamp changedAt = rs.getTimestamp("changed_at");
        history.setChangedAt(changedAt == null ? null : new java.util.Date(changedAt.getTime()));

        String note = rs.getString("note");
        history.setNote(rs.wasNull() ? null : note);

        return history;
    }
}
