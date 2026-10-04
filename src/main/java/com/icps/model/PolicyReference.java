package com.icps.model;

import java.math.BigDecimal;
import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code policy_reference} table.
 */
public class PolicyReference {

    private Long policyReferenceId;
    private String policyNumber;
    private String policyType;
    private BigDecimal coverageLimit;
    private BigDecimal deductible;
    private Date effectiveStartDate;
    private Date effectiveEndDate;

    public PolicyReference() {
    }

    public Long getPolicyReferenceId() {
        return policyReferenceId;
    }

    public void setPolicyReferenceId(Long policyReferenceId) {
        this.policyReferenceId = policyReferenceId;
    }

    public String getPolicyNumber() {
        return policyNumber;
    }

    public void setPolicyNumber(String policyNumber) {
        this.policyNumber = policyNumber;
    }

    public String getPolicyType() {
        return policyType;
    }

    public void setPolicyType(String policyType) {
        this.policyType = policyType;
    }

    public BigDecimal getCoverageLimit() {
        return coverageLimit;
    }

    public void setCoverageLimit(BigDecimal coverageLimit) {
        this.coverageLimit = coverageLimit;
    }

    public BigDecimal getDeductible() {
        return deductible;
    }

    public void setDeductible(BigDecimal deductible) {
        this.deductible = deductible;
    }

    public Date getEffectiveStartDate() {
        return effectiveStartDate;
    }

    public void setEffectiveStartDate(Date effectiveStartDate) {
        this.effectiveStartDate = effectiveStartDate;
    }

    public Date getEffectiveEndDate() {
        return effectiveEndDate;
    }

    public void setEffectiveEndDate(Date effectiveEndDate) {
        this.effectiveEndDate = effectiveEndDate;
    }
}
