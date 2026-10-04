package com.icps.dao.jdbc;
import java.util.ArrayList;
import java.util.Date;
import java.sql.Types;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import javax.sql.DataSource;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;
import com.icps.dao.LitigationRecordDao;
import com.icps.model.LitigationRecord;
import com.icps.model.rowmapper.LitigationRecordRowMapper;
/**
 * {@code SimpleJdbcCall}-backed implementation of {@link LitigationRecordDao}.
 *
 * Litigation_Record is one of the ten JDBC-call-backed entities
 * (Requirement 15.3). All operations invoke the {@code sp_lit_*} stored
 * procedures defined in {@code 14_sp_crud_document_litigation_subrogation.sql};
 * no inline business SQL is used (Requirement 15.4, 17.2). One
 * {@link SimpleJdbcCall} instance is configured per procedure at
 * construction time via {@code @Resource}-injected {@link DataSource},
 * following the same pattern as the other JDBC DAOs in this package.
 */
@Repository
public class JdbcLitigationRecordDao implements LitigationRecordDao {
    @Resource(name = "dataSource")
    private DataSource dataSource;
    private SimpleJdbcCall createCall;
    private SimpleJdbcCall readCall;
    private SimpleJdbcCall updateCall;
    private SimpleJdbcCall deleteCall;
    private SimpleJdbcCall listByClaimCall;
    @javax.annotation.PostConstruct
    public void init() {
        createCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_lit_create")
                .declareParameters(
                        new SqlParameter("p_claim_id", Types.BIGINT),
                        new SqlParameter("p_case_reference", Types.VARCHAR),
                        new SqlParameter("p_filing_date", Types.DATE),
                        new SqlParameter("p_status", Types.VARCHAR),
                        new SqlParameter("p_attorney_name", Types.VARCHAR),
                        new SqlOutParameter("p_new_id", Types.BIGINT));
        readCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_lit_read")
                .returningResultSet("#result-set-1", new LitigationRecordRowMapper())
                .declareParameters(new SqlParameter("p_litigation_record_id", Types.BIGINT));
        updateCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_lit_update")
                .declareParameters(
                        new SqlParameter("p_litigation_record_id", Types.BIGINT),
                        new SqlParameter("p_case_reference", Types.VARCHAR),
                        new SqlParameter("p_filing_date", Types.DATE),
                        new SqlParameter("p_status", Types.VARCHAR),
                        new SqlParameter("p_attorney_name", Types.VARCHAR));
        deleteCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_lit_delete")
                .declareParameters(new SqlParameter("p_litigation_record_id", Types.BIGINT));
        listByClaimCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_lit_list_by_claim")
                .returningResultSet("#result-set-1", new LitigationRecordRowMapper())
                .declareParameters(new SqlParameter("p_claim_id", Types.BIGINT));
    }
    @Override
    public Long create(Long claimId, String caseReference, Date filingDate, String status, String attorneyName) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        params.put("p_case_reference", caseReference);
        params.put("p_filing_date", filingDate);
        params.put("p_status", status);
        params.put("p_attorney_name", attorneyName);
        Map<String, Object> out = createCall.execute(params);
        Number newId = (Number) out.get("p_new_id");
        return newId == null ? null : newId.longValue();
    }
    @Override
    @SuppressWarnings("unchecked")
    public LitigationRecord findById(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_litigation_record_id", id);
        Map<String, Object> out = readCall.execute(params);
        List<LitigationRecord> rows = (List<LitigationRecord>) out.get("#result-set-1");
        return (rows == null || rows.isEmpty()) ? null : rows.get(0);
    }
    @Override
    @SuppressWarnings("unchecked")
    public List<LitigationRecord> findByClaim(Long claimId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claim_id", claimId);
        Map<String, Object> out = listByClaimCall.execute(params);
        List<LitigationRecord> rows = (List<LitigationRecord>) out.get("#result-set-1");
        return rows == null ? new ArrayList<>() : rows;
    }
    @Override
    public void update(Long id, String caseReference, Date filingDate, String status, String attorneyName) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_litigation_record_id", id);
        params.put("p_case_reference", caseReference);
        params.put("p_filing_date", filingDate);
        params.put("p_status", status);
        params.put("p_attorney_name", attorneyName);
        updateCall.execute(params);
    }
    @Override
    public void delete(Long id) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_litigation_record_id", id);
        deleteCall.execute(params);
    }
}
