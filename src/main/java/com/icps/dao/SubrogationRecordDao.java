package com.icps.dao;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;
import java.util.Map;

import com.icps.model.SubrogationRecord;

/**
 * DAO interface for {@link SubrogationRecord} persistence.
 *
 * Subrogation_Record is one of the ten JDBC/{@code SimpleJdbcCall}-backed
 * entities (Requirement 15.3, 15.4). The implementation
 * ({@code JdbcSubrogationRecordDao}) invokes the {@code sp_sub_*} CRUD
 * procedures plus the transactional lifecycle procedure
 * {@code sp_subrogation_record_create} — no inline business SQL.
 */
public interface SubrogationRecordDao {

    SubrogationRecord findById(Long id);

    List<SubrogationRecord> findByClaim(Long claimId);

    /**
     * Checks whether the given Claim's current status is eligible
     * ('Settled' or 'Closed') for Subrogation_Record creation.
     *
     * @see Requirements 11.2, 11.3
     */
    Boolean validateClaimStatus(Long claimId);

    /**
     * Invokes the transactional lifecycle procedure
     * {@code sp_subrogation_record_create}, which validates Claim status
     * eligibility and recovery-amount range, inserts the Subrogation_Record,
     * and recomputes {@code claim.net_paid_amount}.
     *
     * @return a map with keys {@code newId} (Long, null on failure) and
     *         {@code errorMessage} (String, null on success)
     */
    Map<String, Object> create(Long claimId, String thirdPartyIdentifier, BigDecimal recoveryAmount,
            Date recordedDate);

    void update(Long id, String thirdPartyIdentifier, BigDecimal recoveryAmount, Date recordedDate);

    void delete(Long id);
}
