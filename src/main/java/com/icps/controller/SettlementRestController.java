package com.icps.controller;

import java.util.Map;

import javax.annotation.Resource;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.icps.exception.NotFoundException;
import com.icps.model.Settlement;
import com.icps.service.SettlementService;

/**
 * REST JSON controller exposing calculate and read operations for
 * {@link Settlement} (Requirement 7).
 *
 * <p>All operations delegate to {@link SettlementService}, which in turn
 * delegates to the {@code SimpleJdbcCall}-backed {@code SettlementDao} whose
 * stored procedures enforce the Requirement 7.2/7.7 deductible/coverage
 * limit clamp, the Requirement 7.3/7.4 "Approved"-only and
 * no-duplicate-settlement rules, and the Requirement 7.5 Policy_Reference
 * completeness check.</p>
 *
 * @see Requirements 7.2, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/settlement")
public class SettlementRestController {

    @Resource
    private SettlementService settlementService;

    /**
     * Reads the Settlement record for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Settlement
     * @throws NotFoundException if the Claim has no Settlement
     */
    @GetMapping
    public Settlement getSettlement(@PathVariable Long claimId) {
        Settlement settlement = settlementService.getSettlement(claimId);
        if (settlement == null) {
            throw new NotFoundException("Settlement not found for claim: " + claimId);
        }
        return settlement;
    }

    /**
     * Calculates the Settlement payout for a Claim without persisting
     * anything (Requirement 7.2).
     *
     * <p>The result map contains {@code payoutAmount} on success or
     * {@code errorMessage} when the Claim's status is not "Approved"
     * (7.3), a Settlement already exists (7.4), or the Policy_Reference
     * data is incomplete (7.5).</p>
     *
     * @param claimId the Claim identifier
     * @return a result map with keys {@code payoutAmount} and
     *         {@code errorMessage}
     */
    @PostMapping("/calculate")
    public Map<String, Object> calculateSettlement(@PathVariable Long claimId) {
        return settlementService.calculateSettlement(claimId);
    }
}
