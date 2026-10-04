package com.icps.controller;

import java.util.List;
import javax.annotation.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.icps.model.Claimant;
import com.icps.service.ClaimantService;

/**
 * REST JSON controller exposing CRUD operations for {@link Claimant} records.
 *
 * <p>All persistence, validation (missing/invalid required fields), not-found
 * handling, and the "referenced by a Claim" delete guard are delegated to
 * {@link ClaimantService} and surfaced to callers via
 * {@link com.icps.exception.GlobalErrorHandler} (Requirements 2.3, 2.4, 2.5).</p>
 *
 * @see Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 15.6
 */
@RestController
@RequestMapping("/api/claimants")
public class ClaimantRestController {

    @Resource
    private ClaimantService claimantService;

    /**
     * Lists all Claimant records.
     *
     * @return all persisted Claimants
     */
    @GetMapping
    public List<Claimant> findAll() {
        return claimantService.findAll();
    }

    /**
     * Reads a single Claimant by identifier.
     *
     * @param id the Claimant identifier
     * @return the matching Claimant's current field values
     * @see Requirements 2.4, 2.6
     */
    @GetMapping("/{id}")
    public Claimant findById(@PathVariable Long id) {
        return claimantService.findById(id);
    }

    /**
     * Creates a new Claimant.
     *
     * @param claimant the Claimant payload
     * @return 201 Created with the persisted Claimant, including its
     *         generated identifier
     * @see Requirements 2.2, 2.3
     */
    @PostMapping
    public ResponseEntity<Claimant> create(@RequestBody Claimant claimant) {
        Claimant created = claimantService.create(claimant);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    /**
     * Updates an existing Claimant.
     *
     * @param id       the Claimant identifier to update
     * @param claimant the new field values
     * @return the persisted Claimant
     * @see Requirements 2.2, 2.3, 2.4
     */
    @PutMapping("/{id}")
    public Claimant update(@PathVariable Long id, @RequestBody Claimant claimant) {
        return claimantService.update(id, claimant);
    }

    /**
     * Deletes a Claimant by identifier, rejected if the Claimant is
     * referenced by at least one existing Claim.
     *
     * @param id the Claimant identifier to delete
     * @return 204 No Content on success
     * @see Requirements 2.4, 2.5
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        claimantService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
