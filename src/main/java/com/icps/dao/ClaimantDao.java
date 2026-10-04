package com.icps.dao;
import java.util.List;
import com.icps.model.Claimant;
/**
 * DAO interface for {@link Claimant} persistence.
 *
 * Claimant is one of the three Hibernate-backed reference entities
 * (Requirement 15.3, 17.1). The implementation ({@code HibernateClaimantDao})
 * uses the shared {@code SessionFactory} for all operations.
 */
public interface ClaimantDao {
    Claimant save(Claimant claimant);
    Claimant findById(Long id);
    List<Claimant> findAll();
    void delete(Long id);
    List<Claimant> findByState(String state);

    /**
     * Checks whether the given Claimant is referenced by at least one
     * existing Claim, via the stored procedure {@code sp_claimant_has_claims}.
     * Backs the delete-guard required by Requirement 2.5.
     */
    boolean hasClaims(Long claimantId);
}
