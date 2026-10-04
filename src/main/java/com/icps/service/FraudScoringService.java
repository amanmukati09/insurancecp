package com.icps.service;

import java.util.List;
import java.util.Map;

import com.icps.model.FraudFlag;

/**
 * Service interface for computing and maintaining a Claim's fraud score from
 * its active {@link FraudFlag} conditions (Requirement 8).
 *
 * <p>The actual score math (summing active Fraud_Flag score weights, capping
 * at 100, and toggling the Claim's "Under Fraud Review" indicator against
 * the configured threshold) lives in the {@code sp_fraud_score_recompute}
 * stored procedure, invoked via {@code FraudFlagDao.recomputeScore}
 * (Requirement 15.4, 17.2). This service exists to give the controller layer
 * a single, Spring-managed entry point, to compose flag creation with score
 * recomputation, and to consult {@code RegionPolicyRuleHelper} for the
 * region-based fraud score weight multiplier (design.md Components and
 * Interfaces, Requirement 17.6).</p>
 */
public interface FraudScoringService {

    /**
     * Recomputes the fraud score for a Claim from its active Fraud_Flag
     * conditions, toggling the "Under Fraud Review" indicator against the
     * configured threshold.
     *
     * @param claimId the Claim identifier
     * @return a result map with keys {@code newScore} ({@link Integer}) and
     *         {@code underReviewFlag} ({@link Boolean})
     * @see Requirements 8.3, 8.4, 8.5
     */
    Map<String, Object> recomputeScore(Long claimId);

    /**
     * Lists the active Fraud_Flag records for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the active Fraud_Flag records, or an empty list if none exist
     * @see Requirements 8.3
     */
    List<FraudFlag> getActiveFlags(Long claimId);

    /**
     * Creates a new Fraud_Flag for a Claim and triggers a fraud score
     * recomputation as a follow-up operation (Requirement 8.3).
     *
     * @param claimId    the Claim identifier
     * @param flagReason the reason for the flag
     * @param scoreWeight the scoring weight contributed by this flag
     * @return the generated {@code fraud_flag_id}
     * @see Requirements 8.1, 8.2, 8.3
     */
    Long createFlag(Long claimId, String flagReason, Integer scoreWeight);
}
