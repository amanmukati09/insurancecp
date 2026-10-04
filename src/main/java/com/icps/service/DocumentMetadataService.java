package com.icps.service;

import java.util.List;

import com.icps.model.DocumentMetadata;

/**
 * Service interface applying Bean Validation and not-found handling around
 * {@link com.icps.dao.DocumentMetadataDao} for use by the REST controllers
 * (task 17).
 *
 * @see Requirements 9.3, 9.4
 */
public interface DocumentMetadataService {

    /**
     * Validates and persists a new Document_Metadata record.
     *
     * @param documentMetadata the Document_Metadata to create
     * @return the persisted Document_Metadata, including its generated
     *         identifier
     * @throws com.icps.exception.ValidationException if any required field is
     *         missing or invalid (Requirement 9.3)
     */
    DocumentMetadata create(DocumentMetadata documentMetadata);

    /**
     * Validates and persists changes to an existing Document_Metadata record.
     *
     * @param id               the Document_Metadata identifier to update
     * @param documentMetadata the new field values
     * @return the persisted Document_Metadata
     * @throws com.icps.exception.NotFoundException   if no Document_Metadata
     *         with the given id exists (Requirement 9.4)
     * @throws com.icps.exception.ValidationException if any required field is
     *         missing or invalid (Requirement 9.3)
     */
    DocumentMetadata update(Long id, DocumentMetadata documentMetadata);

    /**
     * Fetches a Document_Metadata record by identifier.
     *
     * @param id the Document_Metadata identifier
     * @return the matching Document_Metadata
     * @throws com.icps.exception.NotFoundException if no Document_Metadata
     *         with the given id exists (Requirement 9.4)
     */
    DocumentMetadata findById(Long id);

    /**
     * Lists the Document_Metadata records associated with a Claim.
     *
     * @param claimId the Claim identifier
     * @return the matching Document_Metadata records, or an empty list if
     *         none exist
     */
    List<DocumentMetadata> findByClaimId(Long claimId);

    /**
     * Deletes a Document_Metadata record by identifier.
     *
     * @param id the Document_Metadata identifier
     * @throws com.icps.exception.NotFoundException if no Document_Metadata
     *         with the given id exists (Requirement 9.4)
     */
    void delete(Long id);
}
