package com.icps.dao.jdbc;

import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.icps.dao.ReserveDao;
import com.icps.dao.ReserveHistoryDao;
import com.icps.model.Reserve;
import com.icps.model.ReserveHistory;
import com.icps.model.rowmapper.ReserveHistoryRowMapper;

/**
 * {@code SimpleJdbcCall}-backed implementation of {@link ReserveHistoryDao}.
 *
 * {@link #findByReserve} invokes the insert-only audit trail's listing
 * procedure {@code sp_rh_list_by_reserve} ({@code 12_sp_crud_damage_reserve.sql}).
 * No update/delete method exists, matching the absence of
 * {@code sp_rh_update}/{@code sp_rh_delete} procedures (Requirement 14.2,
 * 14.3). No inline SQL is used (Requirement 15.4, 17.2).
 *
 * <p>{@link #findByClaimViaReserve} composes {@link ReserveDao#findByClaimId}
 * (to resolve the Claim's {@code reserve_id}) with {@link #findByReserve},
 * entirely within this DAO, so callers only need a {@code claimId}. This
 * composition is done here rather than in the service layer purely as a
 * convenience; see the interface Javadoc for the alternative.</p>
 */
@Repository
public class JdbcReserveHistoryDao implements ReserveHistoryDao {

    @Resource(name = "dataSource")
    private DataSource dataSource;

    @Autowired
    private ReserveDao reserveDao;

    private SimpleJdbcCall listByReserveCall;

    @javax.annotation.PostConstruct
    public void init() {
        listByReserveCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_rh_list_by_reserve")
                .returningResultSet("#result-set-1", new ReserveHistoryRowMapper())
                .declareParameters(new SqlParameter("p_reserve_id", Types.BIGINT));
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<ReserveHistory> findByReserve(Long reserveId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_reserve_id", reserveId);
        Map<String, Object> out = listByReserveCall.execute(params);
        List<ReserveHistory> rows = (List<ReserveHistory>) out.get("#result-set-1");
        return rows == null ? new ArrayList<>() : rows;
    }

    @Override
    public List<ReserveHistory> findByClaimViaReserve(Long claimId) {
        Reserve reserve = reserveDao.findByClaimId(claimId);
        if (reserve == null) {
            return new ArrayList<>();
        }
        return findByReserve(reserve.getReserveId());
    }
}
