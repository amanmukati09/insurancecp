package com.icps.controller;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.icps.dao.ClaimDao;
import com.icps.dao.ClaimStatusHistoryDao;
import com.icps.exception.NotFoundException;
import com.icps.model.Claim;
import com.icps.model.ClaimStatusHistory;
import com.icps.service.ClaimsLifecycleService;
/**
 * REST JSON controller exposing read, status-transition, and
 * status-history operations for {@link Claim} records.
 *
 * <p>Claim creation (FNOL intake) and the claim detail/status view are
 * handled by the JSP-rendered {@code ClaimIntakeController} and
 * {@code ClaimDetailController} respectively (Requirement 15.5); this
 * controller covers the REST JSON surface for listing/filtering Claims,
 * reading a single Claim, requesting a status transition, and retrieving
 * a Claim's status history (Requirement 15.6).</p>
 *
 * <p>Claim does not expose a general field-update stored procedure/DAO
 * method (only creation, status transition, and adjuster assignment are
 * supported), so no {@code PUT} update endpoint is provided here.</p>
 *
 * @see Requirements 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 15.6
 */
@RestController
@RequestMapping("/api/claims")
public class ClaimRestController {
    @Resource
    private ClaimDao claimDao;
    @Resource
    private ClaimsLifecycleService claimsLifecycleService;
    @Resource
    private ClaimStatusHistoryDao claimStatusHistoryDao;
    /**
     * Lists Claims, optionally filtered by claimant, adjuster, or status.
     * At most one filter is expected to be meaningfully applied; if more
     * than one is supplied, {@code claimantId} takes precedence over
     * {@code adjusterId}, which takes precedence over {@code status}.
     *
     * @param claimantId optional Claimant identifier filter
     * @param adjusterId optional Adjuster identifier filter
     * @param status     optional status filter
     * @return the matching Claims
     */
    @GetMapping
    public List<Claim> findAll(@RequestParam(required = false) Long claimantId,
            @RequestParam(required = false) Long adjusterId,
            @RequestParam(required = false) String status) {
        if (claimantId != null) {
            return claimDao.findByClaimant(claimantId);
        }
        if (adjusterId != null) {
            return claimDao.findByAdjuster(adjusterId);
        }
        if (status != null) {
            return claimDao.findByStatus(status);
        }
        return claimDao.findAll();
    }
    /**
     * Reads a single Claim by identifier.
     *
     * @param id the Claim identifier
     * @return the matching Claim's current field values
     * @throws NotFoundException if no Claim exists with the given identifier
     * @see Requirements 6.6
     */
    @GetMapping("/{id}")
    public Claim findById(@PathVariable Long id) {
        Claim claim = claimDao.findById(id);
        if (claim == null) {
            throw new NotFoundException("Claim not found: " + id);
        }
        return claim;
    }
    /**
     * Requests a Claim status transition.
     *
     * <p>The request body is expected to contain {@code newStatus} (String),
     * {@code changedBy} (String), and {@code expectedVersion} (Integer) keys.
     * Delegates validation of the allowed-transition graph, not-found
     * handling, and optimistic-concurrency checking to
     * {@link ClaimsLifecycleService#transitionStatus}.</p>
     *
     * @param id      the Claim identifier
     * @param request the transition request payload
     * @return 200 OK with the result map on success; 404 if the Claim does
     *         not exist; 409 if the transition is not allowed for the
     *         Claim's current status or the supplied version is stale
     * @see Requirements 6.2, 6.3, 6.4, 6.5, 6.7
     */
    @PostMapping("/{id}/status-transitions")
    public ResponseEntity<Map<String, Object>> transitionStatus(@PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        String newStatus = (String) request.get("newStatus");
        String changedBy = (String) request.get("changedBy");
        Object expectedVersionRaw = request.get("expectedVersion");
        Integer expectedVersion = expectedVersionRaw == null ? null : Integer.valueOf(expectedVersionRaw.toString());
        Map<String, Object> result = claimsLifecycleService.transitionStatus(id, newStatus, changedBy, expectedVersion);
        Boolean successFlag = (Boolean) result.get("successFlag");
        if (Boolean.TRUE.equals(successFlag)) {
            return new ResponseEntity<>(result, HttpStatus.OK);
        }
        String errorMessage = (String) result.get("errorMessage");
        HttpStatus httpStatus = resolveTransitionFailureStatus(id, errorMessage);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", errorMessage);
        return new ResponseEntity<>(body, httpStatus);
    }
    /**
     * Retrieves the full Claim_Status_History for a Claim, as returned by
     * {@code sp_csh_list_by_claim} (most-recent-first).
     *
     * @param id the Claim identifier
     * @return the Claim's status history entries
     * @see Requirements 6.6
     */
    @GetMapping("/{id}/status-history")
    public List<ClaimStatusHistory> statusHistory(@PathVariable Long id) {
        return claimStatusHistoryDao.findByClaim(id);
    }
    /**
     * Determines the HTTP status for a failed status transition: 404 if the
     * Claim does not exist (Requirement 6.4), 409 for an invalid transition
     * or a stale version (Requirements 6.3, 6.7).
     */
    private HttpStatus resolveTransitionFailureStatus(Long claimId, String errorMessage) {
        if (claimDao.findById(claimId) == null) {
            return HttpStatus.NOT_FOUND;
        }
        return HttpStatus.CONFLICT;
    }
}
