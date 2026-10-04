package com.icps.model;

import java.util.Date;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

/**
 * Hibernate entity mapped to the {@code document_metadata} table.
 *
 * Document_Metadata describes an attachment (file name, type, size, storage
 * reference) associated with a Claim. This is one of the three
 * Hibernate-backed reference entities (Requirement 15.3, 17.1) persisted via
 * {@code HibernateDocumentMetadataDao}.
 *
 * {@code claimId} is stored as a plain foreign-key column rather than a full
 * {@code @ManyToOne} association, since {@code Claim} is a JDBC
 * ({@code SimpleJdbcCall}) backed entity, not a Hibernate-mapped entity.
 */
@Entity
@Table(name = "document_metadata")
public class DocumentMetadata {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "document_metadata_id")
    private Long documentMetadataId;

    @NotNull(message = "Claim id is required")
    @Column(name = "claim_id", nullable = false)
    private Long claimId;

    @NotBlank(message = "File name is required")
    @Size(max = 255, message = "File name must not exceed 255 characters")
    @Column(name = "file_name", nullable = false, length = 255)
    private String fileName;

    @NotBlank(message = "Document type is required")
    @Size(max = 50, message = "Document type must not exceed 50 characters")
    @Column(name = "document_type", nullable = false, length = 50)
    private String documentType;

    @NotNull(message = "File size is required")
    @Min(value = 0, message = "File size must be at least 0 bytes")
    @Max(value = 2147483647L, message = "File size must not exceed 2147483647 bytes")
    @Column(name = "file_size_bytes", nullable = false)
    private Long fileSizeBytes;

    @NotBlank(message = "Storage reference is required")
    @Size(max = 500, message = "Storage reference must not exceed 500 characters")
    @Column(name = "storage_reference", nullable = false, length = 500)
    private String storageReference;

    @NotNull(message = "Uploaded timestamp is required")
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "uploaded_at", nullable = false)
    private Date uploadedAt;

    public DocumentMetadata() {
    }

    public Long getDocumentMetadataId() {
        return documentMetadataId;
    }

    public void setDocumentMetadataId(Long documentMetadataId) {
        this.documentMetadataId = documentMetadataId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getDocumentType() {
        return documentType;
    }

    public void setDocumentType(String documentType) {
        this.documentType = documentType;
    }

    public Long getFileSizeBytes() {
        return fileSizeBytes;
    }

    public void setFileSizeBytes(Long fileSizeBytes) {
        this.fileSizeBytes = fileSizeBytes;
    }

    public String getStorageReference() {
        return storageReference;
    }

    public void setStorageReference(String storageReference) {
        this.storageReference = storageReference;
    }

    public Date getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(Date uploadedAt) {
        this.uploadedAt = uploadedAt;
    }
}
