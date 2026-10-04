package com.icps.model.rowmapper;

import com.icps.model.SubrogationRecord;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code subrogation_record} result set to a
 * {@link SubrogationRecord}.
 */
public class SubrogationRecordRowMapper implements RowMapper<SubrogationRecord> {

    @Override
    public SubrogationRecord mapRow(ResultSet rs, int rowNum) throws SQLException {
        SubrogationRecord record = new SubrogationRecord();
        record.setSubrogationRecordId(rs.getLong("subrogation_record_id"));
        record.setClaimId(rs.getLong("claim_id"));
        record.setThirdPartyIdentifier(rs.getString("third_party_identifier"));
        record.setRecoveryAmount(rs.getBigDecimal("recovery_amount"));

        Timestamp recordedDate = rs.getTimestamp("recorded_date");
        record.setRecordedDate(recordedDate == null ? null : new java.util.Date(recordedDate.getTime()));

        Timestamp createdAt = rs.getTimestamp("created_at");
        record.setCreatedAt(createdAt == null ? null : new java.util.Date(createdAt.getTime()));

        return record;
    }
}
