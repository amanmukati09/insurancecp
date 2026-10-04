package com.icps.dao.jdbc;
import java.math.BigDecimal;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import javax.sql.DataSource;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;
import com.icps.dao.SubrogationRecordDao;
import com.icps.model.SubrogationRecord;
import com.icps.model.rowmapper.SubrogationRecordRowMapper;
/**
 * {@code SimpleJdbcCall}-backed implementation of {@link SubrogationRecordDao}.
 *
 * Subrogation_Record is one of the ten JDBC-call-backed entities
 * (Requirement 15.3). Simple CRUD/finder operations invoke the
 * {@code sp_sub_*} procedures defined in
 * {@code 14_sp_crud_document_litigation_subrogation.sql}. Creation of a new
 * record invokes the transactional lifecycle procedure
 * {@code sp_subrogation_record_create} ({@code 22_sp_lifecycle_fraud_subrogation.sql}),
 * which composes {@code sp_sub_create} and {@code sp_sub_validate_claim_status}
 * after validating Claim status eligibility (Settled/Closed) and the
 * recovery-amount range against {@code claim.net_paid_amount}
 * (Requirement 11.2-11.6). No inline business SQL is used here
 * (Requirement 15.4, 17.2).
 */
@Repository
public class JdbcSubrogationRecordDao implements SubrogationRecordDao {
    @Resource(name = "dataSource")
    private DataSource dataSource;
    private SimpleJdbcCall readCall;
    private SimpleJdbcCall listByClaimCall;
    private SimpleJdbcCall validateClaimStatusCall;
    private SimpleJdbcCall subrogationRecordCreateCall;
    private SimpleJdbcCall updateCall;
    private SimpleJdbcCall deleteCall;
    @javax.annotation.PostConstruct
    public void init() {
        readCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_sub_read")
                .returningResultSet("#result-set-1", new SubrogationRecordRowMapper())
                .declareParameters(new SqlParameter("p_subrogation_record_id", Types.BIGINT));
        listByClaimCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_sub_list_by_claim")
                .returningResultSet("#result-set-1", new SubrogationRecordRowMapper())
                .declareParameters(new SqlParameter("p_claim_id", Types.BIGINT));
        validateClaimStatusCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_sub_validate_claim_status")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlOutParameter("p_is_valid", Types.TINYINT));
        subrogationRecordCreateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_subrogation_record_create")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_third_party_identifier", Types.VARCHAR),
                        new SqlParameter("p_recovery_amount", Types.DECIMAL),
                        new SqlParameter("p_recorded_date", Types.DATE),
                        new SqlOutParameter("p_new_id", Types.BIGINT),
                        new SqlOutParameter("p_error_message", Types.VARCHAR));
        updateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_sub_update")
                .declareParameters(
                        new SqlParameter("p_subrogation_record_id", Types.BIGINT),
                        new SqlParameter("p_third_party_identifier", Types.VARCHAR),
                        new SqlParameter("p_recovery_amount", Types.DECIMAL),
                        new SqlParameter("p_recorded_date", Types.DATE));
        deleteCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_sub_delete")
                .declareParameters(new SqlParameter("p_subrogation_record_id", Types.BIGINT));
    }
    @Override
    @SuppressWarnings("unchecked")
    public SubrogationRecord findById(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_subrogation_record_id", id);
        Map<String, Object> out = readCall.execute(params);
        List<SubrogationRecord> rows = (List<SubrogationRecord>) out.get("#result-set-1");
        return (rows == null || rows.isEmpty()) ? null : rows.get(0);
    }
    @Override
    @SuppressWarnings("unchecked")
    public List<SubrogationRecord> findByClaim(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = listByClaimCall.execute(params);
        List<SubrogationRecord> rows = (List<SubrogationRecord>) out.get("#result-set-1");
        return rows == null ? new ArrayList<>() : rows;
    }
    @Override
    public Boolean validateClaimStatus(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = validateClaimStatusCall.execute(params);
        Object flag = out.get("p_is_valid");
        if (flag == null) {
            return null;
        }
        if (flag instanceof Boolean) {
            return (Boolean) flag;
        }
        return ((Number) flag).intValue() != 0;
    }
    @Override
    public Map<String, Object> create(Long claimId, String thirdPartyIdentifier, BigDecimal recoveryAmount,
            Date recordedDate) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_third_party_identifier", thirdPartyIdentifier);
        params.put("p_recovery_amount", recoveryAmount);
        params.put("p_recorded_date", recordedDate);
        Map<String, Object> out = subrogationRecordCreateCall.execute(params);
        Number newId = (Number) out.get("p_new_id");
        String errorMessage = (String) out.get("p_error_message");
        Map<String, Object> outcome = new HashMap<>();
        outcome.put("newId", newId == null ? null : newId.longValue());
        outcome.put("errorMessage", errorMessage);
        return outcome;
    }
    @Override
    public void update(Long id, String thirdPartyIdentifier, BigDecimal recoveryAmount, Date recordedDate) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_subrogation_record_id", id);
        params.put("p_third_party_identifier", thirdPartyIdentifier);
        params.put("p_recovery_amount", recoveryAmount);
        params.put("p_recorded_date", recordedDate);
        updateCall.execute(params);
    }
    @Override
    public void delete(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_subrogation_record_id", id);
        deleteCall.execute(params);
    }
}
