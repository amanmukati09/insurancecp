package com.icps.dao;

import java.util.List;

import com.icps.model.Adjuster;

/**
 * DAO interface for {@link Adjuster} persistence.
 *
 * Adjuster is one of the three Hibernate-backed reference entities
 * (Requirement 15.3, 17.1). The implementation ({@code HibernateAdjusterDao})
 * uses the shared {@code SessionFactory} for all operations.
 */
public interface AdjusterDao {

    Adjuster save(Adjuster adjuster);

    Adjuster findById(Long id);

    List<Adjuster> findAll();

    void delete(Long id);

    Adjuster findByUsername(String username);
}
