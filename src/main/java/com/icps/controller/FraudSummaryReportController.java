package com.icps.controller;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.dao.ReportingDao;

/**
 * REST JSON controller exposing the cross-claim fraud flag summary report
 * (Requirement 8.6).
 *
 * <p>Kept separate from {@link FraudFlagRestController} because this
 * endpoint is not scoped to a single Claim ({@code /api/claims/{claimId}/...})
 * -- it spans every flagged Claim. Delegates directly to
 * {@link ReportingDao#getFraudSummary()}, which is backed by the
 * {@code sp_report_fraud_summary} stored procedure with no aggregation
 * logic in Java (Requirement 13, 15.4). This endpoint will be joined by the
 * other cross-cutting reporting endpoints added in task 17.5's
 * {@code ReportingRestController}.</p>
 *
 * @see Requirements 8.6, 15.6
 */
@RestController
@RequestMapping("/api/reports")
public class FraudSummaryReportController {

    @Resource
    private ReportingDao reportingDao;

    /**
     * Fraud flag summary report across all flagged Claims.
     *
     * @return the fraud summary report rows (Claim identifier, current
     *         fraud score, "Under Fraud Review" indicator, and active
     *         Fraud_Flag count per Claim), or an empty list if no Claims
     *         are flagged (Requirement 13.6)
     */
    @GetMapping("/fraud-summary")
    public List<Map<String, Object>> getFraudSummaryReport() {
        return reportingDao.getFraudSummary();
    }
}
