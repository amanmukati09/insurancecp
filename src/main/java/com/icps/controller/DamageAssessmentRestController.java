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
import com.icps.dao.DamageAssessmentDao;
import com.icps.exception.NotFoundException;
import com.icps.model.DamageAssessment;
import com.icps.service.DamageAssessmentService;

/**
 * REST JSON controller exposing CRUD operations for {@link DamageAssessment}
 * records (Requirement 4).
 *
 * <p>Create/list/read go through the validating {@link DamageAssessmentService}
 * (Requirements 4.1, 4.3, 4.4 field validation, surfaced as 400 responses via
 * {@code ValidationException}/{@link com.icps.exception.GlobalErrorHandler}).
 * Update/delete are mutable-field/administrative operations not exposed by
 * the service interface, so this controller talks directly to the
 * {@code SimpleJdbcCall}-backed {@link DamageAssessmentDao} for those two
 * operations, consistent with the direct-DAO pattern used by
 * {@code PolicyReferenceRestController} (Requirement 15.3, 15.4).</p>
 *
 * @see Requirements 4.1, 4.2, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/damage-assessments")
public class DamageAssessmentRestController {

    @Resource
    private DamageAssessmentService damageAssessmentService;

    @Resource
    private DamageAssessmentDao damageAssessmentDao;

    /**
     * Lists all Damage_Assessment records for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Damage_Assessment records
     */
    @GetMapping
    public List<DamageAssessment> findByClaim(@PathVariable Long claimId) {
        return damageAssessmentService.findByClaim(claimId);
    }

    /**
     * Reads a single Damage_Assessment by identifier.
     *
     * @param claimId the Claim identifier (path context, not independently validated here)
     * @param id      the Damage_Assessment identifier
     * @return the matching Damage_Assessment
     * @throws NotFoundException if no Damage_Assessment exists for the id
     */
    @GetMapping("/{id}")
    public DamageAssessment findById(@PathVariable Long claimId, @PathVariable Long id) {
        return damageAssessmentService.findById(id);
    }

    /**
     * Creates a new Damage_Assessment for a Claim.
     *
     * <p>Field validation (positive estimated cost not exceeding
     * 999,999,999.99, non-blank description, assessment date present and not
     * later than today — Requirements 4.3, 4.4) is enforced by
     * {@link DamageAssessmentService#create} and surfaced as a 400 response
     * via {@code ValidationException} on failure.</p>
     *
     * @param claimId          the Claim identifier
     * @param damageAssessment the Damage_Assessment payload (estimatedCost,
     *                         description, assessmentDate)
     * @return 201 Created with the persisted Damage_Assessment
     */
    @PostMapping
    public ResponseEntity<DamageAssessment> create(@PathVariable Long claimId,
            @RequestBody DamageAssessment damageAssessment) {
        Long newId = damageAssessmentService.create(
                claimId,
                damageAssessment.getEstimatedCost(),
                damageAssessment.getDescription(),
                damageAssessment.getAssessmentDate());
        DamageAssessment created = damageAssessmentService.findById(newId);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    /**
     * Updates the mutable fields of an existing Damage_Assessment.
     *
     * @param claimId          the Claim identifier (path context)
     * @param id               the Damage_Assessment identifier to update
     * @param damageAssessment the new field values
     * @return the persisted Damage_Assessment
     * @throws NotFoundException if no Damage_Assessment exists for the id
     */
    @PutMapping("/{id}")
    public DamageAssessment update(@PathVariable Long claimId, @PathVariable Long id,
            @RequestBody DamageAssessment damageAssessment) {
        DamageAssessment existing = damageAssessmentDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Damage_Assessment not found: " + id);
        }
        damageAssessmentDao.update(
                id,
                damageAssessment.getEstimatedCost(),
                damageAssessment.getDescription(),
                damageAssessment.getAssessmentDate());
        return damageAssessmentDao.findById(id);
    }

    /**
     * Deletes a Damage_Assessment by identifier.
     *
     * @param claimId the Claim identifier (path context)
     * @param id      the Damage_Assessment identifier to delete
     * @return 204 No Content on success
     * @throws NotFoundException if no Damage_Assessment exists for the id
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long claimId, @PathVariable Long id) {
        DamageAssessment existing = damageAssessmentDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Damage_Assessment not found: " + id);
        }
        damageAssessmentDao.delete(id);
        return ResponseEntity.noContent().build();
    }
}
