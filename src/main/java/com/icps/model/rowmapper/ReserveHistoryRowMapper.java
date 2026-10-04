package com.icps.model.rowmapper;

import com.icps.model.ReserveHistory;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code reserve_history} result set to a
 * {@link ReserveHistory}.
 */
public class ReserveHistoryRowMapper implements RowMapper<ReserveHistory> {

    @Override
    public ReserveHistory mapRow(ResultSet rs, int rowNum) throws SQLException {
        ReserveHistory history = new ReserveHistory();
        history.setReserveHistoryId(rs.getLong("reserve_history_id"));
        history.setReserveId(rs.getLong("reserve_id"));
        history.setPriorAmount(rs.getBigDecimal("prior_amount"));
        history.setNewAmount(rs.getBigDecimal("new_amount"));
        history.setReason(rs.getString("reason"));
        history.setChangedBy(rs.getString("changed_by"));

        Timestamp changedAt = rs.getTimestamp("changed_at");
        history.setChangedAt(changedAt == null ? null : new java.util.Date(changedAt.getTime()));

        return history;
    }
}
