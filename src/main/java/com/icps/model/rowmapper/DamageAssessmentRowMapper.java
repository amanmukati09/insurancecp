package com.icps.model.rowmapper;

import com.icps.model.DamageAssessment;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code damage_assessment} result set to a
 * {@link DamageAssessment}.
 */
public class DamageAssessmentRowMapper implements RowMapper<DamageAssessment> {

    @Override
    public DamageAssessment mapRow(ResultSet rs, int rowNum) throws SQLException {
        DamageAssessment assessment = new DamageAssessment();
        assessment.setDamageAssessmentId(rs.getLong("damage_assessment_id"));
        assessment.setClaimId(rs.getLong("claim_id"));
        assessment.setEstimatedCost(rs.getBigDecimal("estimated_cost"));
        assessment.setDescription(rs.getString("description"));

        Timestamp assessmentDate = rs.getTimestamp("assessment_date");
        assessment.setAssessmentDate(assessmentDate == null ? null : new java.util.Date(assessmentDate.getTime()));

        Timestamp createdAt = rs.getTimestamp("created_at");
        assessment.setCreatedAt(createdAt == null ? null : new java.util.Date(createdAt.getTime()));

        return assessment;
    }
}
