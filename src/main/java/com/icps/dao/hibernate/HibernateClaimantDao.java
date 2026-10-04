package com.icps.dao.hibernate;
import java.sql.Types;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import javax.sql.DataSource;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import com.icps.dao.ClaimantDao;
import com.icps.exception.ClaimantReferencedException;
import com.icps.model.Claimant;
/**
 * Hibernate-backed implementation of {@link ClaimantDao}.
 *
 * Uses the shared {@code sessionFactory} bean (defined in
 * {@code applicationContext.xml}) via {@code getCurrentSession()} for all
 * operations, relying on Spring's {@code HibernateTransactionManager} /
 * {@code tx:annotation-driven} for session and transaction management.
 * {@code @Transactional} is applied here at the DAO level (in addition to the
 * service layer) so these DAOs remain safe to call directly in isolation.
 *
 * {@link #hasClaims} and the delete-guard in {@link #delete} are the one
 * deliberate exception to the "Hibernate DAOs use the SessionFactory only"
 * rule: the referenced-Claimant check (Requirement 2.5) is backed by the
 * stored procedure {@code sp_claimant_has_claims} rather than a Hibernate
 * query, so this DAO also holds a {@code DataSource} reference purely to
 * invoke that one cross-cutting procedure via {@code SimpleJdbcCall}. This
 * keeps the delete-guard logic colocated with the entity it protects instead
 * of duplicating a JDBC-based "has references" check in the service layer.
 */
@Repository
public class HibernateClaimantDao implements ClaimantDao {
    @Resource(name = "sessionFactory")
    private SessionFactory sessionFactory;
    @Resource(name = "dataSource")
    private DataSource dataSource;
    private SimpleJdbcCall hasClaimsCall;
    private Session currentSession() {
        return sessionFactory.getCurrentSession();
    }
    @javax.annotation.PostConstruct
    public void init() {
        // sp_claimant_has_claims: CRUD-support procedure
        // (10_sp_crud_claimant_adjuster_policy.sql) backing the delete-guard
        // required by Requirement 2.5.
        hasClaimsCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_claimant_has_claims")
                .declareParameters(
                        new SqlParameter("p_claimant_id", Types.BIGINT),
                        new SqlOutParameter("p_has_claims_flag", Types.TINYINT));
    }
    @Override
    @Transactional
    public Claimant save(Claimant claimant) {
        currentSession().saveOrUpdate(claimant);
        return claimant;
    }
    @Override
    @Transactional(readOnly = true)
    public Claimant findById(Long id) {
        return currentSession().get(Claimant.class, id);
    }
    @Override
    @Transactional(readOnly = true)
    @SuppressWarnings("unchecked")
    public List<Claimant> findAll() {
        return currentSession()
                .createQuery("FROM Claimant", Claimant.class)
                .list();
    }
    @Override
    @Transactional
    public void delete(Long id) {
        if (hasClaims(id)) {
            throw new ClaimantReferencedException(
                    "Claimant is referenced by existing Claims and cannot be deleted");
        }
        Claimant claimant = currentSession().get(Claimant.class, id);
        if (claimant != null) {
            currentSession().delete(claimant);
        }
    }
    @Override
    @Transactional(readOnly = true)
    public List<Claimant> findByState(String state) {
        return currentSession()
                .createQuery("FROM Claimant WHERE addressState = :state", Claimant.class)
                .setParameter("state", state)
                .list();
    }
    @Override
    public boolean hasClaims(Long claimantId) {
        Map<String, Object> params = new HashMap<>();
        params.put("p_claimant_id", claimantId);
        Map<String, Object> out = hasClaimsCall.execute(params);
        Number flag = (Number) out.get("p_has_claims_flag");
        return flag != null && flag.intValue() != 0;
    }
}
