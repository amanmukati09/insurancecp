package com.icps.service.impl;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.icps.dao.DamageAssessmentDao;
import com.icps.dao.ReserveDao;
import com.icps.dao.ReserveHistoryDao;
import com.icps.model.Reserve;
import com.icps.model.ReserveHistory;
import com.icps.service.ReserveService;

/**
 * Default {@link ReserveService} implementation.
 *
 * <p>Delegates all validation and business logic to the underlying
 * {@code SimpleJdbcCall}-backed DAOs, whose stored procedures already
 * enforce the Requirement 5 reserve-amount rules (numeric range validation,
 * the settlement-floor check) and the Requirement 4.5 recalculation
 * composition. This service exists to give the controller/web layer a
 * single, Spring-managed entry point and to add application-level logging
 * around those operations (Requirement 15.3, 17.2).</p>
 */
@Service
public class ReserveServiceImpl implements ReserveService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ReserveServiceImpl.class);

    private final ReserveDao reserveDao;
    private final ReserveHistoryDao reserveHistoryDao;
    private final DamageAssessmentDao damageAssessmentDao;

    @Autowired
    public ReserveServiceImpl(ReserveDao reserveDao, ReserveHistoryDao reserveHistoryDao,
            DamageAssessmentDao damageAssessmentDao) {
        this.reserveDao = reserveDao;
        this.reserveHistoryDao = reserveHistoryDao;
        this.damageAssessmentDao = damageAssessmentDao;
    }

    @Override
    public Map<String, Object> setReserve(Long claimId, BigDecimal amount, String reason, String changedBy) {
        LOGGER.info("Reserve set attempted for claimId={}, amount={}, changedBy={}", claimId, amount, changedBy);
        Map<String, Object> result = reserveDao.setAmount(claimId, amount, reason, changedBy);
        Boolean successFlag = result == null ? null : (Boolean) result.get("successFlag");
        if (Boolean.TRUE.equals(successFlag)) {
            LOGGER.info("Reserve set succeeded for claimId={}, newAmount={}", claimId, amount);
        } else {
            Object errorMessage = result == null ? null : result.get("errorMessage");
            LOGGER.warn("Reserve set failed for claimId={}, amount={}, errorMessage={}", claimId, amount,
                    errorMessage);
        }
        return result;
    }

    @Override
    public BigDecimal recalculateFromAssessments(Long claimId) {
        LOGGER.info("Recalculating recommended reserve from damage assessments for claimId={}", claimId);
        BigDecimal recommendedAmount = reserveDao.recalculateFromAssessments(claimId);
        LOGGER.info("Recalculated recommended reserve for claimId={} to {}", claimId, recommendedAmount);
        return recommendedAmount;
    }

    @Override
    public Reserve getReserve(Long claimId) {
        return reserveDao.findByClaimId(claimId);
    }

    @Override
    public List<ReserveHistory> getReserveHistory(Long claimId) {
        List<ReserveHistory> history = reserveHistoryDao.findByClaimViaReserve(claimId);
        return history == null ? Collections.emptyList() : history;
    }
}
