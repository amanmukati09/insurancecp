package com.icps.service;
import java.util.Map;
import com.icps.model.Settlement;
/**
 * Service interface for calculating and recording Settlement amounts
 * (Requirement 7).
 *
 * <p>Delegates calculation and approval to {@code SettlementDao}, whose
 * stored procedures already enforce the Requirement 7 deductible/coverage
 * limit clamp (7.2, 7.7), the "Approved"-only + no-duplicate-settlement
 * rules (7.3, 7.4), the Policy_Reference completeness check (7.5), and the
 * composed transition to "Settled" on approval (7.6).</p>
 */
public interface SettlementService {
    /**
     * Calculates the Settlement payout for a Claim via
     * {@code SettlementDao.calculate}, without persisting anything.
     *
     * @param claimId the Claim identifier
     * @return a result map with keys {@code payoutAmount} ({@link java.math.BigDecimal})
     *         and {@code errorMessage} ({@link String}, {@code null} on success)
     * @see Requirements 7.2, 7.5, 7.7
     */
    Map<String, Object> calculateSettlement(Long claimId);
    /**
     * Approves a Settlement for a Claim via {@code SettlementDao.approve}
     * (transactional, composed: calculates the payout and transitions the
     * Claim to "Settled").
     *
     * @param claimId    the Claim identifier
     * @param approvedBy the acting/approving user
     * @return a result map with keys {@code newSettlementId} ({@link Long})
     *         and {@code errorMessage} ({@link String}, {@code null} on success)
     * @see Requirements 7.3, 7.4, 7.6
     */
    Map<String, Object> approveSettlement(Long claimId, String approvedBy);
    /**
     * Fetches the Settlement row for a given Claim.
     *
     * @param claimId the Claim identifier
     * @return the matching {@link Settlement}, or {@code null} if the Claim
     *         has no Settlement
     */
    Settlement getSettlement(Long claimId);
}
