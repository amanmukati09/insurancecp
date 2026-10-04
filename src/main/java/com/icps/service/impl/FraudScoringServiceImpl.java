package com.icps.service.impl;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.icps.dao.ClaimDao;
import com.icps.dao.ClaimantDao;
import com.icps.dao.FraudFlagDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.model.Claim;
import com.icps.model.Claimant;
import com.icps.model.FraudFlag;
import com.icps.model.PolicyReference;
import com.icps.service.FraudScoringService;
import com.icps.util.RegionPolicyRuleHelper;
import com.icps.util.RegionPolicyRuleHelper.HandlingRule;

/**
 * Default {@link FraudScoringService} implementation.
 *
 * <p>Delegates the actual score computation to {@code FraudFlagDao.recomputeScore},
 * which is backed by the {@code sp_fraud_score_recompute} stored procedure
 * and already enforces the Requirement 8.3-8.5 scoring and threshold rules.
 * This service adds application-level logging, composes flag creation with
 * score recomputation (Requirement 8.3), and consults
 * {@link RegionPolicyRuleHelper} for the region-based fraud score weight
 * multiplier that applies to the Claim's claimant/policy combination
 * (design.md Components and Interfaces, Requirement 17.6).</p>
 */
@Service
public class FraudScoringServiceImpl implements FraudScoringService {

    private static final Logger LOGGER = LoggerFactory.getLogger(FraudScoringServiceImpl.class);

    private final FraudFlagDao fraudFlagDao;
    private final ClaimDao claimDao;
    private final ClaimantDao claimantDao;
    private final PolicyReferenceDao policyReferenceDao;
    private final RegionPolicyRuleHelper regionPolicyRuleHelper = new RegionPolicyRuleHelper();

    @Autowired
    public FraudScoringServiceImpl(FraudFlagDao fraudFlagDao, ClaimDao claimDao, ClaimantDao claimantDao,
            PolicyReferenceDao policyReferenceDao) {
        this.fraudFlagDao = fraudFlagDao;
        this.claimDao = claimDao;
        this.claimantDao = claimantDao;
        this.policyReferenceDao = policyReferenceDao;
    }

    @Override
    public Map<String, Object> recomputeScore(Long claimId) {
        LOGGER.info("Recomputing fraud score for claimId={}", claimId);
        logRegionPolicyHandlingRule(claimId);
        Map<String, Object> result = fraudFlagDao.recomputeScore(claimId);
        Object newScore = result == null ? null : result.get("newScore");
        Object underReviewFlag = result == null ? null : result.get("underReviewFlag");
        LOGGER.info("Fraud score recomputed for claimId={}, newScore={}, underReviewFlag={}", claimId, newScore,
                underReviewFlag);
        return result;
    }

    @Override
    public List<FraudFlag> getActiveFlags(Long claimId) {
        List<FraudFlag> activeFlags = fraudFlagDao.findActiveByClaim(claimId);
        return activeFlags == null ? Collections.emptyList() : activeFlags;
    }

    @Override
    public Long createFlag(Long claimId, String flagReason, Integer scoreWeight) {
        LOGGER.info("Creating fraud flag for claimId={}, flagReason={}, scoreWeight={}", claimId, flagReason,
                scoreWeight);
        Long fraudFlagId = fraudFlagDao.create(claimId, flagReason, scoreWeight);
        LOGGER.info("Fraud flag created with id={} for claimId={}; triggering score recomputation", fraudFlagId,
                claimId);
        recomputeScore(claimId);
        return fraudFlagId;
    }

    /**
     * Looks up the Claim's claimant and policy reference and consults
     * {@link RegionPolicyRuleHelper} for the resulting fraud score weight
     * multiplier and enhanced-review indicator, logging the outcome at DEBUG
     * level. This is illustrative wiring per design.md -- the actual score
     * math lives in the stored procedure, not here.
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
        LOGGER.debug(
                "Region/policy handling rule for claimId={}: fraudScoreWeightMultiplier={}, requiresEnhancedReview={}",
                claimId, handlingRule.getFraudScoreWeightMultiplier(), handlingRule.isRequiresEnhancedReview());
    }
}
