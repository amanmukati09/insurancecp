package com.icps.dao;

import java.util.List;

import com.icps.model.ClaimStatusHistory;

/**
 * DAO interface for {@link ClaimStatusHistory} persistence.
 *
 * Claim_Status_History is an append-only audit trail (Requirement 14.1,
 * 14.3): only an insert ({@code sp_csh_create}) and finder
 * ({@code sp_csh_list_by_claim}) procedure are exposed here; no update or
 * delete method is provided, matching the stored procedure library.
 */
public interface ClaimStatusHistoryDao {

    Long create(Long claimId, String priorStatus, String newStatus, String changedBy, String note);

    /**
     * Returns history rows for the given Claim ordered most-recent-first
     * (Requirement 5.6/6.6 display convention), per {@code sp_csh_list_by_claim}.
     */
    List<ClaimStatusHistory> findByClaim(Long claimId);
}
