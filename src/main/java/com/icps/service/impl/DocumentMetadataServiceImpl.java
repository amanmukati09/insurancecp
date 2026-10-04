package com.icps.service.impl;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.PostConstruct;
import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.icps.dao.DocumentMetadataDao;
import com.icps.exception.NotFoundException;
import com.icps.exception.ValidationException;
import com.icps.model.DocumentMetadata;
import com.icps.service.DocumentMetadataService;

/**
 * Default implementation of {@link DocumentMetadataService}.
 *
 * Applies the {@code javax.validation} constraints declared on
 * {@link DocumentMetadata} (Requirement 9.3) and translates not-found
 * conditions into {@link NotFoundException} (Requirement 9.4).
 */
@Service
public class DocumentMetadataServiceImpl implements DocumentMetadataService {

    @Autowired
    private DocumentMetadataDao documentMetadataDao;

    private Validator validator;

    @PostConstruct
    public void init() {
        this.validator = Validation.buildDefaultValidatorFactory().getValidator();
    }

    @Override
    public DocumentMetadata create(DocumentMetadata documentMetadata) {
        // uploadedAt is a server-assigned audit timestamp, not a caller-supplied
        // field; default it here before validation (Requirement 9.2).
        if (documentMetadata.getUploadedAt() == null) {
            documentMetadata.setUploadedAt(new Date());
        }
        validate(documentMetadata);
        return documentMetadataDao.save(documentMetadata);
    }

    @Override
    public DocumentMetadata update(Long id, DocumentMetadata documentMetadata) {
        DocumentMetadata existing = documentMetadataDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Document_Metadata not found: id=" + id);
        }
        if (documentMetadata.getUploadedAt() == null) {
            documentMetadata.setUploadedAt(existing.getUploadedAt());
        }
        validate(documentMetadata);
        documentMetadata.setDocumentMetadataId(id);
        return documentMetadataDao.save(documentMetadata);
    }

    @Override
    public DocumentMetadata findById(Long id) {
        DocumentMetadata documentMetadata = documentMetadataDao.findById(id);
        if (documentMetadata == null) {
            throw new NotFoundException("Document_Metadata not found: id=" + id);
        }
        return documentMetadata;
    }

    @Override
    public List<DocumentMetadata> findByClaimId(Long claimId) {
        return documentMetadataDao.findByClaimId(claimId);
    }

    @Override
    public void delete(Long id) {
        if (documentMetadataDao.findById(id) == null) {
            throw new NotFoundException("Document_Metadata not found: id=" + id);
        }
        documentMetadataDao.delete(id);
    }

    private void validate(DocumentMetadata documentMetadata) {
        Set<ConstraintViolation<DocumentMetadata>> violations = validator.validate(documentMetadata);
        if (!violations.isEmpty()) {
            Map<String, String> fieldErrors = new LinkedHashMap<>();
            for (ConstraintViolation<DocumentMetadata> violation : violations) {
                fieldErrors.put(violation.getPropertyPath().toString(), violation.getMessage());
            }
            throw new ValidationException(fieldErrors);
        }
    }
}
