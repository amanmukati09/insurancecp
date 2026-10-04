package com.icps.model;

import java.math.BigDecimal;
import java.util.Date;

/**
 * Plain JDBC-mapped POJO for the {@code reserve_history} table. This is an
 * append-only audit trail (Requirement 14.2, 14.3) written via SimpleJdbcCall
 * DAOs; no update/delete access is provided.
 */
public class ReserveHistory {

    private Long reserveHistoryId;
    private Long reserveId;
    private BigDecimal priorAmount;
    private BigDecimal newAmount;
    private String reason;
    private String changedBy;
    private Date changedAt;

    public ReserveHistory() {
    }

    public Long getReserveHistoryId() {
        return reserveHistoryId;
    }

    public void setReserveHistoryId(Long reserveHistoryId) {
        this.reserveHistoryId = reserveHistoryId;
    }

    public Long getReserveId() {
        return reserveId;
    }

    public void setReserveId(Long reserveId) {
        this.reserveId = reserveId;
    }

    public BigDecimal getPriorAmount() {
        return priorAmount;
    }

    public void setPriorAmount(BigDecimal priorAmount) {
        this.priorAmount = priorAmount;
    }

    public BigDecimal getNewAmount() {
        return newAmount;
    }

    public void setNewAmount(BigDecimal newAmount) {
        this.newAmount = newAmount;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
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
}
