package com.icps.service.impl;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.icps.dao.LitigationRecordDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.LitigationRecord;
import com.icps.service.LitigationRecordService;
/**
 * Default {@link LitigationRecordService} implementation.
 *
 * <p>Enforces the Requirement 10.2/10.3 field validation rules in Java
 * before delegating to the {@code SimpleJdbcCall}-backed
 * {@link LitigationRecordDao}.</p>
 */
@Service
public class LitigationRecordServiceImpl implements LitigationRecordService {

    private static final Logger LOGGER = LoggerFactory.getLogger(LitigationRecordServiceImpl.class);
    private static final int MAX_CASE_REFERENCE_LENGTH = 100;

    private final LitigationRecordDao litigationRecordDao;

    @Autowired
    public LitigationRecordServiceImpl(LitigationRecordDao litigationRecordDao) {
        this.litigationRecordDao = litigationRecordDao;
    }

    @Override
    public Long create(Long claimId, String caseReference, Date filingDate, String status, String attorneyName) {
        Map<String, String> fieldErrors = new LinkedHashMap<String, String>();

        if (caseReference == null || caseReference.trim().isEmpty()) {
            fieldErrors.put("caseReference", "Case reference is required");
        } else if (caseReference.length() > MAX_CASE_REFERENCE_LENGTH) {
            fieldErrors.put("caseReference", "Case reference must not exceed " + MAX_CASE_REFERENCE_LENGTH
                    + " characters");
        }

        if (filingDate == null) {
            fieldErrors.put("filingDate", "Filing date is required");
        }

        if (!fieldErrors.isEmpty()) {
            LOGGER.warn("Litigation_Record validation failed for claimId={}, errors={}", claimId, fieldErrors);
            throw new ValidationException("Litigation_Record validation failed", fieldErrors);
        }

        Long newId = litigationRecordDao.create(claimId, caseReference, filingDate, status, attorneyName);
        LOGGER.info("Litigation_Record created with id={} for claimId={}", newId, claimId);
        return newId;
    }

    @Override
    public List<LitigationRecord> findByClaim(Long claimId) {
        return litigationRecordDao.findByClaim(claimId);
    }

    @Override
    public LitigationRecord findById(Long id) {
        LitigationRecord litigationRecord = litigationRecordDao.findById(id);
        if (litigationRecord == null) {
            throw new NotFoundException("Litigation_Record not found for id " + id);
        }
        return litigationRecord;
    }
}
