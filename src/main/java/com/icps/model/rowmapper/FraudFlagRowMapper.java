package com.icps.model.rowmapper;

import com.icps.model.FraudFlag;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code fraud_flag} result set to a
 * {@link FraudFlag}.
 */
public class FraudFlagRowMapper implements RowMapper<FraudFlag> {

    @Override
    public FraudFlag mapRow(ResultSet rs, int rowNum) throws SQLException {
        FraudFlag flag = new FraudFlag();
        flag.setFraudFlagId(rs.getLong("fraud_flag_id"));
        flag.setClaimId(rs.getLong("claim_id"));
        flag.setFlagReason(rs.getString("flag_reason"));

        int scoreWeight = rs.getInt("score_weight");
        flag.setScoreWeight(rs.wasNull() ? null : scoreWeight);

        boolean isActive = rs.getBoolean("is_active");
        flag.setIsActive(rs.wasNull() ? null : isActive);

        Timestamp createdAt = rs.getTimestamp("created_at");
        flag.setCreatedAt(createdAt == null ? null : new java.util.Date(createdAt.getTime()));

        Timestamp updatedAt = rs.getTimestamp("updated_at");
        flag.setUpdatedAt(updatedAt == null ? null : new java.util.Date(updatedAt.getTime()));

        return flag;
    }
}
