package com.icps.controller;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.dao.ReportingDao;
/**
 * REST JSON controller exposing the cross-claim subrogation recovery
 * tracking report (Requirement 11.7).
 *
 * <p>Kept separate from {@link SubrogationRecordRestController} because
 * this endpoint is not scoped to a single Claim
 * ({@code /api/claims/{claimId}/...}) -- it spans every Claim with
 * Subrogation_Record entries. Delegates directly to
 * {@link ReportingDao#getSubrogationTracking()}, which is backed by the
 * {@code sp_report_subrogation_tracking} stored procedure with no
 * aggregation logic in Java (Requirement 13.5, 15.4). Mirrors the pattern
 * used by {@code FraudSummaryReportController} and will be joined by the
 * other cross-cutting reporting endpoints added in task 17.5's
 * {@code ReportingRestController}.</p>
 *
 * @see Requirements 11.7, 15.6
 */
@RestController
@RequestMapping("/api/reports")
public class SubrogationReportController {
    @Resource
    private ReportingDao reportingDao;
    /**
     * Subrogation recovery tracking report across all Claims with
     * Subrogation_Record entries.
     *
     * @return the subrogation tracking report rows (Claim identifier,
     *         third-party identifier, recovery amount, date recorded, and
     *         the Claim's net paid amount after recovery), or an empty list
     *         if no Claims have Subrogation_Record entries (Requirement
     *         13.6)
     */
    @GetMapping("/subrogation")
    public List<Map<String, Object>> getSubrogationTrackingReport() {
        return reportingDao.getSubrogationTracking();
    }
}
