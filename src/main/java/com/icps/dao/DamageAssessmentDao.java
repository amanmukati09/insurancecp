package com.icps.dao;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

import com.icps.model.DamageAssessment;

/**
 * DAO interface for {@link DamageAssessment} persistence.
 *
 * Damage_Assessment is one of the ten {@code SimpleJdbcCall}-backed entities
 * (Requirement 15.3). All operations are implemented purely in terms of the
 * stored procedures defined in {@code 12_sp_crud_damage_reserve.sql}
 * ({@code sp_da_create}, {@code sp_da_read}, {@code sp_da_update},
 * {@code sp_da_delete}, {@code sp_da_list_by_claim}, {@code sp_da_sum_by_claim})
 * — no inline business SQL is used (Requirement 15.4, 17.2).
 */
public interface DamageAssessmentDao {

    /**
     * Inserts a new Damage_Assessment row for a Claim via {@code sp_da_create}.
     *
     * @return the generated {@code damage_assessment_id}
     */
    Long create(Long claimId, BigDecimal estimatedCost, String description, Date assessmentDate);

    /**
     * Fetches a single Damage_Assessment by id via {@code sp_da_read}.
     *
     * @return the matching {@link DamageAssessment}, or {@code null} if not found
     */
    DamageAssessment findById(Long id);

    /**
     * Lists all Damage_Assessment rows for a Claim via {@code sp_da_list_by_claim},
     * most recent assessment date first.
     */
    List<DamageAssessment> findByClaim(Long claimId);

    /** Updates the mutable fields of a Damage_Assessment via {@code sp_da_update}. */
    void update(Long id, BigDecimal estimatedCost, String description, Date assessmentDate);

    /** Deletes a Damage_Assessment by id via {@code sp_da_delete}. */
    void delete(Long id);

    /**
     * Sums {@code estimated_cost} across a Claim's Damage_Assessment rows via
     * {@code sp_da_sum_by_claim}. Returns {@code 0.00} (never {@code null}) when
     * the Claim has no Damage_Assessment rows.
     */
    BigDecimal sumByClaim(Long claimId);
}
