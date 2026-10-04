package com.icps.service;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Map;
import com.icps.model.SubrogationRecord;
/**
 * Service for creating and retrieving {@link SubrogationRecord} entries.
 *
 * <p>Performs a lightweight Java-side sanity check (third-party identifier
 * present, recovery amount present and non-negative) before delegating to
 * {@link com.icps.dao.SubrogationRecordDao#create}, which invokes the
 * transactional {@code sp_subrogation_record_create} procedure. That
 * procedure performs the deeper business validation required by Requirements
 * 11.2-11.5 (Claim status must be "Settled" or "Closed"; recovery amount
 * must be between 0.01 and the Claim's current net paid amount, inclusive)
 * and reports failures via the returned map's {@code errorMessage} entry
 * rather than a Java exception.</p>
 */
public interface SubrogationRecordService {

    /**
     * Validates (lightly) and creates a Subrogation_Record for a Claim.
     *
     * @return a map with keys {@code newId} (Long, null on failure) and
     *         {@code errorMessage} (String, null on success)
     * @throws com.icps.exception.ValidationException if the basic sanity check fails
     */
    Map<String, Object> create(Long claimId, String thirdPartyIdentifier, BigDecimal recoveryAmount,
            Date recordedDate);

    /** Lists all Subrogation_Record entries for a Claim. */
    List<SubrogationRecord> findByClaim(Long claimId);

    /**
     * Fetches a single Subrogation_Record by id.
     *
     * @throws com.icps.exception.NotFoundException if no matching row exists
     */
    SubrogationRecord findById(Long id);
}
