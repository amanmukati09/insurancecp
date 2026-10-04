package com.icps.model;

import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code claim_status_history} table. This is
 * an append-only audit trail (Requirement 14.1, 14.3) written via
 * SimpleJdbcCall DAOs; no update/delete access is provided.
 */
public class ClaimStatusHistory {

    private Long historyId;
    private Long claimId;
    private String priorStatus;
    private String newStatus;
    private String changedBy;
    private Date changedAt;
    private String note;

    public ClaimStatusHistory() {
    }

    public Long getHistoryId() {
        return historyId;
    }

    public void setHistoryId(Long historyId) {
        this.historyId = historyId;
    }

    public Long getClaimId() {
        return claimId;
    }

    public void setClaimId(Long claimId) {
        this.claimId = claimId;
    }

    public String getPriorStatus() {
        return priorStatus;
    }

    public void setPriorStatus(String priorStatus) {
        this.priorStatus = priorStatus;
    }

    public String getNewStatus() {
        return newStatus;
    }

    public void setNewStatus(String newStatus) {
        this.newStatus = newStatus;
    }

    public String getChangedBy() {
        return changedBy;
    }

    public void setChangedBy(String changedBy) {
        this.changedBy = changedBy;
    }

    public Date getChangedAt() {
        return changedAt;
    }

    public void setChangedAt(Date changedAt) {
        this.changedAt = changedAt;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
