package com.icps.model.rowmapper;

import com.icps.model.LitigationRecord;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 * Maps a single row of a {@code litigation_record} result set to a
 * {@link LitigationRecord}.
 */
public class LitigationRecordRowMapper implements RowMapper<LitigationRecord> {

    @Override
    public LitigationRecord mapRow(ResultSet rs, int rowNum) throws SQLException {
        LitigationRecord record = new LitigationRecord();
        record.setLitigationRecordId(rs.getLong("litigation_record_id"));
        record.setClaimId(rs.getLong("claim_id"));
        record.setCaseReference(rs.getString("case_reference"));

        Timestamp filingDate = rs.getTimestamp("filing_date");
        record.setFilingDate(filingDate == null ? null : new java.util.Date(filingDate.getTime()));

        String status = rs.getString("status");
        record.setStatus(rs.wasNull() ? null : status);

        String attorneyName = rs.getString("attorney_name");
        record.setAttorneyName(rs.wasNull() ? null : attorneyName);

        Timestamp createdAt = rs.getTimestamp("created_at");
        record.setCreatedAt(createdAt == null ? null : new java.util.Date(createdAt.getTime()));

        return record;
    }
}
