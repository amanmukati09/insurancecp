package com.icps.service.impl;

import java.util.Date;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.icps.dao.ClaimDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.model.Claim;
import com.icps.service.ClaimsLifecycleService;
import com.icps.util.ClaimFormatUtil;

/**
 * Default {@link ClaimsLifecycleService} implementation.
 *
 * <p>Delegates all validation and business logic (Policy_Reference
 * resolution, loss-date range checking, allowed-transition graph,
 * optimistic concurrency, inactive adjuster rejection) to the underlying
 * {@code SimpleJdbcCall}-backed {@link ClaimDao}, whose stored procedures
 * already enforce those rules. This service exists to give the
 * controller/web layer a single, Spring-managed entry point and to add
 * application-level logging around those operations (Requirement 15.3,
 * 17.2).</p>
 */
@Service
public class ClaimsLifecycleServiceImpl implements ClaimsLifecycleService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ClaimsLifecycleServiceImpl.class);

    private final ClaimDao claimDao;
    private final PolicyReferenceDao policyReferenceDao;

    @Autowired
    public ClaimsLifecycleServiceImpl(ClaimDao claimDao, PolicyReferenceDao policyReferenceDao) {
        this.claimDao = claimDao;
        this.policyReferenceDao = policyReferenceDao;
    }

    @Override
    public Map<String, Object> createClaim(Long claimantId, Long policyReferenceId, Date lossDate,
            String lossDescription) {
        LOGGER.info("FNOL claim creation attempted for claimantId={}, policyReferenceId={}, lossDate={}",
                claimantId, policyReferenceId, lossDate);

        Map<String, Object> result = claimDao.createClaimWithFnol(claimantId, policyReferenceId, lossDate,
                lossDescription);

        Long newClaimId = result == null ? null : (Long) result.get("newClaimId");
        if (newClaimId != null) {
            String claimReferenceCode = ClaimFormatUtil.generateClaimReferenceCode(newClaimId);
            LOGGER.info("FNOL claim created successfully: claimId={}, claimReferenceCode={}", newClaimId,
                    claimReferenceCode);
        } else {
            Object errorMessage = result == null ? null : result.get("errorMessage");
            LOGGER.warn("FNOL claim creation failed for claimantId={}, policyReferenceId={}, errorMessage={}",
                    claimantId, policyReferenceId, errorMessage);
        }

        // Normalize the result map key to "claimId" for callers of this service,
        // while preserving the DAO's own result contents.
        if (result != null && result.containsKey("newClaimId")) {
            result.put("claimId", result.get("newClaimId"));
        }
        return result;
    }

    @Override
    public Map<String, Object> transitionStatus(Long claimId, String newStatus, String changedBy,
            Integer expectedVersion) {
        LOGGER.info("Status transition attempted for claimId={}, newStatus={}, changedBy={}, expectedVersion={}",
                claimId, newStatus, changedBy, expectedVersion);

        Map<String, Object> result = claimDao.transitionStatus(claimId, newStatus, changedBy, expectedVersion);

        Boolean successFlag = result == null ? null : (Boolean) result.get("successFlag");
        if (Boolean.TRUE.equals(successFlag)) {
            LOGGER.info("Status transition succeeded for claimId={}, newStatus={}", claimId, newStatus);
        } else {
            Object errorMessage = result == null ? null : result.get("errorMessage");
            LOGGER.warn("Status transition failed for claimId={}, newStatus={}, errorMessage={}", claimId,
                    newStatus, errorMessage);
        }
        return result;
    }

    @Override
    public Map<String, Object> assignAdjuster(Long claimId, Long newAdjusterId, String changedBy) {
        LOGGER.info("Adjuster assignment attempted for claimId={}, newAdjusterId={}, changedBy={}", claimId,
                newAdjusterId, changedBy);

        Map<String, Object> result = claimDao.assignAdjuster(claimId, newAdjusterId, changedBy);

        Boolean successFlag = result == null ? null : (Boolean) result.get("successFlag");
        if (Boolean.TRUE.equals(successFlag)) {
            LOGGER.info("Adjuster assignment succeeded for claimId={}, newAdjusterId={}", claimId, newAdjusterId);
        } else {
            Object errorMessage = result == null ? null : result.get("errorMessage");
            LOGGER.warn("Adjuster assignment failed for claimId={}, newAdjusterId={}, errorMessage={}", claimId,
                    newAdjusterId, errorMessage);
        }
        return result;
    }

    @Override
    public Claim getClaimById(Long claimId) {
        return claimDao.findById(claimId);
    }
}
