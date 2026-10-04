package com.icps.util;

import com.icps.model.Claimant;
import com.icps.model.PolicyReference;

import java.util.Arrays;
import java.util.List;

/**
 * Legacy-style branching helper that derives claim-handling rules from a
 * combination of the claimant's address state and the policy's type.
 *
 * This class intentionally mixes two unrelated branching concerns
 * (region-based litigation risk and policy-type-based settlement rounding)
 * into a single helper, consistent with the legacy code smell described in
 * Requirement 17.6. It is consumed by Fraud_Scoring_Service (for the fraud
 * score weight multiplier) and Settlement_Service (for the settlement
 * rounding rule).
 */
public class RegionPolicyRuleHelper {

    /**
     * States considered "high litigation" for claims-handling purposes.
     * Hardcoded on purpose to match the legacy branching-helper smell.
     */
    private static final List<String> HIGH_LITIGATION_STATES = Arrays.asList("CA", "FL", "NY", "IL");

    private static final String ROUNDING_NEAREST_DOLLAR = "NEAREST_DOLLAR";
    private static final String ROUNDING_NEAREST_CENT = "NEAREST_CENT";

    private static final double HIGH_LITIGATION_FRAUD_WEIGHT_MULTIPLIER = 1.25;
    private static final double DEFAULT_FRAUD_WEIGHT_MULTIPLIER = 1.0;

    /**
     * Derives the combined handling rule for a claim based on the claimant's
     * address state and the policy's type.
     *
     * @param claimant        the claimant associated with the claim (may be null)
     * @param policyReference the policy covering the claim (may be null)
     * @return a HandlingRule combining both branches of logic; never null
     */
    public HandlingRule getHandlingRule(Claimant claimant, PolicyReference policyReference) {
        HandlingRule rule = new HandlingRule();

        // Branch 1: region-based litigation risk, driven by claimant address state.
        if (claimant != null && claimant.getAddressState() != null
                && HIGH_LITIGATION_STATES.contains(claimant.getAddressState().toUpperCase())) {
            rule.setRequiresEnhancedReview(true);
            rule.setFraudScoreWeightMultiplier(HIGH_LITIGATION_FRAUD_WEIGHT_MULTIPLIER);
        } else {
            rule.setRequiresEnhancedReview(false);
            rule.setFraudScoreWeightMultiplier(DEFAULT_FRAUD_WEIGHT_MULTIPLIER);
        }

        // Branch 2: settlement rounding rule, driven by policy type.
        String policyType = (policyReference != null) ? policyReference.getPolicyType() : null;
        if (policyType == null) {
            rule.setSettlementRoundingRule(ROUNDING_NEAREST_CENT);
        } else {
            switch (policyType.toUpperCase()) {
                case "AUTO":
                    rule.setSettlementRoundingRule(ROUNDING_NEAREST_DOLLAR);
                    break;
                case "PROPERTY":
                case "LIABILITY":
                    rule.setSettlementRoundingRule(ROUNDING_NEAREST_CENT);
                    break;
                default:
                    rule.setSettlementRoundingRule(ROUNDING_NEAREST_CENT);
                    break;
            }
        }

        return rule;
    }

    /**
     * Result object combining both branches of the region/policy-type
     * handling logic into a single set of outcomes.
     */
    public static class HandlingRule {
        private double fraudScoreWeightMultiplier = DEFAULT_FRAUD_WEIGHT_MULTIPLIER;
        private String settlementRoundingRule = ROUNDING_NEAREST_CENT;
        private boolean requiresEnhancedReview = false;

        public double getFraudScoreWeightMultiplier() {
            return fraudScoreWeightMultiplier;
        }

        public void setFraudScoreWeightMultiplier(double fraudScoreWeightMultiplier) {
            this.fraudScoreWeightMultiplier = fraudScoreWeightMultiplier;
        }

        public String getSettlementRoundingRule() {
            return settlementRoundingRule;
        }

        public void setSettlementRoundingRule(String settlementRoundingRule) {
            this.settlementRoundingRule = settlementRoundingRule;
        }

        public boolean isRequiresEnhancedReview() {
            return requiresEnhancedReview;
        }

        public void setRequiresEnhancedReview(boolean requiresEnhancedReview) {
            this.requiresEnhancedReview = requiresEnhancedReview;
        }
    }
}
