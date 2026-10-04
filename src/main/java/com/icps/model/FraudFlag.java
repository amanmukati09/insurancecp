package com.icps.model;

import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code fraud_flag} table.
 */
public class FraudFlag {

    private Long fraudFlagId;
    private Long claimId;
    private String flagReason;
    private Integer scoreWeight;
    private Boolean isActive;
    private Date createdAt;
    private Date updatedAt;

    public FraudFlag() {
    }

    public Long getFraudFlagId() {
        return fraudFlagId;
    }

    public void setFraudFlagId(Long fraudFlagId) {
        this.fraudFlagId = fraudFlagId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public String getFlagReason() {
        return flagReason;
    }

    public void setFlagReason(String flagReason) {
        this.flagReason = flagReason;
    }

    public Integer getScoreWeight() {
        return scoreWeight;
    }

    public void setScoreWeight(Integer scoreWeight) {
        this.scoreWeight = scoreWeight;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
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
