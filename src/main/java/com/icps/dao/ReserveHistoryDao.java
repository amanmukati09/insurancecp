package com.icps.dao;

import java.util.List;

import com.icps.model.ReserveHistory;

/**
 * DAO interface for read access to the {@link ReserveHistory} append-only
 * audit trail.
 *
 * Reserve_History is insert-only (Requirement 14.2, 14.3): rows are written
 * exclusively by the transactional {@code sp_reserve_set_amount} procedure
 * (via {@link ReserveDao#setAmount}), so this DAO exposes only the listing
 * procedure, {@code sp_rh_list_by_reserve} (from
 * {@code 12_sp_crud_damage_reserve.sql}). No update/delete method is
 * provided, matching the absence of {@code sp_rh_update}/{@code sp_rh_delete}
 * procedures.
 *
 * <p><b>Composition note:</b> {@code sp_rh_list_by_reserve} is keyed by
 * {@code reserve_id}, not {@code claim_id}. {@link #findByClaimViaReserve}
 * implements the claim-id-based lookup here (by first resolving the Claim's
 * Reserve via {@link ReserveDao#findByClaimId}) purely as a convenience for
 * callers that only have a {@code claimId} on hand (e.g. the Claim detail
 * view, Requirement 5.6). Callers that already have a {@code reserveId} on
 * hand should prefer {@link #findByReserve} directly. If a future caller
 * needs this composition to participate in a larger service-level
 * transaction or caching strategy, the service layer may instead compose
 * {@code ReserveDao.findByClaimId} + {@code ReserveHistoryDao.findByReserve}
 * itself; both options use only the already-loaded stored procedures.</p>
 */
public interface ReserveHistoryDao {

    /**
     * Lists all Reserve_History rows for a Reserve via
     * {@code sp_rh_list_by_reserve}, most recent change first
     * (Requirement 5.6).
     */
    List<ReserveHistory> findByReserve(Long reserveId);

    /**
     * Lists all Reserve_History rows for the Reserve belonging to a Claim.
     * Resolves {@code claimId} to its {@code reserveId} via
     * {@link ReserveDao#findByClaimId}, then delegates to
     * {@link #findByReserve}. Returns an empty list if the Claim has no
     * Reserve.
     */
    List<ReserveHistory> findByClaimViaReserve(Long claimId);
}
