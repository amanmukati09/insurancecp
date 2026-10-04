package com.icps.exception;

/**
 * Thrown when a request attempts to read, update, or delete an entity
 * identifier that does not exist (e.g. {@link com.icps.model.Claimant},
 * {@link com.icps.model.DocumentMetadata}).
 *
 * Backs the not-found handling required by Requirements 2.4 and 9.4.
 */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}
