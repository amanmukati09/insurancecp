package com.icps.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.servlet.ModelAndView;

import java.util.Collections;

import com.icps.dao.AdjusterDao;
import com.icps.model.Adjuster;
import com.icps.service.ReportingService;

/**
 * {@code @Controller} (ModelAndView/JSP, not REST) rendering the adjuster
 * worklist view (Requirement 15.5).
 *
 * <p>{@code GET /adjusters/{adjusterId}/worklist} lists all Claims
 * currently assigned to the given Adjuster that are not in a Closed
 * status, ordered by Claim age descending (Requirement 3.5, 3.6).</p>
 *
 * <p>If the Adjuster identifier does not resolve to an existing
 * {@link Adjuster}, the view is still rendered with an empty worklist and
 * a model flag ({@code adjusterNotFound}) indicating the Adjuster could
 * not be found, rather than raising an error. The worklist screen is a
 * read-only report view, so a missing Adjuster is treated as "nothing to
 * show" rather than a hard failure.</p>
 */
@Controller
public class AdjusterWorklistController {

    private static final String VIEW_NAME = "adjusterWorklist";

    private final ReportingService reportingService;
    private final AdjusterDao adjusterDao;

    @Autowired
    public AdjusterWorklistController(ReportingService reportingService, AdjusterDao adjusterDao) {
        this.reportingService = reportingService;
        this.adjusterDao = adjusterDao;
    }

    /**
     * Displays the worklist screen for a single Adjuster.
     *
     * @param adjusterId the Adjuster identifier
     * @return a {@link ModelAndView} for the {@code adjusterWorklist} JSP
     */
    @GetMapping("/adjusters/{adjusterId}/worklist")
    public ModelAndView showWorklist(@PathVariable Long adjusterId) {
        ModelAndView mav = new ModelAndView(VIEW_NAME);
        Adjuster adjuster = adjusterDao.findById(adjusterId);
        if (adjuster == null) {
            mav.addObject("adjuster", null);
            mav.addObject("adjusterNotFound", true);
            mav.addObject("worklistClaims", Collections.emptyList());
        } else {
            mav.addObject("adjuster", adjuster);
            mav.addObject("adjusterNotFound", false);
            mav.addObject("worklistClaims", reportingService.getAdjusterWorklist(adjusterId));
        }
        return mav;
    }
}
