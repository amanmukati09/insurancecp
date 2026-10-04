package com.icps.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import com.icps.dao.ClaimDao;
import com.icps.dao.ClaimantDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.dao.SettlementDao;
import com.icps.model.Claim;
import com.icps.service.impl.SettlementServiceImpl;

/**
 * Unit tests for {@link SettlementServiceImpl} covering settlement
 * calculation logic delegation to {@link SettlementDao}.
 *
 * Satisfies Requirement 18.5 (settlement calculation logic coverage) and
 * documents Requirements 7.2-7.7.
 */
@RunWith(MockitoJUnitRunner.class)
public class SettlementServiceTest {

    @Mock
    private SettlementDao settlementDao;

    @Mock
    private ClaimDao claimDao;

    @Mock
    private ClaimantDao claimantDao;

    @Mock
    private PolicyReferenceDao policyReferenceDao;

    private SettlementService settlementService;

    @Before
    public void setUp() {
        settlementService = new SettlementServiceImpl(settlementDao, claimDao, claimantDao, policyReferenceDao);
    }

    @Test
    public void calculateSettlement_delegatesToSettlementDaoCalculateAndReturnsPayoutAmount() {
        Long claimId = 500L;
        BigDecimal payoutAmount = new BigDecimal("12000.00");

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("payoutAmount", payoutAmount);
        daoResult.put("errorMessage", null);
        when(settlementDao.calculate(claimId)).thenReturn(daoResult);

        Map<String, Object> result = settlementService.calculateSettlement(claimId);

        verify(settlementDao).calculate(claimId);
        assertEquals(payoutAmount, result.get("payoutAmount"));
    }

    @Test
    public void calculateSettlement_handlesMissingClaimantOrPolicyWithoutThrowing() {
        Long claimId = 501L;

        // The service's region/policy handling-rule lookup (which consults
        // claimantDao/policyReferenceDao) only runs when DEBUG logging is
        // enabled; it is lenient here so the claimDao lookup itself (which
        // always runs) is still exercised with a null-claimant/policy Claim
        // without the test depending on the logger's configured level.
        Claim claim = new Claim();
        claim.setClaimId(claimId);
        claim.setClaimantId(null);
        claim.setPolicyReferenceId(null);
        org.mockito.Mockito.lenient().when(claimDao.findById(claimId)).thenReturn(claim);
        org.mockito.Mockito.lenient().when(claimantDao.findById(org.mockito.ArgumentMatchers.any())).thenReturn(null);
        org.mockito.Mockito.lenient().when(policyReferenceDao.findById(org.mockito.ArgumentMatchers.any()))
                .thenReturn(null);

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("payoutAmount", new BigDecimal("3000.00"));
        when(settlementDao.calculate(claimId)).thenReturn(daoResult);

        Map<String, Object> result = settlementService.calculateSettlement(claimId);

        assertNotNull(result);
        assertEquals(new BigDecimal("3000.00"), result.get("payoutAmount"));
    }

    @Test
    public void approveSettlement_delegatesToSettlementDaoApprove() {
        Long claimId = 502L;
        String approvedBy = "supervisor1";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("newSettlementId", 900L);
        daoResult.put("errorMessage", null);
        when(settlementDao.approve(claimId, approvedBy)).thenReturn(daoResult);

        Map<String, Object> result = settlementService.approveSettlement(claimId, approvedBy);

        verify(settlementDao).approve(claimId, approvedBy);
        assertEquals(900L, result.get("newSettlementId"));
    }

    @Test
    public void approveSettlement_propagatesFailureForDuplicateSettlement() {
        Long claimId = 503L;
        String approvedBy = "supervisor2";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("newSettlementId", null);
        daoResult.put("errorMessage", "A Settlement already exists for this Claim");
        when(settlementDao.approve(claimId, approvedBy)).thenReturn(daoResult);

        Map<String, Object> result = settlementService.approveSettlement(claimId, approvedBy);

        assertEquals(null, result.get("newSettlementId"));
        assertEquals("A Settlement already exists for this Claim", result.get("errorMessage"));
    }
}
