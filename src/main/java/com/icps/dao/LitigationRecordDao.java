package com.icps.dao;

import java.util.Date;
import java.util.List;

import com.icps.model.LitigationRecord;

/**
 * DAO interface for {@link LitigationRecord} persistence.
 *
 * Litigation_Record is one of the ten JDBC/{@code SimpleJdbcCall}-backed
 * entities (Requirement 15.3, 15.4). The implementation
 * ({@code JdbcLitigationRecordDao}) invokes the {@code sp_lit_*} stored
 * procedures exclusively — no inline business SQL.
 */
public interface LitigationRecordDao {

    Long create(Long claimId, String caseReference, Date filingDate, String status, String attorneyName);

    LitigationRecord findById(Long id);

    List<LitigationRecord> findByClaim(Long claimId);

    void update(Long id, String caseReference, Date filingDate, String status, String attorneyName);

    void delete(Long id);
}
