package com.icps.service;

import java.util.Date;
import java.util.Map;

import com.icps.model.Claim;

/**
 * Service interface responsible for validating and executing Claim status
 * transitions and other claim lifecycle operations (FNOL intake, adjuster
 * assignment, status transitions).
 *
 * <p>All business validation (Policy_Reference resolution, loss-date range
 * checking, allowed-transition graph, optimistic concurrency, inactive
 * adjuster rejection) is enforced by the composed stored procedures invoked
 * through {@code ClaimDao}; this service is the single Spring-managed entry
 * point for the controller/web layer (Requirement 15.3, 17.2).</p>
 *
 * @see Requirements 1.2, 1.3, 1.4, 1.5, 3.2, 3.3, 3.4, 6.1, 6.2, 6.3, 6.4,
 *      6.5, 6.7, 12.2, 12.3, 12.4, 12.5
 */
public interface ClaimsLifecycleService {

    /**
     * Creates a new Claim from an FNOL (First Notice of Loss) submission.
     *
     * <p>Validates the referenced Policy_Reference exists and that the loss
     * date falls within its effective date range, then atomically creates
     * the Claim (status "Open"), its initial Claim_Status_History entry,
     * and a default Reserve row.</p>
     *
     * @param claimantId        the Claimant identifier
     * @param policyReferenceId the Policy_Reference identifier
     * @param lossDate          the date of loss
     * @param lossDescription   a description of the loss
     * @return a result map containing {@code "claimId"} (Long, {@code null}
     *         on failure) and {@code "errorMessage"} (String, {@code null}
     *         on success)
     * @see Requirements 1.2, 1.3, 1.4, 1.5, 12.2, 12.3, 12.4, 12.5
     */
    Map<String, Object> createClaim(Long claimantId, Long policyReferenceId, Date lossDate, String lossDescription);

    /**
     * Requests a Claim status transition, validated against the allowed
     * lifecycle sequence with optimistic-concurrency checking via
     * {@code expectedVersion}.
     *
     * @param claimId         the Claim identifier
     * @param newStatus       the requested target status
     * @param changedBy       the acting user
     * @param expectedVersion the Claim version the caller last observed
     * @return a result map containing {@code "successFlag"} (Boolean) and
     *         {@code "errorMessage"} (String, {@code null} on success)
     * @see Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.7
     */
    Map<String, Object> transitionStatus(Long claimId, String newStatus, String changedBy, Integer expectedVersion);

    /**
     * Assigns or reassigns an Adjuster to a Claim, rejecting assignment to
     * an inactive Adjuster.
     *
     * @param claimId      the Claim identifier
     * @param newAdjusterId the Adjuster identifier to assign
     * @param changedBy    the acting user
     * @return a result map containing {@code "successFlag"} (Boolean) and
     *         {@code "errorMessage"} (String, {@code null} on success)
     * @see Requirements 3.2, 3.3, 3.4
     */
    Map<String, Object> assignAdjuster(Long claimId, Long newAdjusterId, String changedBy);

    /**
     * Fetches a Claim by its identifier.
     *
     * @param claimId the Claim identifier
     * @return the matching {@link Claim}, or {@code null} if not found
     */
    Claim getClaimById(Long claimId);
}
