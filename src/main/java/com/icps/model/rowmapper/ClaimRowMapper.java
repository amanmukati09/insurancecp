package com.icps.model.rowmapper;

import com.icps.model.Claim;
import org.springframework.jdbc.core.RowMapper;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code claim} result set (as returned by the
 * Claim stored procedures invoked via SimpleJdbcCall) to a {@link Claim}.
 */
public class ClaimRowMapper implements RowMapper<Claim> {

    @Override
    public Claim mapRow(ResultSet rs, int rowNum) throws SQLException {
        Claim claim = new Claim();
        claim.setClaimId(rs.getLong("claim_id"));
        claim.setClaimantId(rs.getLong("claimant_id"));
        claim.setPolicyReferenceId(rs.getLong("policy_reference_id"));

        long adjusterId = rs.getLong("adjuster_id");
        claim.setAdjusterId(rs.wasNull() ? null : adjusterId);

        Timestamp lossDate = rs.getTimestamp("loss_date");
        claim.setLossDate(lossDate == null ? null : new java.util.Date(lossDate.getTime()));

        claim.setLossDescription(rs.getString("loss_description"));
        claim.setStatus(rs.getString("status"));

        boolean underFraudReview = rs.getBoolean("under_fraud_review");
        claim.setUnderFraudReview(rs.wasNull() ? null : underFraudReview);

        BigDecimal netPaidAmount = rs.getBigDecimal("net_paid_amount");
        claim.setNetPaidAmount(rs.wasNull() ? null : netPaidAmount);

        int version = rs.getInt("version");
        claim.setVersion(rs.wasNull() ? null : version);

        Timestamp createdAt = rs.getTimestamp("created_at");
        claim.setCreatedAt(createdAt == null ? null : new java.util.Date(createdAt.getTime()));

        Timestamp updatedAt = rs.getTimestamp("updated_at");
        claim.setUpdatedAt(updatedAt == null ? null : new java.util.Date(updatedAt.getTime()));

        return claim;
    }
}
