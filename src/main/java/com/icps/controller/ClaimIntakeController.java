package com.icps.controller;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.ModelAndView;

import com.icps.dao.ClaimantDao;
import com.icps.dao.PolicyReferenceDao;
import com.icps.dto.FnolFormDto;
import com.icps.model.Claimant;
import com.icps.model.PolicyReference;
import com.icps.service.ClaimsLifecycleService;

/**
 * {@code @Controller} (ModelAndView/JSP, not REST) rendering the claim
 * intake (FNOL) form and handling its submission (Requirement 1.1, 15.5).
 *
 * <p>{@code GET /claims/new} displays an empty form with claimant and
 * Policy_Reference dropdowns. {@code POST /claims/new} performs basic
 * presence validation on required fields (Requirement 1.4); if all
 * required fields are present it delegates to
 * {@link ClaimsLifecycleService#createClaim} which performs the
 * authoritative Policy_Reference resolution and loss-date validation
 * (Requirement 1.5). On success the user is redirected to the claim
 * detail/status view (Requirement 1.6).</p>
 */
@Controller
public class ClaimIntakeController {

    private static final String VIEW_NAME = "claimIntakeForm";
    private static final String LOSS_DATE_PATTERN = "yyyy-MM-dd";

    private final ClaimsLifecycleService claimsLifecycleService;
    private final ClaimantDao claimantDao;
    private final PolicyReferenceDao policyReferenceDao;

    @Autowired
    public ClaimIntakeController(ClaimsLifecycleService claimsLifecycleService,
                                  ClaimantDao claimantDao,
                                  PolicyReferenceDao policyReferenceDao) {
        this.claimsLifecycleService = claimsLifecycleService;
        this.claimantDao = claimantDao;
        this.policyReferenceDao = policyReferenceDao;
    }

    /**
     * Displays the empty claim intake form.
     *
     * @return a {@link ModelAndView} for the {@code claimIntakeForm} JSP
     *         with an empty {@code fnolForm} and populated claimant/
     *         Policy_Reference dropdown lists
     */
    @GetMapping("/claims/new")
    public ModelAndView showIntakeForm() {
        ModelAndView mav = new ModelAndView(VIEW_NAME);
        mav.addObject("fnolForm", new FnolFormDto());
        mav.addObject("claimants", claimantDao.findAll());
        mav.addObject("policyReferences", policyReferenceDao.findAll());
        return mav;
    }

    /**
     * Handles FNOL form submission.
     *
     * <p>Missing required fields redisplay the form with the submitted
     * values retained and field-specific error messages (Requirement 1.4).
     * An unresolvable Policy_Reference (or other service-level rejection,
     * Requirement 1.5) also redisplays the form with an error message. On
     * success the browser is redirected to the newly created Claim's
     * detail/status view (Requirement 1.6).</p>
     *
     * @param fnolForm the submitted form values
     * @return a {@link ModelAndView}, either redisplaying the form or
     *         redirecting to the claim detail view
     */
    @PostMapping("/claims/new")
    public ModelAndView submitIntakeForm(@ModelAttribute("fnolForm") FnolFormDto fnolForm) {
        Map<String, String> fieldErrors = new HashMap<String, String>();

        if (fnolForm.getClaimantId() == null) {
            fieldErrors.put("claimantId", "Claimant is required");
        }
        if (fnolForm.getPolicyReferenceId() == null) {
            fieldErrors.put("policyReferenceId", "Policy reference is required");
        }
        if (fnolForm.getLossDate() == null || fnolForm.getLossDate().trim().isEmpty()) {
            fieldErrors.put("lossDate", "Loss date is required");
        }
        if (fnolForm.getLossDescription() == null || fnolForm.getLossDescription().trim().isEmpty()) {
            fieldErrors.put("lossDescription", "Loss description is required");
        }

        if (!fieldErrors.isEmpty()) {
            return redisplayForm(fnolForm, fieldErrors, null);
        }

        Date parsedLossDate;
        try {
            SimpleDateFormat dateFormat = new SimpleDateFormat(LOSS_DATE_PATTERN);
            dateFormat.setLenient(false);
            parsedLossDate = dateFormat.parse(fnolForm.getLossDate().trim());
        } catch (ParseException e) {
            fieldErrors.put("lossDate", "Loss date must be a valid date in yyyy-MM-dd format");
            return redisplayForm(fnolForm, fieldErrors, null);
        }

        Map<String, Object> result = claimsLifecycleService.createClaim(
                fnolForm.getClaimantId(),
                fnolForm.getPolicyReferenceId(),
                parsedLossDate,
                fnolForm.getLossDescription());

        String errorMessage = (String) result.get("errorMessage");
        if (errorMessage != null) {
            return redisplayForm(fnolForm, fieldErrors, errorMessage);
        }

        Long claimId = (Long) result.get("claimId");
        return new ModelAndView("redirect:/claims/" + claimId);
    }

    /**
     * Redisplays the claim intake form, retaining submitted values and
     * re-populating the claimant/Policy_Reference dropdowns.
     *
     * @param fnolForm     the previously submitted form values to retain
     * @param fieldErrors  field name to validation message map (may be empty)
     * @param errorMessage a general (non-field-specific) error message, or
     *                     {@code null} if none
     * @return a {@link ModelAndView} for the {@code claimIntakeForm} JSP
     */
    private ModelAndView redisplayForm(FnolFormDto fnolForm, Map<String, String> fieldErrors, String errorMessage) {
        ModelAndView mav = new ModelAndView(VIEW_NAME);
        mav.addObject("fnolForm", fnolForm);
        List<Claimant> claimants = claimantDao.findAll();
        List<PolicyReference> policyReferences = policyReferenceDao.findAll();
        mav.addObject("claimants", claimants);
        mav.addObject("policyReferences", policyReferences);
        mav.addObject("fieldErrors", fieldErrors);
        if (errorMessage != null) {
            mav.addObject("errorMessage", errorMessage);
        }
        return mav;
    }
}
