package com.icps.dao;

import java.util.List;
import java.util.Map;

import com.icps.model.FraudFlag;

/**
 * DAO contract for the {@code fraud_flag} table, backed exclusively by the
 * {@code sp_ff_*} / {@code sp_fraud_score_recompute} stored procedures (no
 * inline business SQL).
 */
public interface FraudFlagDao {

    /**
     * Creates a new Fraud_Flag row for a Claim via {@code sp_ff_create}
     * (new flags default to active).
     *
     * @return the generated {@code fraud_flag_id}
     */
    Long create(Long claimId, String flagReason, Integer scoreWeight);

    /**
     * Fetches a single Fraud_Flag by id via {@code sp_ff_read}.
     */
    FraudFlag findById(Long id);

    /**
     * Lists all Fraud_Flag rows (active and inactive) for a Claim via
     * {@code sp_ff_list_by_claim}.
     */
    List<FraudFlag> findByClaim(Long claimId);

    /**
     * Lists only active Fraud_Flag rows for a Claim via
     * {@code sp_ff_list_active_by_claim}.
     * Requirement 8.3: feeds fraud score recomputation.
     */
    List<FraudFlag> findActiveByClaim(Long claimId);

    /**
     * Updates the mutable fields of a Fraud_Flag via {@code sp_ff_update}.
     */
    void update(Long id, String flagReason, Integer scoreWeight, Boolean isActive);

    /**
     * Deletes a Fraud_Flag by id via {@code sp_ff_delete}.
     */
    void delete(Long id);

    /**
     * Recomputes the fraud score for a Claim via
     * {@code sp_fraud_score_recompute} (sums active Fraud_Flag score
     * weights, capped at 100, and toggles the Claim's "Under Fraud Review"
     * indicator against the configured threshold).
     *
     * @return a map with keys {@code newScore} ({@link Integer}) and
     *         {@code underReviewFlag} ({@link Boolean})
     */
    Map<String, Object> recomputeScore(Long claimId);
}
