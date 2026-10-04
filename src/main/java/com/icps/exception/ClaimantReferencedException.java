package com.icps.exception;

/**
 * Thrown when an attempt is made to delete a {@link com.icps.model.Claimant}
 * that is still referenced by at least one existing {@code Claim} row.
 *
 * Backs the delete-guard required by Requirement 2.5, enforced via the
 * stored procedure {@code sp_claimant_has_claims}.
 */
public class ClaimantReferencedException extends RuntimeException {

    public ClaimantReferencedException(String message) {
        super(message);
    }
}
