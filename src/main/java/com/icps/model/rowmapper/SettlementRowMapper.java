package com.icps.model.rowmapper;

import com.icps.model.Settlement;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code settlement} result set to a
 * {@link Settlement}.
 */
public class SettlementRowMapper implements RowMapper<Settlement> {

    @Override
    public Settlement mapRow(ResultSet rs, int rowNum) throws SQLException {
        Settlement settlement = new Settlement();
        settlement.setSettlementId(rs.getLong("settlement_id"));
        settlement.setClaimId(rs.getLong("claim_id"));
        settlement.setPayoutAmount(rs.getBigDecimal("payout_amount"));
        settlement.setApprovedBy(rs.getString("approved_by"));

        Timestamp approvedAt = rs.getTimestamp("approved_at");
        settlement.setApprovedAt(approvedAt == null ? null : new java.util.Date(approvedAt.getTime()));

        return settlement;
    }
}
