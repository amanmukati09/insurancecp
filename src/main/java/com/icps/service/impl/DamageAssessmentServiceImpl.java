package com.icps.service.impl;
import java.math.BigDecimal;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.icps.dao.DamageAssessmentDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.DamageAssessment;
import com.icps.service.DamageAssessmentService;
/**
 * Default {@link DamageAssessmentService} implementation.
 *
 * <p>Enforces the Requirement 4.1/4.3/4.4 field validation rules in Java
 * before delegating to the {@code SimpleJdbcCall}-backed
 * {@link DamageAssessmentDao}.</p>
 */
@Service
public class DamageAssessmentServiceImpl implements DamageAssessmentService {

    private static final Logger LOGGER = LoggerFactory.getLogger(DamageAssessmentServiceImpl.class);
    private static final BigDecimal MAX_ESTIMATED_COST = new BigDecimal("999999999.99");

    private final DamageAssessmentDao damageAssessmentDao;

    @Autowired
    public DamageAssessmentServiceImpl(DamageAssessmentDao damageAssessmentDao) {
        this.damageAssessmentDao = damageAssessmentDao;
    }

    @Override
    public Long create(Long claimId, BigDecimal estimatedCost, String description, Date assessmentDate) {
        Map<String, String> fieldErrors = new LinkedHashMap<String, String>();

        if (estimatedCost == null || estimatedCost.compareTo(BigDecimal.ZERO) <= 0) {
            fieldErrors.put("estimatedCost", "Estimated cost must be greater than 0.00");
        } else if (estimatedCost.compareTo(MAX_ESTIMATED_COST) > 0) {
            fieldErrors.put("estimatedCost", "Estimated cost must not exceed 999,999,999.99");
        }

        if (description == null || description.trim().isEmpty()) {
            fieldErrors.put("description", "Description is required");
        }

        if (assessmentDate == null) {
            fieldErrors.put("assessmentDate", "Assessment date is required");
        } else if (assessmentDate.after(new Date())) {
            fieldErrors.put("assessmentDate", "Assessment date must not be later than the current date");
        }

        if (!fieldErrors.isEmpty()) {
            LOGGER.warn("Damage_Assessment validation failed for claimId={}, errors={}", claimId, fieldErrors);
            throw new ValidationException("Damage_Assessment validation failed", fieldErrors);
        }

        Long newId = damageAssessmentDao.create(claimId, estimatedCost, description, assessmentDate);
        LOGGER.info("Damage_Assessment created with id={} for claimId={}", newId, claimId);
        return newId;
    }

    @Override
    public List<DamageAssessment> findByClaim(Long claimId) {
        return damageAssessmentDao.findByClaim(claimId);
    }

    @Override
    public DamageAssessment findById(Long id) {
        DamageAssessment damageAssessment = damageAssessmentDao.findById(id);
        if (damageAssessment == null) {
            throw new NotFoundException("Damage_Assessment not found for id " + id);
        }
        return damageAssessment;
    }
}
