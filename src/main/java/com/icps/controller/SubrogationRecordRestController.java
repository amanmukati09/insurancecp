package com.icps.controller;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.dao.SubrogationRecordDao;
import com.icps.model.SubrogationRecord;
import com.icps.service.SubrogationRecordService;
/**
 * REST JSON controller exposing CRUD operations for {@link SubrogationRecord}
 * entries associated with a Claim (Requirement 11).
 *
 * <p>Creation is delegated to {@link SubrogationRecordService#create}, which
 * performs a lightweight Java-side sanity check and then invokes the
 * transactional {@code sp_subrogation_record_create} stored procedure via
 * {@link SubrogationRecordDao#create}. That procedure enforces the Claim
 * status eligibility rule (Requirement 11.2, 11.3: Claim status must be
 * "Settled" or "Closed") and the recovery-amount range rule (Requirement
 * 11.4, 11.5: between 0.01 and the Claim's current net paid amount,
 * inclusive), reporting failures via the returned map's
 * {@code errorMessage} entry rather than a Java exception. This controller
 * inspects that message to choose between HTTP 409 (Claim status
 * ineligible) and HTTP 400 (invalid recovery amount) for the error
 * response.</p>
 *
 * <p>Update and delete are not covered by the service's narrow create/read
 * interface, so they are delegated directly to the
 * {@code SimpleJdbcCall}-backed {@link SubrogationRecordDao}, consistent
 * with the direct-DAO pattern used by {@code LitigationRecordRestController}
 * (Requirement 15.3, 15.4).</p>
 *
 * @see Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 11.7, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/subrogation-records")
public class SubrogationRecordRestController {
    @Resource
    private SubrogationRecordService subrogationRecordService;
    @Resource
    private SubrogationRecordDao subrogationRecordDao;
    /**
     * Lists the Subrogation_Record entries associated with a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Subrogation_Record entries, or an empty list if
     *         none exist
     */
    @GetMapping
    public List<SubrogationRecord> listSubrogationRecords(@PathVariable Long claimId) {
        return subrogationRecordService.findByClaim(claimId);
    }
    /**
     * Reads a single Subrogation_Record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Subrogation_Record identifier
     * @return the Subrogation_Record
     * @throws com.icps.exception.NotFoundException if no Subrogation_Record
     *         exists with the given id
     */
    @GetMapping("/{id}")
    public SubrogationRecord getSubrogationRecord(@PathVariable Long claimId, @PathVariable Long id) {
        return subrogationRecordService.findById(id);
    }
    /**
     * Creates a new Subrogation_Record for a Claim.
     *
     * <p>Only succeeds if the Claim's status is "Settled" or "Closed"
     * (Requirement 11.2, 11.3) and the recovery amount is between 0.01 and
     * the Claim's current net paid amount, inclusive (Requirement 11.4,
     * 11.5). Both rules are enforced by the stored procedure invoked
     * through {@link SubrogationRecordService#create}; failures are
     * reported via the returned map's {@code errorMessage} rather than an
     * exception, so this method translates that into the appropriate HTTP
     * status.</p>
     *
     * @param claimId           the Claim identifier taken from the path
     * @param subrogationRecord the request payload (thirdPartyIdentifier,
     *                          recoveryAmount, recordedDate)
     * @return HTTP 201 with the created Subrogation_Record on success;
     *         HTTP 409 if the Claim status is not eligible for subrogation
     *         recording; HTTP 400 if the recovery amount is out of range
     */
    @PostMapping
    public ResponseEntity<?> createSubrogationRecord(@PathVariable Long claimId,
            @RequestBody SubrogationRecord subrogationRecord) {
        Map<String, Object> result = subrogationRecordService.create(claimId,
                subrogationRecord.getThirdPartyIdentifier(), subrogationRecord.getRecoveryAmount(),
                subrogationRecord.getRecordedDate());
        String errorMessage = (String) result.get("errorMessage");
        if (errorMessage != null) {
            HttpStatus status = errorMessage.toLowerCase().contains("status") ? HttpStatus.CONFLICT
                    : HttpStatus.BAD_REQUEST;
            Map<String, Object> body = new HashMap<>();
            body.put("error", errorMessage);
            return new ResponseEntity<>(body, status);
        }
        Long newId = (Long) result.get("newId");
        SubrogationRecord created = subrogationRecordService.findById(newId);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    /**
     * Updates an existing Subrogation_Record.
     *
     * @param claimId           the Claim identifier (path consistency only)
     * @param id                the Subrogation_Record identifier
     * @param subrogationRecord the request payload with the new field
     *                          values (thirdPartyIdentifier, recoveryAmount,
     *                          recordedDate)
     * @return the updated Subrogation_Record
     * @throws com.icps.exception.NotFoundException if no Subrogation_Record
     *         exists with the given id
     */
    @PutMapping("/{id}")
    public SubrogationRecord updateSubrogationRecord(@PathVariable Long claimId, @PathVariable Long id,
            @RequestBody SubrogationRecord subrogationRecord) {
        subrogationRecordService.findById(id);
        subrogationRecordDao.update(id, subrogationRecord.getThirdPartyIdentifier(),
                subrogationRecord.getRecoveryAmount(), subrogationRecord.getRecordedDate());
        return subrogationRecordService.findById(id);
    }
    /**
     * Deletes a Subrogation_Record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Subrogation_Record identifier
     * @return HTTP 204 on success
     * @throws com.icps.exception.NotFoundException if no Subrogation_Record
     *         exists with the given id
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSubrogationRecord(@PathVariable Long claimId, @PathVariable Long id) {
        subrogationRecordService.findById(id);
        subrogationRecordDao.delete(id);
        return ResponseEntity.noContent().build();
    }
}
