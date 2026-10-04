package com.icps.controller;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.model.DocumentMetadata;
import com.icps.service.DocumentMetadataService;
/**
 * REST JSON controller exposing CRUD operations for {@link DocumentMetadata}
 * records associated with a Claim (Requirement 9).
 *
 * <p>Validation (Requirement 9.3) and not-found handling (Requirement 9.4)
 * are delegated to {@link DocumentMetadataService}, which is backed by a
 * Hibernate-mapped entity and DAO (Requirement 9.2).</p>
 *
 * @see Requirements 9.1, 9.2, 9.3, 9.4, 15.6
 */
@RestController
@RequestMapping("/api/claims/{claimId}/documents")
public class DocumentMetadataRestController {
    @Resource
    private DocumentMetadataService documentMetadataService;
    /**
     * Lists the Document_Metadata records associated with a Claim.
     *
     * @param claimId the Claim identifier
     * @return the Claim's Document_Metadata records, or an empty list if
     *         none exist
     */
    @GetMapping
    public List<DocumentMetadata> listDocuments(@PathVariable Long claimId) {
        return documentMetadataService.findByClaimId(claimId);
    }
    /**
     * Reads a single Document_Metadata record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Document_Metadata identifier
     * @return the Document_Metadata record
     * @throws com.icps.exception.NotFoundException if no Document_Metadata
     *         exists with the given id (Requirement 9.4)
     */
    @GetMapping("/{id}")
    public DocumentMetadata getDocument(@PathVariable Long claimId, @PathVariable Long id) {
        return documentMetadataService.findById(id);
    }
    /**
     * Creates a new Document_Metadata record for a Claim.
     *
     * @param claimId           the Claim identifier taken from the path
     * @param documentMetadata  the request payload
     * @return HTTP 201 with the created Document_Metadata
     * @throws com.icps.exception.ValidationException if a required field is
     *         missing or invalid (Requirement 9.3)
     */
    @PostMapping
    public ResponseEntity<DocumentMetadata> createDocument(@PathVariable Long claimId,
            @RequestBody DocumentMetadata documentMetadata) {
        documentMetadata.setClaimId(claimId);
        DocumentMetadata created = documentMetadataService.create(documentMetadata);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    /**
     * Updates an existing Document_Metadata record.
     *
     * @param claimId           the Claim identifier taken from the path
     * @param id                the Document_Metadata identifier
     * @param documentMetadata  the request payload with the new field values
     * @return the updated Document_Metadata
     * @throws com.icps.exception.NotFoundException   if no Document_Metadata
     *         exists with the given id (Requirement 9.4)
     * @throws com.icps.exception.ValidationException if a required field is
     *         missing or invalid (Requirement 9.3)
     */
    @PutMapping("/{id}")
    public DocumentMetadata updateDocument(@PathVariable Long claimId, @PathVariable Long id,
            @RequestBody DocumentMetadata documentMetadata) {
        documentMetadata.setClaimId(claimId);
        return documentMetadataService.update(id, documentMetadata);
    }
    /**
     * Deletes a Document_Metadata record by id.
     *
     * @param claimId the Claim identifier (path consistency only)
     * @param id      the Document_Metadata identifier
     * @return HTTP 204 on success
     * @throws com.icps.exception.NotFoundException if no Document_Metadata
     *         exists with the given id (Requirement 9.4)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDocument(@PathVariable Long claimId, @PathVariable Long id) {
        documentMetadataService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
