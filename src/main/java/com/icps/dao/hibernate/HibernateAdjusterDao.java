package com.icps.dao.hibernate;

import java.util.List;

import javax.annotation.Resource;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.icps.dao.AdjusterDao;
import com.icps.model.Adjuster;

/**
 * Hibernate-backed implementation of {@link AdjusterDao}.
 *
 * Uses the shared {@code sessionFactory} bean (defined in
 * {@code applicationContext.xml}) via {@code getCurrentSession()} for all
 * operations, relying on Spring's {@code HibernateTransactionManager} /
 * {@code tx:annotation-driven} for session and transaction management.
 */
@Repository
public class HibernateAdjusterDao implements AdjusterDao {

    @Resource(name = "sessionFactory")
    private SessionFactory sessionFactory;

    private Session currentSession() {
        return sessionFactory.getCurrentSession();
    }

    @Override
    @Transactional
    public Adjuster save(Adjuster adjuster) {
        currentSession().saveOrUpdate(adjuster);
        return adjuster;
    }

    @Override
    @Transactional(readOnly = true)
    public Adjuster findById(Long id) {
        return currentSession().get(Adjuster.class, id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Adjuster> findAll() {
        return currentSession()
                .createQuery("FROM Adjuster", Adjuster.class)
                .list();
    }

    @Override
    @Transactional
    public void delete(Long id) {
        Adjuster adjuster = currentSession().get(Adjuster.class, id);
        if (adjuster != null) {
            currentSession().delete(adjuster);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Adjuster findByUsername(String username) {
        return currentSession()
                .createQuery("FROM Adjuster WHERE username = :username", Adjuster.class)
                .setParameter("username", username)
                .uniqueResult();
    }
}
