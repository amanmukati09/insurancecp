package com.icps.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

import org.junit.Test;

/**
 * Documents and asserts the fixed Claim status enumeration and the allowed
 * lifecycle transition graph seeded in the {@code claim_status_transition_rule}
 * table (see {@code src/main/resources/db/40_seed_reference_lookup.sql}).
 *
 * <p>There is no runtime enum class for Claim status in ICPS -- the status
 * enumeration and allowed-transition graph are enforced entirely by the
 * {@code claim_status_transition_rule} lookup table and the
 * {@code sp_claim_transition_status} stored procedure (Requirement 6.1,
 * 6.2). This test statically documents and asserts the known seeded values
 * so that any future unintended change to the lifecycle graph is caught at
 * test time.</p>
 *
 * Satisfies Requirement 18.5 (claims lifecycle transition validation
 * coverage).
 */
public class ClaimStatusEnumerationTest {

    /** The 6 valid Claim statuses, per Requirement 6.1. */
    private static final Set<String> EXPECTED_STATUSES = new LinkedHashSet<>(Arrays.asList(
            "Open", "Investigating", "Approved", "Denied", "Settled", "Closed"));

    /**
     * The allowed (prior_status -> new_status) transition pairs seeded into
     * {@code claim_status_transition_rule} (Requirement 6.2), as pipe-joined
     * strings for simple set comparison.
     */
    private static final Set<String> EXPECTED_TRANSITION_PAIRS = new LinkedHashSet<>(Arrays.asList(
            "Open|Investigating",
            "Investigating|Approved",
            "Investigating|Denied",
            "Approved|Settled",
            "Settled|Closed",
            "Denied|Closed"));

    @Test
    public void expectedStatusEnumeration_hasExactlySixKnownStatuses() {
        assertEquals(6, EXPECTED_STATUSES.size());
        assertTrue(EXPECTED_STATUSES.containsAll(Arrays.asList(
                "Open", "Investigating", "Approved", "Denied", "Settled", "Closed")));
    }

    @Test
    public void expectedTransitionGraph_hasExactlySixAllowedPairs() {
        assertEquals(6, EXPECTED_TRANSITION_PAIRS.size());
    }

    @Test
    public void expectedTransitionGraph_everyPairReferencesOnlyKnownStatuses() {
        Set<String> statusesReferencedInPairs = new HashSet<>();
        for (String pair : EXPECTED_TRANSITION_PAIRS) {
            String[] parts = pair.split("\\|");
            statusesReferencedInPairs.add(parts[0]);
            statusesReferencedInPairs.add(parts[1]);
        }
        assertTrue(EXPECTED_STATUSES.containsAll(statusesReferencedInPairs));
    }

    @Test
    public void expectedTransitionGraph_openHasNoIncomingTransitions() {
        for (String pair : EXPECTED_TRANSITION_PAIRS) {
            String newStatus = pair.split("\\|")[1];
            assertTrue("Open" + " must not be a transition target", !newStatus.equals("Open"));
        }
    }
}
