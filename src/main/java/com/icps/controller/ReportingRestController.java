package com.icps.controller;

import java.util.Date;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.icps.service.ReportingService;
import com.icps.util.ClaimFormatUtil;

/**
 * REST JSON endpoints for the claims reporting surface (Requirement 13).
 *
 * Each endpoint delegates directly to {@link ReportingService}, which in
 * turn delegates to a stored-procedure-backed {@code ReportingDao} method
 * -- no aggregation logic lives in this controller or in Java generally,
 * per design.md's Reporting_Service component description.
 *
 * Note: {@code /api/reports/fraud-summary} and {@code /api/reports/subrogation}
 * are implemented by separate controllers ({@code FraudSummaryReportController},
 * {@code SubrogationReportController}) added alongside their respective entity
 * controllers in tasks 17.1/17.4, so they are intentionally not duplicated here.
 */
@RestController
@RequestMapping("/api/reports")
public class ReportingRestController {

    private static final Logger LOGGER = LoggerFactory.getLogger(ReportingRestController.class);

    @Resource
    private ReportingService reportingService;

    /**
     * Requirement 13.1: adjuster caseload report. Returns an empty list
     * (not an error) when no Claims match, per Requirement 13.6.
     */
    @GetMapping("/adjuster-caseload")
    public List<Map<String, Object>> getAdjusterCaseload() {
        LOGGER.info("Adjuster caseload report requested at {}", ClaimFormatUtil.formatDateTime(new Date()));
        return reportingService.getAdjusterCaseload();
    }

    /**
     * Requirement 13.2: claims aging report, bucketed by elapsed time since
     * FNOL. Returns an empty list (not an error) when no Claims match, per
     * Requirement 13.6.
     */
    @GetMapping("/claims-aging")
    public List<Map<String, Object>> getClaimsAging() {
        LOGGER.info("Claims aging report requested at {}", ClaimFormatUtil.formatDateTime(new Date()));
        return reportingService.getAgingReport();
    }

    /**
     * Requirement 13.3: reserve adequacy report, comparing current Reserve
     * amounts against Damage_Assessment totals. Returns an empty list (not
     * an error) when no Claims match, per Requirement 13.6.
     */
    @GetMapping("/reserve-adequacy")
    public List<Map<String, Object>> getReserveAdequacy() {
        LOGGER.info("Reserve adequacy report requested at {}", ClaimFormatUtil.formatDateTime(new Date()));
        return reportingService.getReserveAdequacy();
    }
}