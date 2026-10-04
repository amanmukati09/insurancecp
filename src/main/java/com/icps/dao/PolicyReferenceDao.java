package com.icps.dao;
import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import com.icps.model.PolicyReference;
/**
 * DAO interface for {@link PolicyReference} persistence.
 *
 * Policy_Reference is referenced by lifecycle validation procedures
 * (design.md Persistence Split, Requirement 15.3). All methods delegate to
 * the Policy_Reference CRUD stored procedures (task 4.1).
 */
public interface PolicyReferenceDao {
    PolicyReference findById(Long id);
    PolicyReference findByNumber(String policyNumber);
    List<PolicyReference> findAll();
    /**
     * Validates that {@code lossDate} falls within the referenced Policy's
     * effective date range, via {@code sp_policy_reference_validate_date_range}
     * (Requirement 12.4, 12.5).
     */
    Boolean validateDateRange(Long policyReferenceId, Date lossDate);
    /**
     * Creates a new Policy_Reference via {@code sp_policy_reference_create}.
     *
     * @return the generated policy_reference_id
     * @see Requirements 12.1
     */
    Long create(String policyNumber, String policyType, BigDecimal coverageLimit,
            BigDecimal deductible, Date effectiveStartDate, Date effectiveEndDate);
    /**
     * Updates an existing Policy_Reference via {@code sp_policy_reference_update}.
     *
     * @see Requirements 12.1
     */
    void update(Long id, String policyNumber, String policyType, BigDecimal coverageLimit,
            BigDecimal deductible, Date effectiveStartDate, Date effectiveEndDate);
    /**
     * Deletes a Policy_Reference via {@code sp_policy_reference_delete}.
     *
     * @see Requirements 12.1
     */
    void delete(Long id);
}
