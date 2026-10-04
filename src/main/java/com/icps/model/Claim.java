package com.icps.model;

import java.math.BigDecimal;
import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code claim} table. Claim is a core
 * transactional entity backed by stored procedures via SimpleJdbcCall DAOs
 * (design.md Persistence Split, Requirement 15.3) rather than a Hibernate
 * entity.
 */
public class Claim {

    private Long claimId;
    private Long claimantId;
    private Long policyReferenceId;
    private Long adjusterId;
    private Date lossDate;
    private String lossDescription;
    private String status;
    private Boolean underFraudReview;
    private BigDecimal netPaidAmount;
    private Integer version;
    private Date createdAt;
    private Date updatedAt;

    public Claim() {
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public Long getClaimantId() {
        return claimantId;
    }

    public void setClaimantId(Long claimantId) {
        this.claimantId = claimantId;
    }

    public Long getPolicyReferenceId() {
        return policyReferenceId;
    }

    public void setPolicyReferenceId(Long policyReferenceId) {
        this.policyReferenceId = policyReferenceId;
    }

    public Long getAdjusterId() {
        return adjusterId;
    }

    public void setAdjusterId(Long adjusterId) {
        this.adjusterId = adjusterId;
    }

    public Date getLossDate() {
        return lossDate;
    }

    public void setLossDate(Date lossDate) {
        this.lossDate = lossDate;
    }

    public String getLossDescription() {
        return lossDescription;
    }

    public void setLossDescription(String lossDescription) {
        this.lossDescription = lossDescription;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Boolean getUnderFraudReview() {
        return underFraudReview;
    }

    public void setUnderFraudReview(Boolean underFraudReview) {
        this.underFraudReview = underFraudReview;
    }

    public BigDecimal getNetPaidAmount() {
        return netPaidAmount;
    }

    public void setNetPaidAmount(BigDecimal netPaidAmount) {
        this.netPaidAmount = netPaidAmount;
    }

    public Integer getVersion() {
        return version;
    }

    public void setVersion(Integer version) {
        this.version = version;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Date getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Date updatedAt) {
        this.updatedAt = updatedAt;
    }
}
