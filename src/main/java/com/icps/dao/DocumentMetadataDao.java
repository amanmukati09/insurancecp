package com.icps.dao;

import java.util.List;

import com.icps.model.DocumentMetadata;

/**
 * DAO interface for {@link DocumentMetadata} persistence.
 *
 * Document_Metadata is one of the three Hibernate-backed reference entities
 * (Requirement 15.3, 17.1). The implementation
 * ({@code HibernateDocumentMetadataDao}) uses the shared {@code SessionFactory}
 * for all operations.
 */
public interface DocumentMetadataDao {

    DocumentMetadata save(DocumentMetadata documentMetadata);

    DocumentMetadata findById(Long id);

    List<DocumentMetadata> findByClaimId(Long claimId);

    void delete(Long id);
}
