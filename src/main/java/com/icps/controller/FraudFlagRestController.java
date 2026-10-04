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
import com.icps.dao.FraudFlagDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.FraudFlag;
import com.icps.service.FraudScoringService;

/**
 * REST JSON controller exposing CRUD operations for {@link FraudFlag}
 * records associated with a Claim, plus the cross-claim fraud summary
 * report (Requirement 8).
 *
 * <p>Create/update/delete operations trigger a fraud score recomputation
 * via {@link FraudScoringService} (Requirement 8.3), and reads/writes on a
 * non-existent Fraud_Flag or Claim surface as HTTP 404/400 per Requirement
 * 8.2.</p>
 *
 * @see Requirements 8.1, 8.2, 8.6, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/fraud-flags")
public class FraudFlagRestController {

    @Resource
    private FraudScoringService fraudScoringService;

    @Resource
    private FraudFlagDao fraudFlagDao;

    /**
     * Lists all Fraud_Flag rows (active and inactive) for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Fraud_Flag records, or an empty list if none exist
     */
    @GetMapping
    public List<FraudFlag> listFraudFlags(@PathVariable Long claimId) {
        return fraudFlagDao.findByClaim(claimId);
    }

    /**
     * Reads a single Fraud_Flag by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Fraud_Flag identifier
     * @return the Fraud_Flag
     * @throws NotFoundException if no Fraud_Flag exists with the given id
     *                           (Requirement 8.2)
     */
    @GetMapping("/{id}")
    public FraudFlag getFraudFlag(@PathVariable Long claimId, @PathVariable Long id) {
        FraudFlag flag = fraudFlagDao.findById(id);
        if (flag == null) {
            throw new NotFoundException("Fraud_Flag not found: " + id);
        }
        return flag;
    }

    /**
     * Creates a new Fraud_Flag for a Claim and recomputes the Claim's fraud
     * score as a follow-up operation (Requirement 8.1, 8.3).
     *
     * @param claimId the Claim identifier
     * @param request the request payload (flagReason, scoreWeight)
     * @return HTTP 201 with the created Fraud_Flag
     * @throws ValidationException if a required field is missing
     *                             (Requirement 8.2)
     */
    @PostMapping
    public ResponseEntity<FraudFlag> createFraudFlag(@PathVariable Long claimId,
            @RequestBody FraudFlagRequest request) {
        Map<String, String> fieldErrors = new HashMap<>();
        if (request == null || request.getFlagReason() == null || request.getFlagReason().trim().isEmpty()) {
            fieldErrors.put("flagReason", "flagReason is required");
        }
        if (request == null || request.getScoreWeight() == null) {
            fieldErrors.put("scoreWeight", "scoreWeight is required");
        }
        if (!fieldErrors.isEmpty()) {
            throw new ValidationException("Fraud_Flag create request is invalid", fieldErrors);
        }
        Long newId = fraudScoringService.createFlag(claimId, request.getFlagReason(), request.getScoreWeight());
        FraudFlag created = fraudFlagDao.findById(newId);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * Updates the mutable fields of a Fraud_Flag and recomputes the Claim's
     * fraud score (Requirement 8.3).
     *
     * @param claimId the Claim identifier
     * @param id      the Fraud_Flag identifier
     * @param request the request payload (flagReason, scoreWeight, isActive)
     * @return the updated Fraud_Flag
     * @throws NotFoundException if no Fraud_Flag exists with the given id
     *                           (Requirement 8.2)
     */
    @PutMapping("/{id}")
    public FraudFlag updateFraudFlag(@PathVariable Long claimId, @PathVariable Long id,
            @RequestBody FraudFlagRequest request) {
        FraudFlag existing = fraudFlagDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Fraud_Flag not found: " + id);
        }
        fraudFlagDao.update(id, request.getFlagReason(), request.getScoreWeight(), request.getIsActive());
        fraudScoringService.recomputeScore(claimId);
        return fraudFlagDao.findById(id);
    }

    /**
     * Deletes a Fraud_Flag and recomputes the Claim's fraud score
     * (Requirement 8.3).
     *
     * @param claimId the Claim identifier
     * @param id      the Fraud_Flag identifier
     * @return HTTP 204 on success
     * @throws NotFoundException if no Fraud_Flag exists with the given id
     *                           (Requirement 8.2)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFraudFlag(@PathVariable Long claimId, @PathVariable Long id) {
        FraudFlag existing = fraudFlagDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Fraud_Flag not found: " + id);
        }
        fraudFlagDao.delete(id);
        fraudScoringService.recomputeScore(claimId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Request payload for {@link #createFraudFlag} and
     * {@link #updateFraudFlag}.
     */
    public static class FraudFlagRequest {
        private String flagReason;
        private Integer scoreWeight;
        private Boolean isActive;

        public String getFlagReason() {
            return flagReason;
        }

        public void setFlagReason(String flagReason) {
            this.flagReason = flagReason;
        }

        public Integer getScoreWeight() {
            return scoreWeight;
        }

        public void setScoreWeight(Integer scoreWeight) {
            this.scoreWeight = scoreWeight;
        }

        public Boolean getIsActive() {
            return isActive;
        }

        public void setIsActive(Boolean isActive) {
            this.isActive = isActive;
        }
    }
}
