package com.icps.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import com.icps.dao.DamageAssessmentDao;
import com.icps.dao.ReserveDao;
import com.icps.dao.ReserveHistoryDao;
import com.icps.model.Reserve;
import com.icps.model.ReserveHistory;
import com.icps.service.impl.ReserveServiceImpl;

/**
 * Unit tests for {@link ReserveServiceImpl} covering reserve adjustment
 * logic delegation to {@link ReserveDao}/{@link ReserveHistoryDao}.
 *
 * Satisfies Requirement 18.5 (reserve adjustment logic coverage) and
 * documents Requirements 4.5, 5.1-5.5, 11.6.
 */
@RunWith(MockitoJUnitRunner.class)
public class ReserveServiceTest {

    @Mock
    private ReserveDao reserveDao;

    @Mock
    private ReserveHistoryDao reserveHistoryDao;

    @Mock
    private DamageAssessmentDao damageAssessmentDao;

    private ReserveService reserveService;

    @Before
    public void setUp() {
        reserveService = new ReserveServiceImpl(reserveDao, reserveHistoryDao, damageAssessmentDao);
    }

    @Test
    public void setReserve_delegatesToReserveDaoSetAmountAndReturnsResult() {
        Long claimId = 100L;
        BigDecimal amount = new BigDecimal("5000.00");
        String reason = "Updated estimate after inspection";
        String changedBy = "adjuster1";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("successFlag", true);
        daoResult.put("errorMessage", null);
        when(reserveDao.setAmount(claimId, amount, reason, changedBy)).thenReturn(daoResult);

        Map<String, Object> result = reserveService.setReserve(claimId, amount, reason, changedBy);

        verify(reserveDao).setAmount(claimId, amount, reason, changedBy);
        assertEquals(Boolean.TRUE, result.get("successFlag"));
    }

    @Test
    public void setReserve_propagatesFailureResultForInvalidAmount() {
        Long claimId = 101L;
        BigDecimal amount = new BigDecimal("-1.00");
        String reason = "Invalid negative amount";
        String changedBy = "adjuster2";

        Map<String, Object> daoResult = new HashMap<>();
        daoResult.put("successFlag", false);
        daoResult.put("errorMessage", "Reserve amount must be non-negative");
        when(reserveDao.setAmount(claimId, amount, reason, changedBy)).thenReturn(daoResult);

        Map<String, Object> result = reserveService.setReserve(claimId, amount, reason, changedBy);

        assertFalse((Boolean) result.get("successFlag"));
        assertEquals("Reserve amount must be non-negative", result.get("errorMessage"));
    }

    @Test
    public void recalculateFromAssessments_delegatesToReserveDao() {
        Long claimId = 102L;
        BigDecimal recommendedAmount = new BigDecimal("7500.50");
        when(reserveDao.recalculateFromAssessments(claimId)).thenReturn(recommendedAmount);

        BigDecimal result = reserveService.recalculateFromAssessments(claimId);

        verify(reserveDao).recalculateFromAssessments(claimId);
        assertEquals(recommendedAmount, result);
    }

    @Test
    public void getReserve_delegatesToReserveDaoFindByClaimId() {
        Long claimId = 103L;
        Reserve reserve = new Reserve();
        reserve.setClaimId(claimId);
        reserve.setCurrentAmount(new BigDecimal("2500.00"));
        when(reserveDao.findByClaimId(claimId)).thenReturn(reserve);

        Reserve result = reserveService.getReserve(claimId);

        verify(reserveDao).findByClaimId(claimId);
        assertNotNull(result);
        assertEquals(claimId, result.getClaimId());
    }

    @Test
    public void getReserveHistory_delegatesToReserveHistoryDaoFindByClaimViaReserve() {
        Long claimId = 104L;
        ReserveHistory history1 = new ReserveHistory();
        ReserveHistory history2 = new ReserveHistory();
        List<ReserveHistory> historyList = Arrays.asList(history1, history2);
        when(reserveHistoryDao.findByClaimViaReserve(claimId)).thenReturn(historyList);

        List<ReserveHistory> result = reserveService.getReserveHistory(claimId);

        verify(reserveHistoryDao).findByClaimViaReserve(claimId);
        assertEquals(2, result.size());
    }
}
