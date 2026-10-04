package com.icps.model;

import java.math.BigDecimal;
import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code subrogation_record} table.
 */
public class SubrogationRecord {

    private Long subrogationRecordId;
    private Long claimId;
    private String thirdPartyIdentifier;
    private BigDecimal recoveryAmount;
    private Date recordedDate;
    private Date createdAt;

    public SubrogationRecord() {
    }

    public Long getSubrogationRecordId() {
        return subrogationRecordId;
    }

    public void setSubrogationRecordId(Long subrogationRecordId) {
        this.subrogationRecordId = subrogationRecordId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public String getThirdPartyIdentifier() {
        return thirdPartyIdentifier;
    }

    public void setThirdPartyIdentifier(String thirdPartyIdentifier) {
        this.thirdPartyIdentifier = thirdPartyIdentifier;
    }

    public BigDecimal getRecoveryAmount() {
        return recoveryAmount;
    }

    public void setRecoveryAmount(BigDecimal recoveryAmount) {
        this.recoveryAmount = recoveryAmount;
    }

    public Date getRecordedDate() {
        return recordedDate;
    }

    public void setRecordedDate(Date recordedDate) {
        this.recordedDate = recordedDate;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
