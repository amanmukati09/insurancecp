package com.icps.controller;

import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import com.icps.dao.AdjusterDao;
import com.icps.exception.NotFoundException;
import com.icps.model.Adjuster;
import com.icps.service.ClaimsLifecycleService;
import com.icps.util.ClaimFormatUtil;

/**
 * REST JSON controller exposing CRUD operations for {@link Adjuster} records
 * plus the Claim/Adjuster assignment endpoint.
 *
 * <p><strong>Design note:</strong> Adjuster is a simple Hibernate-backed
 * reference entity with no business validation beyond its Bean Validation
 * annotations (enforced by the {@code adjuster} table/entity constraints), so
 * this controller calls {@link AdjusterDao} directly rather than introducing
 * a pass-through {@code AdjusterService} layer purely for CRUD. This mirrors
 * the "straightforward CRUD" guidance for this entity; the adjuster
 * assignment endpoint below still delegates all business rules (inactive
 * Adjuster rejection, assignment history) to {@link ClaimsLifecycleService}.</p>
 *
 * @see Requirements 3.1, 3.2, 3.3, 3.4, 15.6, 17.3
 */
@RestController
@RequestMapping("/api")
public class AdjusterRestController {

    private static final Logger LOGGER = LoggerFactory.getLogger(AdjusterRestController.class);

    @Resource
    private AdjusterDao adjusterDao;

    @Resource
    private ClaimsLifecycleService claimsLifecycleService;

    /**
     * Lists all Adjuster records.
     *
     * @return all persisted Adjusters
     */
    @GetMapping("/adjusters")
    public List<Adjuster> findAll() {
        return adjusterDao.findAll();
    }

    /**
     * Reads a single Adjuster by identifier.
     *
     * @param id the Adjuster identifier
     * @return the matching Adjuster
     * @throws NotFoundException if no Adjuster with the given id exists
     */
    @GetMapping("/adjusters/{id}")
    public Adjuster findById(@PathVariable Long id) {
        Adjuster adjuster = adjusterDao.findById(id);
        if (adjuster == null) {
            throw new NotFoundException("Adjuster not found: " + id);
        }
        return adjuster;
    }

    /**
     * Creates a new Adjuster.
     *
     * @param adjuster the Adjuster payload
     * @return 201 Created with the persisted Adjuster, including its
     *         generated identifier
     */
    @PostMapping("/adjusters")
    public ResponseEntity<Adjuster> create(@RequestBody Adjuster adjuster) {
        adjuster.setAdjusterId(null);
        Adjuster saved = adjusterDao.save(adjuster);
        return new ResponseEntity<>(saved, HttpStatus.CREATED);
    }

    /**
     * Updates an existing Adjuster.
     *
     * @param id       the Adjuster identifier to update
     * @param adjuster the new field values
     * @return the persisted Adjuster
     * @throws NotFoundException if no Adjuster with the given id exists
     */
    @PutMapping("/adjusters/{id}")
    public Adjuster update(@PathVariable Long id, @RequestBody Adjuster adjuster) {
        Adjuster existing = adjusterDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Adjuster not found: " + id);
        }
        adjuster.setAdjusterId(id);
        return adjusterDao.save(adjuster);
    }

    /**
     * Deletes an Adjuster by identifier.
     *
     * @param id the Adjuster identifier to delete
     * @return 204 No Content on success
     * @throws NotFoundException if no Adjuster with the given id exists
     */
    @DeleteMapping("/adjusters/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        Adjuster existing = adjusterDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Adjuster not found: " + id);
        }
        adjusterDao.delete(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Assigns or reassigns an Adjuster to a Claim.
     *
     * <p>Delegates to {@link ClaimsLifecycleService#assignAdjuster} for all
     * business rules, including rejection of inactive Adjusters (Requirement
     * 3.4). On success, logs the Claim's formatted reference code via
     * {@link ClaimFormatUtil}.</p>
     *
     * @param claimId the Claim identifier
     * @param body    request body containing {@code adjusterId} (Number) and
     *                {@code changedBy} (String)
     * @return the service result map on success (HTTP 200), or the same map
     *         with an appropriate error HTTP status if the assignment was
     *         rejected
     * @see Requirements 3.2, 3.3, 3.4
     */
    @PostMapping("/claims/{claimId}/adjuster")
    public ResponseEntity<Map<String, Object>> assignAdjuster(@PathVariable Long claimId,
                                                                @RequestBody Map<String, Object> body) {
        Long adjusterId = toLong(body.get("adjusterId"));
        String changedBy = body.get("changedBy") == null ? null : body.get("changedBy").toString();

        Map<String, Object> result = claimsLifecycleService.assignAdjuster(claimId, adjusterId, changedBy);

        String errorMessage = (String) result.get("errorMessage");
        boolean failed = errorMessage != null;
        Object successFlag = result.get("successFlag");
        if (successFlag instanceof Boolean) {
            failed = failed || !((Boolean) successFlag);
        }

        if (failed) {
            HttpStatus status = (errorMessage != null && errorMessage.toLowerCase().contains("inactive"))
                    ? HttpStatus.CONFLICT
                    : HttpStatus.BAD_REQUEST;
            return new ResponseEntity<>(result, status);
        }

        String referenceCode = ClaimFormatUtil.generateClaimReferenceCode(claimId);
        LOGGER.info("Adjuster {} assigned to Claim {} by {}", adjusterId, referenceCode, changedBy);

        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    private Long toLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        return Long.valueOf(value.toString());
    }
}
