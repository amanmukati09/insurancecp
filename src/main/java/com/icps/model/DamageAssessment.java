package com.icps.model;

import java.math.BigDecimal;
import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code damage_assessment} table.
 */
public class DamageAssessment {

    private Long damageAssessmentId;
    private Long claimId;
    private BigDecimal estimatedCost;
    private String description;
    private Date assessmentDate;
    private Date createdAt;

    public DamageAssessment() {
    }

    public Long getDamageAssessmentId() {
        return damageAssessmentId;
    }

    public void setDamageAssessmentId(Long damageAssessmentId) {
        this.damageAssessmentId = damageAssessmentId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public BigDecimal getEstimatedCost() {
        return estimatedCost;
    }

    public void setEstimatedCost(BigDecimal estimatedCost) {
        this.estimatedCost = estimatedCost;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Date getAssessmentDate() {
        return assessmentDate;
    }

    public void setAssessmentDate(Date assessmentDate) {
        this.assessmentDate = assessmentDate;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
