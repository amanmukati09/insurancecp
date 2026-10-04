package com.icps.dao;

import java.util.List;
import java.util.Map;

import com.icps.model.Settlement;

/**
 * DAO contract for the {@code settlement} table, backed exclusively by the
 * {@code sp_settlement_*} stored procedures (no inline business SQL).
 */
public interface SettlementDao {

    /**
     * Fetches the Settlement row for a given Claim via
     * {@code sp_settlement_find_by_claim} (at most one row per Claim).
     */
    Settlement findByClaimId(Long claimId);

    /**
     * Checks whether a Settlement already exists for a Claim via
     * {@code sp_settlement_exists_for_claim}.
     * Requirement 7.4: backs the "no duplicate Settlement" rule.
     */
    Boolean existsForClaim(Long claimId);

    /**
     * Calculates the Settlement payout for a Claim via
     * {@code sp_settlement_calculate}, without persisting anything.
     *
     * @return a map with keys {@code payoutAmount} ({@link java.math.BigDecimal})
     *         and {@code errorMessage} ({@link String})
     */
    Map<String, Object> calculate(Long claimId);

    /**
     * Approves a Settlement for a Claim via {@code sp_settlement_approve}
     * (transactional, composed: calculates the payout and transitions the
     * Claim to "Settled").
     *
     * @return a map with keys {@code newSettlementId} ({@link Long}) and
     *         {@code errorMessage} ({@link String})
     */
    Map<String, Object> approve(Long claimId, String approvedBy);

    /**
     * Lists all Settlement rows via {@code sp_settlement_list}.
     */
    List<Settlement> findAll();
}
