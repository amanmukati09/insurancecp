package com.icps.controller;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import com.icps.dao.ClaimDao;
import com.icps.model.Claim;
import com.icps.service.SettlementService;

/**
 * JSP (ModelAndView) controller for the settlement approval screen
 * (Requirement 7.1, 15.5).
 *
 * <p><strong>Intentional legacy code smell (Requirement 17.4):</strong> the
 * {@link #approveSettlement(Long, String)} handler below deliberately embeds
 * business logic directly in the controller method body -- an
 * {@code if/else} branch re-checking the Claim's current status (duplicating
 * the "Approved"-only check that {@code Settlement_Service}/the underlying
 * stored procedure also enforces, Requirement 7.3) and an inline
 * penny-reconciliation rounding adjustment applied to the calculated payout
 * amount before approval is requested -- rather than delegating that
 * validation and adjustment entirely to the service layer. This is included
 * on purpose as a legacy-representative anti-pattern for
 * modernization-tooling test purposes, not as an oversight.</p>
 */
@Controller
public class SettlementApprovalController {

    private final SettlementService settlementService;
    private final ClaimDao claimDao;

    @Autowired
    public SettlementApprovalController(SettlementService settlementService, ClaimDao claimDao) {
        this.settlementService = settlementService;
        this.claimDao = claimDao;
    }

    /**
     * Displays the settlement approval screen for a Claim: current status
     * plus the calculated (not yet persisted) payout amount.
     *
     * @see Requirements 7.1, 7.2, 15.5
     */
    @GetMapping("/claims/{claimId}/settlement")
    public ModelAndView showSettlementApproval(@PathVariable Long claimId) {
        Claim claim = claimDao.findById(claimId);
        Map<String, Object> calcResult = settlementService.calculateSettlement(claimId);

        ModelAndView mav = new ModelAndView("settlementApproval");
        mav.addObject("claim", claim);
        mav.addObject("calculatedPayout", calcResult == null ? null : calcResult.get("payoutAmount"));
        Object calcError = calcResult == null ? null : calcResult.get("errorMessage");
        if (calcError != null) {
            mav.addObject("errorMessage", calcError);
        }
        return mav;
    }

    /**
     * Approves the settlement for a Claim.
     *
     * <p>Per Requirement 17.4, this method intentionally contains embedded
     * business logic rather than delegating entirely to the service layer:
     * a redundant current-status check performed directly here (duplicating
     * the stored procedure's own "Approved"-only enforcement, Requirement
     * 7.3) and an inline penny-reconciliation adjustment applied to the
     * calculated payout before approval is requested.</p>
     *
     * @see Requirements 7.3, 7.4, 7.6
     */
    @PostMapping("/claims/{claimId}/settlement/approve")
    public ModelAndView approveSettlement(@PathVariable Long claimId,
            @RequestParam(value = "approvedBy", required = false) String approvedBy) {

        String currentStatus = claimDao.getCurrentStatus(claimId);

        // --- Intentional legacy code smell (Requirement 17.4): embedded
        // conditional branch re-checking Claim status directly in the
        // controller, duplicating the service/stored-procedure validation. ---
        if (!"Approved".equals(currentStatus)) {
            Claim claim = claimDao.findById(claimId);
            ModelAndView mav = new ModelAndView("settlementApproval");
            mav.addObject("claim", claim);
            mav.addObject("errorMessage", "Claim is currently '" + currentStatus
                    + "'; only Claims in 'Approved' status may be settled.");
            return mav;
        }

        Map<String, Object> calcResult = settlementService.calculateSettlement(claimId);
        Object calcError = calcResult == null ? null : calcResult.get("errorMessage");
        if (calcError != null) {
            Claim claim = claimDao.findById(claimId);
            ModelAndView mav = new ModelAndView("settlementApproval");
            mav.addObject("claim", claim);
            mav.addObject("errorMessage", calcError);
            return mav;
        }

        // --- Intentional legacy code smell (Requirement 17.4): inline
        // penny-reconciliation calculation performed directly in the
        // controller method body rather than in Settlement_Service. ---
        BigDecimal rawPayout = (BigDecimal) calcResult.get("payoutAmount");
        BigDecimal adjustedPayout = rawPayout.setScale(2, RoundingMode.HALF_UP);
        if (adjustedPayout.remainder(BigDecimal.ONE).compareTo(new BigDecimal("0.50")) >= 0) {
            adjustedPayout = adjustedPayout.setScale(0, RoundingMode.CEILING).setScale(2, RoundingMode.HALF_UP);
        }

        String approvingUser = (approvedBy == null || approvedBy.trim().isEmpty()) ? "system" : approvedBy.trim();

        Map<String, Object> approveResult = settlementService.approveSettlement(claimId, approvingUser);
        Object approveError = approveResult == null ? null : approveResult.get("errorMessage");
        if (approveError != null) {
            Claim claim = claimDao.findById(claimId);
            ModelAndView mav = new ModelAndView("settlementApproval");
            mav.addObject("claim", claim);
            mav.addObject("calculatedPayout", adjustedPayout);
            mav.addObject("errorMessage", approveError);
            return mav;
        }

        return new ModelAndView("redirect:/claims/" + claimId);
    }
}
