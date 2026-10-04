package com.icps.service.impl;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.PostConstruct;
import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.icps.dao.ClaimantDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.Claimant;
import com.icps.service.ClaimantService;

/**
 * Default implementation of {@link ClaimantService}.
 *
 * Applies the {@code javax.validation} constraints declared on
 * {@link Claimant} (Requirement 2.3), translates not-found conditions into
 * {@link NotFoundException} (Requirement 2.4), and delegates the referenced-
 * Claimant delete guard (Requirement 2.5) to {@link ClaimantDao#delete},
 * which already enforces it via {@code sp_claimant_has_claims} and throws
 * {@link com.icps.exception.ClaimantReferencedException}.
 */
@Service
public class ClaimantServiceImpl implements ClaimantService {

    @Autowired
    private ClaimantDao claimantDao;

    private Validator validator;

    @PostConstruct
    public void init() {
        this.validator = Validation.buildDefaultValidatorFactory().getValidator();
    }

    @Override
    public Claimant create(Claimant claimant) {
        // createdAt is a server-assigned audit timestamp, not a caller-supplied
        // field; default it here before validation rather than requiring the
        // REST client to populate it (Requirement 2.2).
        if (claimant.getCreatedAt() == null) {
            claimant.setCreatedAt(new Date());
        }
        validate(claimant);
        return claimantDao.save(claimant);
    }

    @Override
    public Claimant update(Long id, Claimant claimant) {
        Claimant existing = claimantDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Claimant not found: id=" + id);
        }
        // createdAt is a server-assigned audit timestamp; preserve the
        // original value rather than requiring the REST client to resend it
        // on every update (Requirement 2.2).
        if (claimant.getCreatedAt() == null) {
            claimant.setCreatedAt(existing.getCreatedAt());
        }
        validate(claimant);
        claimant.setClaimantId(id);
        return claimantDao.save(claimant);
    }

    @Override
    public Claimant findById(Long id) {
        Claimant claimant = claimantDao.findById(id);
        if (claimant == null) {
            throw new NotFoundException("Claimant not found: id=" + id);
        }
        return claimant;
    }

    @Override
    public List<Claimant> findAll() {
        return claimantDao.findAll();
    }

    @Override
    public void delete(Long id) {
        if (claimantDao.findById(id) == null) {
            throw new NotFoundException("Claimant not found: id=" + id);
        }
        // ClaimantDao.delete enforces the Requirement 2.5 referenced-Claimant
        // guard internally and throws ClaimantReferencedException; let it
        // propagate unchanged.
        claimantDao.delete(id);
    }

    private void validate(Claimant claimant) {
        Set<ConstraintViolation<Claimant>> violations = validator.validate(claimant);
        if (!violations.isEmpty()) {
            Map<String, String> fieldErrors = new LinkedHashMap<>();
            for (ConstraintViolation<Claimant> violation : violations) {
                fieldErrors.put(violation.getPropertyPath().toString(), violation.getMessage());
            }
            throw new ValidationException(fieldErrors);
        }
    }
}
