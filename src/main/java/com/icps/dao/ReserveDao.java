package com.icps.dao;

import java.math.BigDecimal;
import java.util.Map;

import com.icps.model.Reserve;

/**
 * DAO interface for {@link Reserve} persistence.
 *
 * Reserve is one of the ten {@code SimpleJdbcCall}-backed entities
 * (Requirement 15.3). Simple reads go through the plain CRUD procedures in
 * {@code 12_sp_crud_damage_reserve.sql}; the business-rule-heavy amount
 * change and recommended-amount recalculation go through the transactional
 * lifecycle procedures in {@code 23_sp_lifecycle_reserve_settlement.sql}
 * (Requirement 15.4, 17.2) — no inline business SQL is used.
 */
public interface ReserveDao {

    /**
     * Fetches the (at most one) Reserve row for a Claim via
     * {@code sp_reserve_find_by_claim}.
     *
     * @return the matching {@link Reserve}, or {@code null} if the Claim has no Reserve
     */
    Reserve findByClaimId(Long claimId);

    /**
     * Validates and persists a Reserve amount change for a Claim via the
     * transactional {@code sp_reserve_set_amount} procedure, which also
     * appends a Reserve_History row on success (Requirement 5.4) and enforces
     * the settlement-floor check (Requirement 5.5).
     *
     * @return a result map with keys {@code successFlag} ({@link Boolean}) and
     *         {@code errorMessage} ({@link String}, {@code null} on success)
     */
    Map<String, Object> setAmount(Long claimId, BigDecimal newAmount, String reason, String changedBy);

    /**
     * Recomputes a Claim's recommended Reserve amount as the sum of its
     * Damage_Assessment estimated costs via the composed
     * {@code sp_reserve_recalculate_from_assessments} procedure (which in turn
     * calls {@code sp_da_sum_by_claim}), persists it, and returns the new
     * recommended amount (Requirement 4.5).
     */
    BigDecimal recalculateFromAssessments(Long claimId);
}
