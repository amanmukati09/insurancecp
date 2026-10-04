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
import com.icps.dao.PolicyReferenceDao;
import com.icps.exception.NotFoundException;
import com.icps.model.PolicyReference;
/**
 * REST JSON controller exposing CRUD operations for {@link PolicyReference}
 * records (the Policy_Reference stub, Requirement 12.1).
 *
 * <p>Unlike the Hibernate-backed entity controllers, this controller talks
 * directly to the {@code SimpleJdbcCall}-backed {@link PolicyReferenceDao},
 * consistent with the JDBC/stored-procedure persistence split for
 * Policy_Reference (Requirement 15.3, 15.4). Not-found handling is surfaced
 * via {@link com.icps.exception.GlobalErrorHandler}.</p>
 *
 * @see Requirements 12.1, 15.6
 */
@RestController
@RequestMapping("/api/policy-references")
public class PolicyReferenceRestController {
    @Resource
    private PolicyReferenceDao policyReferenceDao;
    /**
     * Lists all Policy_Reference records.
     *
     * @return all persisted Policy_References
     */
    @GetMapping
    public List<PolicyReference> findAll() {
        return policyReferenceDao.findAll();
    }
    /**
     * Reads a single Policy_Reference by identifier.
     *
     * @param id the Policy_Reference identifier
     * @return the matching Policy_Reference's current field values
     * @throws NotFoundException if no Policy_Reference exists for the id
     */
    @GetMapping("/{id}")
    public PolicyReference findById(@PathVariable Long id) {
        PolicyReference found = policyReferenceDao.findById(id);
        if (found == null) {
            throw new NotFoundException("Policy_Reference not found: " + id);
        }
        return found;
    }
    /**
     * Creates a new Policy_Reference.
     *
     * @param policyReference the Policy_Reference payload
     * @return 201 Created with the persisted Policy_Reference, including its
     *         generated identifier
     */
    @PostMapping
    public ResponseEntity<PolicyReference> create(@RequestBody PolicyReference policyReference) {
        Long newId = policyReferenceDao.create(
                policyReference.getPolicyNumber(),
                policyReference.getPolicyType(),
                policyReference.getCoverageLimit(),
                policyReference.getDeductible(),
                policyReference.getEffectiveStartDate(),
                policyReference.getEffectiveEndDate());
        PolicyReference created = policyReferenceDao.findById(newId);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }
    /**
     * Updates an existing Policy_Reference.
     *
     * @param id              the Policy_Reference identifier to update
     * @param policyReference the new field values
     * @return the persisted Policy_Reference
     * @throws NotFoundException if no Policy_Reference exists for the id
     */
    @PutMapping("/{id}")
    public PolicyReference update(@PathVariable Long id, @RequestBody PolicyReference policyReference) {
        PolicyReference existing = policyReferenceDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Policy_Reference not found: " + id);
        }
        policyReferenceDao.update(
                id,
                policyReference.getPolicyNumber(),
                policyReference.getPolicyType(),
                policyReference.getCoverageLimit(),
                policyReference.getDeductible(),
                policyReference.getEffectiveStartDate(),
                policyReference.getEffectiveEndDate());
        return policyReferenceDao.findById(id);
    }
    /**
     * Deletes a Policy_Reference by identifier.
     *
     * @param id the Policy_Reference identifier to delete
     * @return 204 No Content on success
     * @throws NotFoundException if no Policy_Reference exists for the id
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        PolicyReference existing = policyReferenceDao.findById(id);
        if (existing == null) {
            throw new NotFoundException("Policy_Reference not found: " + id);
        }
        policyReferenceDao.delete(id);
        return ResponseEntity.noContent().build();
    }
}
