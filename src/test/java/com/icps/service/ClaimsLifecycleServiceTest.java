package com.icps.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import com.icps.dao.ClaimDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.model.Claim;
import com.icps.service.impl.ClaimsLifecycleServiceImpl;

/**
 * Unit tests for {@link ClaimsLifecycleServiceImpl} covering claims
 * lifecycle transition validation delegation to {@link ClaimDao}.
 *
 * Satisfies Requirement 18.5 (claims lifecycle transition validation
 * coverage) and documents Requirements 1.2-1.5, 3.2-3.4, 6.1-6.7, 12.2-12.5.
 */
@RunWith(MockitoJUnitRunner.class)
public class ClaimsLifecycleServiceTest {

    @Mock
    private ClaimDao claimDao;

    @Mock
    private PolicyReferenceDao policyReferenceDao;

    private ClaimsLifecycleService claimsLifecycleService;

    @Before
    public void setUp() {
        claimsLifecycleService = new ClaimsLifecycleServiceImpl(claimDao, policyReferenceDao);
    }

    @Test
    public void createClaim_delegatesToClaimDaoCreateClaimWithFnol() {
        Long claimantId = 10L;
        Long policyReferenceId = 20L;
        Date lossDate = new Date();
        String lossDescription = "Rear-end collision";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("newClaimId", 100L);
        daoResult.put("errorMessage", null);
        when(claimDao.createClaimWithFnol(claimantId, policyReferenceId, lossDate, lossDescription))
                .thenReturn(daoResult);

        Map<String, Object> result = claimsLifecycleService.createClaim(claimantId, policyReferenceId, lossDate,
                lossDescription);

        verify(claimDao).createClaimWithFnol(claimantId, policyReferenceId, lossDate, lossDescription);
        assertNotNull(result);
    }

    @Test
    public void createClaim_resultIncludesClaimIdWhenDaoReturnsNewClaimId() {
        Long claimantId = 11L;
        Long policyReferenceId = 21L;
        Date lossDate = new Date();
        String lossDescription = "Water damage";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("newClaimId", 101L);
        when(claimDao.createClaimWithFnol(claimantId, policyReferenceId, lossDate, lossDescription))
                .thenReturn(daoResult);

        Map<String, Object> result = claimsLifecycleService.createClaim(claimantId, policyReferenceId, lossDate,
                lossDescription);

        assertEquals(101L, result.get("claimId"));
    }

    @Test
    public void transitionStatus_delegatesToClaimDaoWithCorrectArgs() {
        Long claimId = 200L;
        String newStatus = "Investigating";
        String changedBy = "adjuster1";
        Integer expectedVersion = 1;

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("successFlag", true);
        when(claimDao.transitionStatus(claimId, newStatus, changedBy, expectedVersion)).thenReturn(daoResult);

        Map<String, Object> result = claimsLifecycleService.transitionStatus(claimId, newStatus, changedBy,
                expectedVersion);

        verify(claimDao).transitionStatus(eq(claimId), eq(newStatus), eq(changedBy), eq(expectedVersion));
        assertEquals(Boolean.TRUE, result.get("successFlag"));
    }

    @Test
    public void transitionStatus_returnsFailureInfoWhenDaoReportsFailure() {
        Long claimId = 201L;
        String newStatus = "Settled";
        String changedBy = "adjuster2";
        Integer expectedVersion = 3;

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("successFlag", false);
        daoResult.put("errorMessage", "Invalid status transition from Open to Settled");
        when(claimDao.transitionStatus(claimId, newStatus, changedBy, expectedVersion)).thenReturn(daoResult);

        Map<String, Object> result = claimsLifecycleService.transitionStatus(claimId, newStatus, changedBy,
                expectedVersion);

        assertFalse((Boolean) result.get("successFlag"));
        assertEquals("Invalid status transition from Open to Settled", result.get("errorMessage"));
    }

    @Test
    public void assignAdjuster_delegatesToClaimDao() {
        Long claimId = 300L;
        Long newAdjusterId = 55L;
        String changedBy = "supervisor1";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("successFlag", true);
        when(claimDao.assignAdjuster(claimId, newAdjusterId, changedBy)).thenReturn(daoResult);

        Map<String, Object> result = claimsLifecycleService.assignAdjuster(claimId, newAdjusterId, changedBy);

        verify(claimDao).assignAdjuster(claimId, newAdjusterId, changedBy);
        assertEquals(Boolean.TRUE, result.get("successFlag"));
    }

    @Test
    public void getClaimById_delegatesToClaimDaoFindById() {
        Long claimId = 400L;
        Claim claim = new Claim();
        claim.setClaimId(claimId);
        claim.setStatus("Open");
        when(claimDao.findById(claimId)).thenReturn(claim);

        Claim result = claimsLifecycleService.getClaimById(claimId);

        verify(claimDao).findById(claimId);
        assertNotNull(result);
        assertEquals("Open", result.getStatus());
    }
}
