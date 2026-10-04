package com.icps.model;

import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code litigation_record} table.
 */
public class LitigationRecord {

    private Long litigationRecordId;
    private Long claimId;
    private String caseReference;
    private Date filingDate;
    private String status;
    private String attorneyName;
    private Date createdAt;

    public LitigationRecord() {
    }

    public Long getLitigationRecordId() {
        return litigationRecordId;
    }

    public void setLitigationRecordId(Long litigationRecordId) {
        this.litigationRecordId = litigationRecordId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public String getCaseReference() {
        return caseReference;
    }

    public void setCaseReference(String caseReference) {
        this.caseReference = caseReference;
    }

    public Date getFilingDate() {
        return filingDate;
    }

    public void setFilingDate(Date filingDate) {
        this.filingDate = filingDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAttorneyName() {
        return attorneyName;
    }

    public void setAttorneyName(String attorneyName) {
        this.attorneyName = attorneyName;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
}
