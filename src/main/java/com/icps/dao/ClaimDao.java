package com.icps.dao;

import java.util.Date;
import java.util.List;
import java.util.Map;

import com.icps.model.Claim;

/**
 * DAO interface for {@link Claim} persistence.
 *
 * Claim is a core transactional entity backed by stored procedures
 * (design.md Persistence Split, Requirement 15.3, 17.2). All methods are
 * implemented purely in terms of the Claim CRUD and lifecycle stored
 * procedures (tasks 4.2, 5.1) via {@code SimpleJdbcCall} / {@code JdbcTemplate}
 * CALL statements -- no inline business SQL (Requirement 15.4).
 */
public interface ClaimDao {

    /**
     * Raw CRUD insert via {@code sp_claim_create}. No FNOL validation, no
     * history/reserve rows are created. Intended for internal/seeding use;
     * application claim creation should go through {@link #createClaimWithFnol}.
     */
    Long createClaim(Long claimantId, Long policyReferenceId, Date lossDate, String lossDescription);

    Claim findById(Long id);

    List<Claim> findAll();

    List<Claim> findByClaimant(Long claimantId);

    List<Claim> findByAdjuster(Long adjusterId);

    List<Claim> findByStatus(String status);

    Integer getVersion(Long claimId);

    String getCurrentStatus(Long claimId);

    /**
     * Lifecycle-composing creation via {@code sp_claim_create_with_fnol}.
     * Validates the referenced Policy_Reference and loss-date range,
     * atomically inserts the Claim, initial Claim_Status_History row, and
     * default Reserve row.
     *
     * @return a map containing {@code "newClaimId"} (Long, null on failure)
     *         and {@code "errorMessage"} (String, null on success).
     */
    Map<String, Object> createClaimWithFnol(Long claimantId, Long policyReferenceId, Date lossDate, String lossDescription);

    /**
     * Status transition via {@code sp_claim_transition_status}, enforcing
     * the allowed-transition graph and optimistic concurrency on
     * {@code claim.version}.
     *
     * @return a map containing {@code "successFlag"} (Boolean) and
     *         {@code "errorMessage"} (String, null on success).
     */
    Map<String, Object> transitionStatus(Long claimId, String newStatus, String changedBy, Integer expectedVersion);

    /**
     * Adjuster assignment/reassignment via {@code sp_claim_assign_adjuster}.
     *
     * @return a map containing {@code "successFlag"} (Boolean) and
     *         {@code "errorMessage"} (String, null on success).
     */
    Map<String, Object> assignAdjuster(Long claimId, Long newAdjusterId, String changedBy);
}
