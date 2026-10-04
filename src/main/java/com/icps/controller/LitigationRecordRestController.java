package com.icps.controller;

import java.util.List;

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

import com.icps.dao.LitigationRecordDao;
import com.icps.model.LitigationRecord;
import com.icps.service.LitigationRecordService;

/**
 * REST JSON controller exposing CRUD operations for {@link LitigationRecord}
 * entries associated with a Claim (Requirement 10).
 *
 * <p>Validation (Requirement 10.3: case reference required and no longer
 * than 100 characters, filing date required) is delegated to
 * {@link LitigationRecordService#create}. Not-found handling is performed
 * via {@link LitigationRecordService#findById}, which throws
 * {@link com.icps.exception.NotFoundException} when no matching row
 * exists. Update and delete operations are delegated to the
 * {@code SimpleJdbcCall}-backed {@link LitigationRecordDao} (Requirement
 * 15.3, 15.4).</p>
 *
 * @see Requirements 10.1, 10.2, 10.3, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/litigation-records")
public class LitigationRecordRestController {

    @Resource
    private LitigationRecordService litigationRecordService;

    @Resource
    private LitigationRecordDao litigationRecordDao;

    /**
     * Lists the Litigation_Record entries associated with a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Litigation_Record entries, or an empty list if
     *         none exist
     */
    @GetMapping
    public List<LitigationRecord> listLitigationRecords(@PathVariable Long claimId) {
        return litigationRecordService.findByClaim(claimId);
    }

    /**
     * Reads a single Litigation_Record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Litigation_Record identifier
     * @return the Litigation_Record
     * @throws com.icps.exception.NotFoundException if no Litigation_Record
     *         exists with the given id
     */
    @GetMapping("/{id}")
    public LitigationRecord getLitigationRecord(@PathVariable Long claimId, @PathVariable Long id) {
        return litigationRecordService.findById(id);
    }

    /**
     * Creates a new Litigation_Record for a Claim.
     *
     * @param claimId          the Claim identifier taken from the path
     * @param litigationRecord the request payload (caseReference, filingDate,
     *                         status, attorneyName)
     * @return HTTP 201 with the created Litigation_Record
     * @throws com.icps.exception.ValidationException if the case reference is
     *         missing or exceeds 100 characters, or the filing date is
     *         missing (Requirement 10.3)
     */
    @PostMapping
    public ResponseEntity<LitigationRecord> createLitigationRecord(@PathVariable Long claimId,
            @RequestBody LitigationRecord litigationRecord) {
        Long id = litigationRecordService.create(claimId, litigationRecord.getCaseReference(),
                litigationRecord.getFilingDate(), litigationRecord.getStatus(), litigationRecord.getAttorneyName());
        LitigationRecord created = litigationRecordService.findById(id);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Updates an existing Litigation_Record.
     *
     * @param claimId          the Claim identifier (path consistency only)
     * @param id               the Litigation_Record identifier
     * @param litigationRecord the request payload with the new field values
     * @return the updated Litigation_Record
     * @throws com.icps.exception.NotFoundException if no Litigation_Record
     *         exists with the given id
     */
    @PutMapping("/{id}")
    public LitigationRecord updateLitigationRecord(@PathVariable Long claimId, @PathVariable Long id,
            @RequestBody LitigationRecord litigationRecord) {
        litigationRecordService.findById(id);
        litigationRecordDao.update(id, litigationRecord.getCaseReference(), litigationRecord.getFilingDate(),
                litigationRecord.getStatus(), litigationRecord.getAttorneyName());
        return litigationRecordService.findById(id);
    }

    /**
     * Deletes a Litigation_Record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Litigation_Record identifier
     * @return HTTP 204 on success
     * @throws com.icps.exception.NotFoundException if no Litigation_Record
     *         exists with the given id
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteLitigationRecord(@PathVariable Long claimId, @PathVariable Long id) {
        litigationRecordService.findById(id);
        litigationRecordDao.delete(id);
        return ResponseEntity.noContent().build();
    }
}
