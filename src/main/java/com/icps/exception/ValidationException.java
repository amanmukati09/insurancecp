package com.icps.exception;

import java.util.Collections;
import java.util.Map;

/**
 * Thrown when a create or update request fails Bean Validation
 * ({@code javax.validation}) constraints applied to a Hibernate-mapped
 * entity (e.g. {@link com.icps.model.Claimant}, {@link
 * com.icps.model.DocumentMetadata}).
 *
 * <p>Carries a field name &rarr; validation error message map so REST
 * controllers / the global error handler can return a response identifying
 * the specific invalid or missing field(s), per Requirements 2.3 and 9.3.</p>
 */
public class ValidationException extends RuntimeException {

    private final Map<String, String> fieldErrors;

    public ValidationException(Map<String, String> fieldErrors) {
        super(buildMessage(fieldErrors));
        this.fieldErrors = Collections.unmodifiableMap(fieldErrors);
    }

    public ValidationException(String message, Map<String, String> fieldErrors) {
        super(message + ": " + buildMessage(fieldErrors));
        this.fieldErrors = Collections.unmodifiableMap(fieldErrors);
    }

    public Map<String, String> getFieldErrors() {
        return fieldErrors;
    }

    private static String buildMessage(Map<String, String> fieldErrors) {
        StringBuilder sb = new StringBuilder("Validation failed: ");
        boolean first = true;
        for (Map.Entry<String, String> entry : fieldErrors.entrySet()) {
            if (!first) {
                sb.append("; ");
            }
            sb.append(entry.getKey()).append(" - ").append(entry.getValue());
            first = false;
        }
        return sb.toString();
    }
}
