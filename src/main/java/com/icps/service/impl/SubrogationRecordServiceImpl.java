package com.icps.service.impl;
import java.math.BigDecimal;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.icps.dao.SubrogationRecordDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.SubrogationRecord;
import com.icps.service.SubrogationRecordService;
/**
 * Default {@link SubrogationRecordService} implementation.
 *
 * <p>Performs only a lightweight Java-side sanity check (third-party
 * identifier present, recovery amount present and non-negative). The deeper
 * business validation required by Requirements 11.2-11.5 (Claim status must
 * be "Settled" or "Closed"; recovery amount must be between 0.01 and the
 * Claim's current net paid amount, inclusive) is enforced transactionally
 * inside the {@code sp_subrogation_record_create} stored procedure invoked
 * by {@link SubrogationRecordDao#create}, which reports those failures via
 * the returned map's {@code errorMessage} entry rather than a Java
 * exception.</p>
 */
@Service
public class SubrogationRecordServiceImpl implements SubrogationRecordService {

    private static final Logger LOGGER = LoggerFactory.getLogger(SubrogationRecordServiceImpl.class);

    private final SubrogationRecordDao subrogationRecordDao;

    @Autowired
    public SubrogationRecordServiceImpl(SubrogationRecordDao subrogationRecordDao) {
        this.subrogationRecordDao = subrogationRecordDao;
    }

    @Override
    public Map<String, Object> create(Long claimId, String thirdPartyIdentifier, BigDecimal recoveryAmount,
            Date recordedDate) {
        Map<String, String> fieldErrors = new LinkedHashMap<String, String>();

        if (thirdPartyIdentifier == null || thirdPartyIdentifier.trim().isEmpty()) {
            fieldErrors.put("thirdPartyIdentifier", "Third-party identifier is required");
        }

        if (recoveryAmount == null) {
            fieldErrors.put("recoveryAmount", "Recovery amount is required");
        } else if (recoveryAmount.compareTo(BigDecimal.ZERO) < 0) {
            fieldErrors.put("recoveryAmount", "Recovery amount must not be negative");
        }

        if (!fieldErrors.isEmpty()) {
            LOGGER.warn("Subrogation_Record pre-check failed for claimId={}, errors={}", claimId, fieldErrors);
            throw new ValidationException("Subrogation_Record validation failed", fieldErrors);
        }

        // Deeper business validation (claim status eligibility, 0.01..netPaid range)
        // happens transactionally inside sp_subrogation_record_create; pass the
        // result map straight through (Requirements 11.3, 11.5).
        Map<String, Object> result = subrogationRecordDao.create(claimId, thirdPartyIdentifier, recoveryAmount,
                recordedDate);
        Object errorMessage = result == null ? null : result.get("errorMessage");
        if (errorMessage != null) {
            LOGGER.warn("Subrogation_Record creation rejected for claimId={}, errorMessage={}", claimId,
                    errorMessage);
        } else {
            LOGGER.info("Subrogation_Record created for claimId={}, newId={}", claimId,
                    result == null ? null : result.get("newId"));
        }
        return result;
    }

    @Override
    public List<SubrogationRecord> findByClaim(Long claimId) {
        return subrogationRecordDao.findByClaim(claimId);
    }

    @Override
    public SubrogationRecord findById(Long id) {
        SubrogationRecord subrogationRecord = subrogationRecordDao.findById(id);
        if (subrogationRecord == null) {
            throw new NotFoundException("Subrogation_Record not found for id " + id);
        }
        return subrogationRecord;
    }
}
