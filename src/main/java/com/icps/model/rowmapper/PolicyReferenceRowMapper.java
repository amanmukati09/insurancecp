package com.icps.model.rowmapper;

import com.icps.model.PolicyReference;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code policy_reference} result set to a
 * {@link PolicyReference}.
 */
public class PolicyReferenceRowMapper implements RowMapper<PolicyReference> {

    @Override
    public PolicyReference mapRow(ResultSet rs, int rowNum) throws SQLException {
        PolicyReference policyReference = new PolicyReference();
        policyReference.setPolicyReferenceId(rs.getLong("policy_reference_id"));
        policyReference.setPolicyNumber(rs.getString("policy_number"));
        policyReference.setPolicyType(rs.getString("policy_type"));
        policyReference.setCoverageLimit(rs.getBigDecimal("coverage_limit"));
        policyReference.setDeductible(rs.getBigDecimal("deductible"));

        Timestamp effectiveStartDate = rs.getTimestamp("effective_start_date");
        policyReference.setEffectiveStartDate(effectiveStartDate == null ? null : new java.util.Date(effectiveStartDate.getTime()));

        Timestamp effectiveEndDate = rs.getTimestamp("effective_end_date");
        policyReference.setEffectiveEndDate(effectiveEndDate == null ? null : new java.util.Date(effectiveEndDate.getTime()));

        return policyReference;
    }
}
