package com.icps.controller;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.exception.NotFoundException;
import com.icps.model.Reserve;
import com.icps.model.ReserveHistory;
import com.icps.service.ReserveService;

/**
 * REST JSON controller exposing read and set/adjust operations for
 * {@link Reserve} and its {@link ReserveHistory} audit trail (Requirement 5).
 *
 * <p>All operations delegate to {@link ReserveService}, which enforces the
 * Requirement 5.1/5.2 amount validation and the Requirement 5.5
 * settlement-floor check inside the transactional {@code sp_reserve_set_amount}
 * stored procedure. Validation/business-rule failures are surfaced as a
 * {@code successFlag=false} result map rather than a thrown exception, so
 * this controller translates that into an HTTP 400 (validation) or 409
 * (settlement-floor conflict) response.</p>
 *
 * @see Requirements 5.1, 5.4, 5.6, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/reserve")
public class ReserveRestController {

    @Resource
    private ReserveService reserveService;

    /**
     * Reads the current Reserve for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's current Reserve
     * @throws NotFoundException if the Claim has no Reserve
     */
    @GetMapping
    public Reserve getReserve(@PathVariable Long claimId) {
        Reserve reserve = reserveService.getReserve(claimId);
        if (reserve == null) {
            throw new NotFoundException("Reserve not found for claim: " + claimId);
        }
        return reserve;
    }

    /**
     * Lists the Reserve_History entries for a Claim's Reserve, most recent
     * change first (Requirement 5.6).
     *
     * @param claimId the Claim identifier
     * @return the Reserve_History entries, or an empty list if the Claim has
     *         no Reserve
     */
    @GetMapping("/history")
    public List<ReserveHistory> getReserveHistory(@PathVariable Long claimId) {
        return reserveService.getReserveHistory(claimId);
    }

    /**
     * Sets or adjusts the Reserve amount for a Claim.
     *
     * <p>Validates the amount (numeric, greater than 0.00, not exceeding
     * 999,999,999.99, up to 2 decimal places — Requirement 5.1) and the
     * settlement floor (Requirement 5.5) via {@link ReserveService#setReserve}.
     * A validation failure yields HTTP 400; a settlement-floor rejection
     * yields HTTP 409, both carrying the service's error message.</p>
     *
     * @param claimId the Claim identifier
     * @param request the request payload (amount, reason, changedBy)
     * @return the updated Reserve on success
     */
    @PutMapping
    public ResponseEntity<?> setReserve(@PathVariable Long claimId, @RequestBody ReserveChangeRequest request) {
        Map<String, Object> result = reserveService.setReserve(
                claimId, request.getAmount(), request.getReason(), request.getChangedBy());
        Boolean success = (Boolean) result.get("successFlag");
        if (success == null || !success) {
            String errorMessage = (String) result.get("errorMessage");
            HttpStatus status = (errorMessage != null && errorMessage.toLowerCase().contains("minimum"))
                    ? HttpStatus.CONFLICT
                    : HttpStatus.BAD_REQUEST;
            return ResponseEntity.status(status).body(result);
        }
        return ResponseEntity.ok(reserveService.getReserve(claimId));
    }

    /**
     * Request payload for {@link #setReserve}.
     */
    public static class ReserveChangeRequest {
        private BigDecimal amount;
        private String reason;
        private String changedBy;

        public BigDecimal getAmount() {
            return amount;
        }

        public void setAmount(BigDecimal amount) {
            this.amount = amount;
        }

        public String getReason() {
            return reason;
        }

        public void setReason(String reason) {
            this.reason = reason;
        }

        public String getChangedBy() {
            return changedBy;
        }

        public void setChangedBy(String changedBy) {
            this.changedBy = changedBy;
        }
    }
}
