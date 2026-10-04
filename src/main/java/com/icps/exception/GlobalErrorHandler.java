package com.icps.exception;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

/**
 * Global exception handling for the REST API surface of ICPS.
 *
 * <p>Applies across both {@code @RestController} and {@code @Controller}
 * (ModelAndView-style) handlers, though the JSP-rendered controllers largely
 * handle their own inline validation redisplay (see Requirement 1.4 and the
 * claim intake form) and so primarily rely on their own logic rather than
 * this advice for user-facing error presentation.
 *
 * <p><strong>Intentional legacy code smell (Requirement 17.5):</strong> the
 * last-resort {@link #handleUnexpected(Exception)} method below deliberately
 * catches the broad {@code java.lang.Exception} type and returns a generic,
 * non-descriptive error response to the caller rather than identifying the
 * specific underlying exception type or message. This is included on purpose
 * as a legacy-representative anti-pattern for modernization-tooling test
 * purposes, not as an oversight. Spring resolves {@code @ExceptionHandler}
 * methods by most-specific exception type first, so the more specific
 * handlers declared above it in this class always take precedence and this
 * handler only activates for truly unanticipated failures.
 */
@ControllerAdvice
public class GlobalErrorHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(GlobalErrorHandler.class);

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(ValidationException e) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", e.getMessage());
        body.put("fieldErrors", e.getFieldErrors());
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(NotFoundException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", e.getMessage());
        return new ResponseEntity<>(body, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(ClaimantReferencedException.class)
    public ResponseEntity<Map<String, Object>> handleClaimantReferenced(ClaimantReferencedException e) {
        Map<String, Object> body = new HashMap<>();
        body.put("error", e.getMessage());
        return new ResponseEntity<>(body, HttpStatus.CONFLICT);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrityViolation(DataIntegrityViolationException e) {
        LOGGER.error("Data integrity violation", e);
        Map<String, Object> body = new HashMap<>();
        body.put("error", "The request could not be completed due to a data constraint violation");
        return new ResponseEntity<>(body, HttpStatus.CONFLICT);
    }

    /**
     * Last-resort handler for any exception not caught by a more specific
     * handler above. See the class-level Javadoc: this broad
     * {@code catch (Exception e)} and the deliberately generic response body
     * are an intentional legacy code smell per Requirement 17.5, included
     * for modernization-tooling test purposes. It must NOT leak
     * {@code e.getMessage()}, {@code e.getClass().getName()}, or any stack
     * trace detail to the caller.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUnexpected(Exception e) {
        LOGGER.error("Unexpected error occurred", e);
        Map<String, Object> body = new HashMap<>();
        body.put("error", "An unexpected error occurred");
        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
