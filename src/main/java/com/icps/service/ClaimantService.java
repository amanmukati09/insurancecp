package com.icps.service;

import java.util.List;

import com.icps.model.Claimant;

/**
 * Service interface applying Bean Validation and not-found handling around
 * {@link com.icps.dao.ClaimantDao} for use by the REST controllers (task 16).
 *
 * @see Requirements 2.3, 2.4, 2.5
 */
public interface ClaimantService {

    /**
     * Validates and persists a new Claimant.
     *
     * @param claimant the Claimant to create
     * @return the persisted Claimant, including its generated identifier
     * @throws com.icps.exception.ValidationException if any required field is
     *         missing or invalid (Requirement 2.3)
     */
    Claimant create(Claimant claimant);

    /**
     * Validates and persists changes to an existing Claimant.
     *
     * @param id       the Claimant identifier to update
     * @param claimant the new field values
     * @return the persisted Claimant
     * @throws com.icps.exception.NotFoundException   if no Claimant with the
     *         given id exists (Requirement 2.4)
     * @throws com.icps.exception.ValidationException if any required field is
     *         missing or invalid (Requirement 2.3)
     */
    Claimant update(Long id, Claimant claimant);

    /**
     * Fetches a Claimant by identifier.
     *
     * @param id the Claimant identifier
     * @return the matching Claimant
     * @throws com.icps.exception.NotFoundException if no Claimant with the
     *         given id exists (Requirement 2.4)
     */
    Claimant findById(Long id);

    /**
     * Lists all Claimants.
     *
     * @return all Claimant records
     */
    List<Claimant> findAll();

    /**
     * Deletes a Claimant by identifier.
     *
     * @param id the Claimant identifier
     * @throws com.icps.exception.NotFoundException          if no Claimant
     *         with the given id exists (Requirement 2.4)
     * @throws com.icps.exception.ClaimantReferencedException if the Claimant
     *         is referenced by at least one existing Claim (Requirement 2.5)
     */
    void delete(Long id);
}
