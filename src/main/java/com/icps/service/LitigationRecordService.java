package com.icps.service;
import java.util.Date;
import java.util.List;
import com.icps.model.LitigationRecord;
/**
 * Service for creating and retrieving {@link LitigationRecord} entries.
 *
 * <p>Enforces the Requirement 10.2/10.3 field validation rules (case
 * reference present and no longer than 100 characters, filing date present)
 * in Java before delegating persistence to the {@code SimpleJdbcCall}-backed
 * {@link com.icps.dao.LitigationRecordDao}.</p>
 */
public interface LitigationRecordService {

    /**
     * Validates and creates a Litigation_Record for a Claim.
     *
     * @return the generated {@code litigation_record_id}
     * @throws com.icps.exception.ValidationException if any field fails validation
     */
    Long create(Long claimId, String caseReference, Date filingDate, String status, String attorneyName);

    /** Lists all Litigation_Record entries for a Claim. */
    List<LitigationRecord> findByClaim(Long claimId);

    /**
     * Fetches a single Litigation_Record by id.
     *
     * @throws com.icps.exception.NotFoundException if no matching row exists
     */
    LitigationRecord findById(Long id);
}
