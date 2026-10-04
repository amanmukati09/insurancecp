package com.icps.model.rowmapper;

import com.icps.model.Reserve;
import org.springframework.jdbc.core.RowMapper;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code reserve} result set to a {@link Reserve}.
 */
public class ReserveRowMapper implements RowMapper<Reserve> {

    @Override
    public Reserve mapRow(ResultSet rs, int rowNum) throws SQLException {
        Reserve reserve = new Reserve();
        reserve.setReserveId(rs.getLong("reserve_id"));
        reserve.setClaimId(rs.getLong("claim_id"));
        reserve.setCurrentAmount(rs.getBigDecimal("current_amount"));

        BigDecimal recommendedAmount = rs.getBigDecimal("recommended_amount");
        reserve.setRecommendedAmount(rs.wasNull() ? null : recommendedAmount);

        Timestamp updatedAt = rs.getTimestamp("updated_at");
        reserve.setUpdatedAt(updatedAt == null ? null : new java.util.Date(updatedAt.getTime()));

        return reserve;
    }
}
