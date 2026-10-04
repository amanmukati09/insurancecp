package com.icps.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import com.icps.model.Reserve;
import com.icps.model.ReserveHistory;

/**
 * Service interface for calculating and adjusting Reserve amounts
 * (Requirements 5, 4.5).
 *
 * <p><b>Net-paid recomputation note (Requirement 11.6):</b> recomputation of
 * a Claim's net paid amount after a Subrogation_Record recovery is applied
 * is handled transactionally inside the {@code sp_subrogation_record_create}
 * stored procedure, invoked via {@code SubrogationRecordDao.create}. That
 * procedure both inserts the Subrogation_Record and updates
 * {@code claim.net_paid_amount} atomically, so Reserve_Service deliberately
 * does not expose a separate {@code recomputeNetPaid} method here — doing so
 * would duplicate logic that already lives, correctly, at the stored
 * procedure layer (Requirement 15.4, 17.2).</p>
 */
public interface ReserveService {

    /**
     * Validates and persists a Reserve amount change for a Claim, appending
     * a Reserve_History entry on success.
     *
     * @param claimId   the Claim identifier
     * @param amount    the new Reserve amount
     * @param reason    the reason for the change (up to 500 characters)
     * @param changedBy the acting user
     * @return a result map with keys {@code successFlag} ({@link Boolean})
     *         and {@code errorMessage} ({@link String}, {@code null} on
     *         success)
     * @see Requirements 5.1, 5.2, 5.3, 5.4, 5.5
     */
    Map<String, Object> setReserve(Long claimId, BigDecimal amount, String reason, String changedBy);

    /**
     * Recomputes a Claim's recommended Reserve amount as the sum of its
     * Damage_Assessment estimated costs and persists it.
     *
     * @param claimId the Claim identifier
     * @return the new recommended Reserve amount
     * @see Requirements 4.5
     */
    BigDecimal recalculateFromAssessments(Long claimId);

    /**
     * Fetches the current Reserve for a Claim.
     *
     * @param claimId the Claim identifier
     * @return the matching {@link Reserve}, or {@code null} if the Claim has
     *         no Reserve
     */
    Reserve getReserve(Long claimId);

    /**
     * Lists the Reserve_History entries for a Claim's Reserve, most recent
     * change first.
     *
     * @param claimId the Claim identifier
     * @return the Reserve_History entries, or an empty list if the Claim has
     *         no Reserve
     * @see Requirements 5.6
     */
    List<ReserveHistory> getReserveHistory(Long claimId);
}
