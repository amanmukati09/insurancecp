package com.icps.dao.hibernate;

import java.util.List;

import javax.annotation.Resource;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.icps.dao.DocumentMetadataDao;
import com.icps.model.DocumentMetadata;

/**
 * Hibernate-backed implementation of {@link DocumentMetadataDao}.
 *
 * Uses the shared {@code sessionFactory} bean (defined in
 * {@code applicationContext.xml}) via {@code getCurrentSession()} for all
 * operations, relying on Spring's {@code HibernateTransactionManager} /
 * {@code tx:annotation-driven} for session and transaction management.
 */
@Repository
public class HibernateDocumentMetadataDao implements DocumentMetadataDao {

    @Resource(name = "sessionFactory")
    private SessionFactory sessionFactory;

    private Session currentSession() {
        return sessionFactory.getCurrentSession();
    }

    @Override
    @Transactional
    public DocumentMetadata save(DocumentMetadata documentMetadata) {
        currentSession().saveOrUpdate(documentMetadata);
        return documentMetadata;
    }

    @Override
    @Transactional(readOnly = true)
    public DocumentMetadata findById(Long id) {
        return currentSession().get(DocumentMetadata.class, id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<DocumentMetadata> findByClaimId(Long claimId) {
        return currentSession()
                .createQuery("FROM DocumentMetadata WHERE claimId = :claimId", DocumentMetadata.class)
                .setParameter("claimId", claimId)
                .list();
    }

    @Override
    @Transactional
    public void delete(Long id) {
        DocumentMetadata documentMetadata = currentSession().get(DocumentMetadata.class, id);
        if (documentMetadata != null) {
            currentSession().delete(documentMetadata);
        }
    }
}
