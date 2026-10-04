package com.icps.service.impl;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.icps.dao.ClaimDao;
import com.icps.dao.ClaimantDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.dao.SettlementDao;
import com.icps.model.Claim;
import com.icps.model.Claimant;
import com.icps.model.PolicyReference;
import com.icps.model.Settlement;
import com.icps.service.SettlementService;
import com.icps.util.RegionPolicyRuleHelper;
import com.icps.util.RegionPolicyRuleHelper.HandlingRule;
/**
 * Default {@link SettlementService} implementation.
 *
 * <p>Delegates all validation and business logic to the underlying
 * {@code SimpleJdbcCall}-backed {@code SettlementDao}, whose stored
 * procedures already enforce the Requirement 7 deductible/coverage limit
 * clamp (7.2, 7.7), the "Approved"-only + no-duplicate-settlement rules
 * (7.3, 7.4), the Policy_Reference completeness check (7.5), and the
 * composed transition to "Settled" on approval (7.6). This service adds
 * application-level logging and consults {@link RegionPolicyRuleHelper} for
 * the settlement rounding rule that applies to the Claim's claimant/policy
 * combination (design.md Components and Interfaces, Requirement 17.6).</p>
 */
@Service
public class SettlementServiceImpl implements SettlementService {
    private static final Logger LOGGER = LoggerFactory.getLogger(SettlementServiceImpl.class);
    private final SettlementDao settlementDao;
    private final ClaimDao claimDao;
    private final ClaimantDao claimantDao;
    private final PolicyReferenceDao policyReferenceDao;
    private final RegionPolicyRuleHelper regionPolicyRuleHelper = new RegionPolicyRuleHelper();
    @Autowired
    public SettlementServiceImpl(SettlementDao settlementDao, ClaimDao claimDao, ClaimantDao claimantDao,
            PolicyReferenceDao policyReferenceDao) {
        this.settlementDao = settlementDao;
        this.claimDao = claimDao;
        this.claimantDao = claimantDao;
        this.policyReferenceDao = policyReferenceDao;
    }
    @Override
    public Map<String, Object> calculateSettlement(Long claimId) {
        LOGGER.info("Calculating settlement for claimId={}", claimId);
        logRegionPolicyHandlingRule(claimId);
        Map<String, Object> result = settlementDao.calculate(claimId);
        Object payoutAmount = result == null ? null : result.get("payoutAmount");
        Object errorMessage = result == null ? null : result.get("errorMessage");
        if (errorMessage == null) {
            LOGGER.info("Settlement calculated for claimId={}, payoutAmount={}", claimId, payoutAmount);
        } else {
            LOGGER.warn("Settlement calculation failed for claimId={}, errorMessage={}", claimId, errorMessage);
        }
        return result;
    }
    @Override
    public Map<String, Object> approveSettlement(Long claimId, String approvedBy) {
        LOGGER.info("Approving settlement for claimId={}, approvedBy={}", claimId, approvedBy);
        Map<String, Object> result = settlementDao.approve(claimId, approvedBy);
        Object newSettlementId = result == null ? null : result.get("newSettlementId");
        Object errorMessage = result == null ? null : result.get("errorMessage");
        if (errorMessage == null) {
            LOGGER.info("Settlement approved for claimId={}, newSettlementId={}", claimId, newSettlementId);
        } else {
            LOGGER.warn("Settlement approval failed for claimId={}, errorMessage={}", claimId, errorMessage);
        }
        return result;
    }
    @Override
    public Settlement getSettlement(Long claimId) {
        return settlementDao.findByClaimId(claimId);
    }
    /**
     * Looks up the Claim's claimant and policy reference and consults
     * {@link RegionPolicyRuleHelper} for the resulting settlement rounding
     * rule, logging the outcome at DEBUG level. This is illustrative wiring
     * per design.md -- the actual rounding math lives in the stored
     * procedure, not here.
     */
    private void logRegionPolicyHandlingRule(Long claimId) {
        if (!LOGGER.isDebugEnabled()) {
            return;
        }
        Claim claim = claimDao.findById(claimId);
        if (claim == null) {
            LOGGER.debug("No Claim found for claimId={}; skipping region/policy handling rule lookup", claimId);
            return;
        }
        Claimant claimant = claim.getClaimantId() == null ? null : claimantDao.findById(claim.getClaimantId());
        PolicyReference policyReference = claim.getPolicyReferenceId() == null ? null
                : policyReferenceDao.findById(claim.getPolicyReferenceId());
        HandlingRule handlingRule = regionPolicyRuleHelper.getHandlingRule(claimant, policyReference);
        LOGGER.debug("Region/policy handling rule for claimId={}: settlementRoundingRule={}", claimId,
                handlingRule.getSettlementRoundingRule());
    }
}
