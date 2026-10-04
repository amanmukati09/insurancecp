package com.icps.service.impl;

import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.icps.dao.ReportingDao;
import com.icps.service.ReportingService;

/**
 * {@code @Service} implementation of {@link ReportingService}.
 *
 * Each method is a straight delegation to the corresponding
 * {@link ReportingDao} method -- per design.md, no aggregation logic lives
 * in Java; all computation happens in the reporting stored procedures
 * (Requirement 13).
 */
@Service
public class ReportingServiceImpl implements ReportingService {

    private static final Logger LOG = LoggerFactory.getLogger(ReportingServiceImpl.class);

    @Autowired
    private ReportingDao reportingDao;

    @Override
    public List<Map<String, Object>> getAdjusterWorklist(Long adjusterId) {
        List<Map<String, Object>> rows = reportingDao.getAdjusterWorklist(adjusterId);
        LOG.debug("adjuster-worklist report returned {} row(s) for adjusterId={}", rows.size(), adjusterId);
        return rows;
    }

    @Override
    public List<Map<String, Object>> getAdjusterCaseload() {
        List<Map<String, Object>> rows = reportingDao.getAdjusterCaseload();
        LOG.debug("adjuster-caseload report returned {} row(s)", rows.size());
        return rows;
    }

    @Override
    public List<Map<String, Object>> getAgingReport() {
        List<Map<String, Object>> rows = reportingDao.getClaimsAging();
        LOG.debug("claims-aging report returned {} row(s)", rows.size());
        return rows;
    }

    @Override
    public List<Map<String, Object>> getReserveAdequacy() {
        List<Map<String, Object>> rows = reportingDao.getReserveAdequacy();
        LOG.debug("reserve-adequacy report returned {} row(s)", rows.size());
        return rows;
    }

    @Override
    public List<Map<String, Object>> getFraudSummary() {
        List<Map<String, Object>> rows = reportingDao.getFraudSummary();
        LOG.debug("fraud-summary report returned {} row(s)", rows.size());
        return rows;
    }

    @Override
    public List<Map<String, Object>> getSubrogationReport() {
        List<Map<String, Object>> rows = reportingDao.getSubrogationTracking();
        LOG.debug("subrogation-tracking report returned {} row(s)", rows.size());
        return rows;
    }
}
