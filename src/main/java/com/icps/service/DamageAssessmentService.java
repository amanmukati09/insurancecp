package com.icps.service;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import com.icps.model.DamageAssessment;
/**
 * Service for creating and retrieving {@link DamageAssessment} records.
 *
 * <p>Enforces the Requirement 4.1/4.3/4.4 field validation rules (positive
 * estimated cost not exceeding 999,999,999.99, non-blank description, and an
 * assessment date present and not later than today) in Java before
 * delegating persistence to the {@code SimpleJdbcCall}-backed
 * {@link com.icps.dao.DamageAssessmentDao}.</p>
 */
public interface DamageAssessmentService {

    /**
     * Validates and creates a Damage_Assessment for a Claim.
     *
     * @return the generated {@code damage_assessment_id}
     * @throws com.icps.exception.ValidationException if any field fails validation
     */
    Long create(Long claimId, BigDecimal estimatedCost, String description, Date assessmentDate);

    /** Lists all Damage_Assessment rows for a Claim, most recent first. */
    List<DamageAssessment> findByClaim(Long claimId);

    /**
     * Fetches a single Damage_Assessment by id.
     *
     * @throws com.icps.exception.NotFoundException if no matching row exists
     */
    DamageAssessment findById(Long id);
}
