package com.icps.controller;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.servlet.ModelAndView;
import com.icps.dao.ClaimDao;
import com.icps.dao.ClaimStatusHistoryDao;
import com.icps.dao.DamageAssessmentDao;
import com.icps.dao.ReserveDao;
import com.icps.dao.ReserveHistoryDao;
import com.icps.exception.NotFoundException;
import com.icps.model.Claim;
import com.icps.service.DocumentMetadataService;
import com.icps.service.LitigationRecordService;
import com.icps.util.ClaimFormatUtil;

/**
 * {@code @Controller} (ModelAndView/JSP, not REST) rendering the claim
 * detail/status view (Requirement 15.5).
 *
 * <p>{@code GET /claims/{claimId}} assembles the Claim together with its
 * current status, Claim_Status_History (most-recent-first, Requirement
 * 6.6), Damage_Assessment records (Requirement 4.2), current Reserve and
 * Reserve_History (most-recent-first, Requirement 5.6), Document_Metadata
 * records or an empty-state indication (Requirement 9.5), and
 * Litigation_Record entries (Requirement 10.4) for display on the
 * {@code claimDetail} JSP view.</p>
 *
 * <p>Uses {@link ClaimFormatUtil#generateClaimReferenceCode(Long)} to
 * derive a human-readable claim reference code, one of this static
 * utility class's required call sites (Requirement 17.3).</p>
 */
@Controller
public class ClaimDetailController {
    private static final String VIEW_NAME = "claimDetail";
    private final ClaimDao claimDao;
    private final ClaimStatusHistoryDao claimStatusHistoryDao;
    private final DamageAssessmentDao damageAssessmentDao;
    private final ReserveDao reserveDao;
    private final ReserveHistoryDao reserveHistoryDao;
    private final DocumentMetadataService documentMetadataService;
    private final LitigationRecordService litigationRecordService;

    @Autowired
    public ClaimDetailController(ClaimDao claimDao,
                                  ClaimStatusHistoryDao claimStatusHistoryDao,
                                  DamageAssessmentDao damageAssessmentDao,
                                  ReserveDao reserveDao,
                                  ReserveHistoryDao reserveHistoryDao,
                                  DocumentMetadataService documentMetadataService,
                                  LitigationRecordService litigationRecordService) {
        this.claimDao = claimDao;
        this.claimStatusHistoryDao = claimStatusHistoryDao;
        this.damageAssessmentDao = damageAssessmentDao;
        this.reserveDao = reserveDao;
        this.reserveHistoryDao = reserveHistoryDao;
        this.documentMetadataService = documentMetadataService;
        this.litigationRecordService = litigationRecordService;
    }

    /**
     * Displays the claim detail/status view for a single Claim.
     *
     * @param claimId the Claim identifier
     * @return a {@link ModelAndView} for the {@code claimDetail} JSP
     * @throws NotFoundException if no Claim with the given id exists
     */
    @GetMapping("/claims/{claimId}")
    public ModelAndView showClaimDetail(@PathVariable Long claimId) {
        Claim claim = claimDao.findById(claimId);
        if (claim == null) {
            throw new NotFoundException("Claim not found: " + claimId);
        }
        ModelAndView mav = new ModelAndView(VIEW_NAME);
        mav.addObject("claim", claim);
        mav.addObject("formattedClaimReference", ClaimFormatUtil.generateClaimReferenceCode(claimId));
        mav.addObject("statusHistory", claimStatusHistoryDao.findByClaim(claimId));
        mav.addObject("damageAssessments", damageAssessmentDao.findByClaim(claimId));
        mav.addObject("reserve", reserveDao.findByClaimId(claimId));
        mav.addObject("reserveHistory", reserveHistoryDao.findByClaimViaReserve(claimId));
        mav.addObject("documents", documentMetadataService.findByClaimId(claimId));
        mav.addObject("litigationRecords", litigationRecordService.findByClaim(claimId));
        return mav;
    }
}
