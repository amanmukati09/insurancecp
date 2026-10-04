-- =============================================================================
-- 14_sp_crud_document_litigation_subrogation.sql
-- Insurance Claims Processing System (ICPS)
--
-- CRUD + finder stored procedures for: document_metadata, litigation_record,
-- subrogation_record (31 procedures total: 10 + 10 + 11).
--
-- LOAD ORDER: Run after 01_ddl_core.sql through 04_ddl_lookup_audit.sql have
-- created all 23 tables (document_metadata / document_type_lookup /
-- litigation_record / subrogation_record are defined in
-- 03_ddl_fraud_doc_litigation_subrogation.sql).
--
-- Requirement 11.2/11.3/16.3 note: sp_sub_create performs the raw insert only.
-- Validation of Claim status (Settled/Closed) and recovery amount range
-- (0.01..net_paid_amount) is enforced by the lifecycle procedure
-- sp_subrogation_record_create (task 5.3), which composes sp_sub_create and
-- sp_sub_validate_claim_status after performing its own checks.
--
-- Requirements: 16.3 (>=10 CRUD procedures per entity), 9.1 (Document_Metadata
-- CRUD), 9.3 (document_type system-defined list validation), 10.1 (Litigation
-- Record CRUD), 11.1 (Subrogation_Record CRUD).
-- =============================================================================

-- #############################################################################
-- ## DOCUMENT_METADATA (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_dm_create: insert a new Document_Metadata row for a Claim.
-- Requirement 9.2: file_name/document_type/file_size_bytes/storage_reference
-- length/range validation is enforced by the table's column lengths and the
-- chk_dm_file_size CHECK constraint plus the fk_dm_document_type FK; this
-- procedure performs the insert and returns the new identifier.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_create(
    IN p_claim_id BIGINT,
    IN p_file_name VARCHAR(255),
    IN p_document_type VARCHAR(50),
    IN p_file_size_bytes BIGINT,
    IN p_storage_reference VARCHAR(500),
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO document_metadata (
        claim_id, file_name, document_type, file_size_bytes, storage_reference, uploaded_at
    ) VALUES (
        p_claim_id, p_file_name, p_document_type, p_file_size_bytes, p_storage_reference, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_read: fetch a single Document_Metadata row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_read(
    IN p_document_metadata_id BIGINT
)
BEGIN
    SELECT document_metadata_id, claim_id, file_name, document_type,
           file_size_bytes, storage_reference, uploaded_at
    FROM document_metadata
    WHERE document_metadata_id = p_document_metadata_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_update: update the mutable fields of a Document_Metadata row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_update(
    IN p_document_metadata_id BIGINT,
    IN p_file_name VARCHAR(255),
    IN p_document_type VARCHAR(50),
    IN p_file_size_bytes BIGINT,
    IN p_storage_reference VARCHAR(500)
)
BEGIN
    UPDATE document_metadata
    SET file_name = p_file_name,
        document_type = p_document_type,
        file_size_bytes = p_file_size_bytes,
        storage_reference = p_storage_reference
    WHERE document_metadata_id = p_document_metadata_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_delete: delete a Document_Metadata row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_delete(
    IN p_document_metadata_id BIGINT
)
BEGIN
    DELETE FROM document_metadata WHERE document_metadata_id = p_document_metadata_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_list_by_claim: list all Document_Metadata rows for a Claim.
-- Requirement 9.5 (Claim detail view displays Document_Metadata records).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT document_metadata_id, claim_id, file_name, document_type,
           file_size_bytes, storage_reference, uploaded_at
    FROM document_metadata
    WHERE claim_id = p_claim_id
    ORDER BY uploaded_at DESC, document_metadata_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_find_by_type: find Document_Metadata rows across all Claims matching
-- a given document_type.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_find_by_type(
    IN p_document_type VARCHAR(50)
)
BEGIN
    SELECT document_metadata_id, claim_id, file_name, document_type,
           file_size_bytes, storage_reference, uploaded_at
    FROM document_metadata
    WHERE document_type = p_document_type
    ORDER BY uploaded_at DESC, document_metadata_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_count_by_claim: count Document_Metadata rows for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_count_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_total
    FROM document_metadata
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_exists: check whether a Document_Metadata row exists for an id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_exists(
    IN p_document_metadata_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_flag
    FROM document_metadata
    WHERE document_metadata_id = p_document_metadata_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_validate_type: check whether a document_type value exists in the
-- system-defined document_type_lookup table.
-- Requirement 9.3: enforces the system-defined document type list.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_validate_type(
    IN p_document_type VARCHAR(50),
    OUT p_is_valid TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_is_valid
    FROM document_type_lookup
    WHERE document_type = p_document_type;
END$$

-- -----------------------------------------------------------------------------
-- sp_dm_total_size_by_claim: sum file_size_bytes for a Claim's
-- Document_Metadata rows. Returns 0 (not NULL) when the Claim has no
-- Document_Metadata rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_dm_total_size_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total_bytes BIGINT
)
BEGIN
    SELECT COALESCE(SUM(file_size_bytes), 0)
    INTO p_total_bytes
    FROM document_metadata
    WHERE claim_id = p_claim_id;
END$$

DELIMITER ;

-- #############################################################################
-- ## LITIGATION_RECORD (10 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_lit_create: insert a new Litigation_Record row for a Claim.
-- Requirement 10.2: case_reference (<=100 chars) and filing_date presence
-- are enforced by the table's NOT NULL / length constraints; this procedure
-- performs the insert and returns the new identifier.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_create(
    IN p_claim_id BIGINT,
    IN p_case_reference VARCHAR(100),
    IN p_filing_date DATE,
    IN p_status VARCHAR(30),
    IN p_attorney_name VARCHAR(150),
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO litigation_record (
        claim_id, case_reference, filing_date, status, attorney_name, created_at
    ) VALUES (
        p_claim_id, p_case_reference, p_filing_date, p_status, p_attorney_name, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_read: fetch a single Litigation_Record row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_read(
    IN p_litigation_record_id BIGINT
)
BEGIN
    SELECT litigation_record_id, claim_id, case_reference, filing_date,
           status, attorney_name, created_at
    FROM litigation_record
    WHERE litigation_record_id = p_litigation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_update: update the mutable fields of a Litigation_Record row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_update(
    IN p_litigation_record_id BIGINT,
    IN p_case_reference VARCHAR(100),
    IN p_filing_date DATE,
    IN p_status VARCHAR(30),
    IN p_attorney_name VARCHAR(150)
)
BEGIN
    UPDATE litigation_record
    SET case_reference = p_case_reference,
        filing_date = p_filing_date,
        status = p_status,
        attorney_name = p_attorney_name
    WHERE litigation_record_id = p_litigation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_delete: delete a Litigation_Record row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_delete(
    IN p_litigation_record_id BIGINT
)
BEGIN
    DELETE FROM litigation_record WHERE litigation_record_id = p_litigation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_list_by_claim: list all Litigation_Record rows for a Claim.
-- Requirement 10.4 (Claim detail view displays Litigation_Record entries).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT litigation_record_id, claim_id, case_reference, filing_date,
           status, attorney_name, created_at
    FROM litigation_record
    WHERE claim_id = p_claim_id
    ORDER BY filing_date DESC, litigation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_find_by_case_reference: find Litigation_Record rows matching a
-- case_reference value.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_find_by_case_reference(
    IN p_case_reference VARCHAR(100)
)
BEGIN
    SELECT litigation_record_id, claim_id, case_reference, filing_date,
           status, attorney_name, created_at
    FROM litigation_record
    WHERE case_reference = p_case_reference
    ORDER BY filing_date DESC, litigation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_exists_for_claim: check whether a Claim has any Litigation_Record
-- rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_exists_for_claim(
    IN p_claim_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_flag
    FROM litigation_record
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_count_by_claim: count Litigation_Record rows for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_count_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_total
    FROM litigation_record
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_find_by_date_range: find Litigation_Record rows with filing_date
-- within an inclusive date range.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_find_by_date_range(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT litigation_record_id, claim_id, case_reference, filing_date,
           status, attorney_name, created_at
    FROM litigation_record
    WHERE filing_date BETWEEN p_start_date AND p_end_date
    ORDER BY filing_date DESC, litigation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_lit_find_by_status: find Litigation_Record rows matching a status
-- value.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_lit_find_by_status(
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT litigation_record_id, claim_id, case_reference, filing_date,
           status, attorney_name, created_at
    FROM litigation_record
    WHERE status = p_status
    ORDER BY filing_date DESC, litigation_record_id DESC;
END$$

DELIMITER ;

-- #############################################################################
-- ## SUBROGATION_RECORD (11 procedures)
-- #############################################################################

DELIMITER $$

-- -----------------------------------------------------------------------------
-- sp_sub_create: insert a new Subrogation_Record row for a Claim.
-- Requirement 11.1: raw insert only. Validation of Claim status
-- (Settled/Closed, Req 11.2/11.3) and recovery amount range
-- (0.01..net_paid_amount, Req 11.4/11.5) is performed by the lifecycle
-- procedure sp_subrogation_record_create (task 5.3), which composes this
-- procedure and sp_sub_validate_claim_status after its own checks pass.
-- The table's chk_sub_recovery_amount CHECK constraint enforces the
-- recovery_amount >= 0.01 floor at the storage layer as a backstop.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_create(
    IN p_claim_id BIGINT,
    IN p_third_party_identifier VARCHAR(100),
    IN p_recovery_amount DECIMAL(12,2),
    IN p_recorded_date DATE,
    OUT p_new_id BIGINT
)
BEGIN
    INSERT INTO subrogation_record (
        claim_id, third_party_identifier, recovery_amount, recorded_date, created_at
    ) VALUES (
        p_claim_id, p_third_party_identifier, p_recovery_amount, p_recorded_date, NOW()
    );
    SET p_new_id = LAST_INSERT_ID();
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_read: fetch a single Subrogation_Record row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_read(
    IN p_subrogation_record_id BIGINT
)
BEGIN
    SELECT subrogation_record_id, claim_id, third_party_identifier,
           recovery_amount, recorded_date, created_at
    FROM subrogation_record
    WHERE subrogation_record_id = p_subrogation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_update: update the mutable fields of a Subrogation_Record row.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_update(
    IN p_subrogation_record_id BIGINT,
    IN p_third_party_identifier VARCHAR(100),
    IN p_recovery_amount DECIMAL(12,2),
    IN p_recorded_date DATE
)
BEGIN
    UPDATE subrogation_record
    SET third_party_identifier = p_third_party_identifier,
        recovery_amount = p_recovery_amount,
        recorded_date = p_recorded_date
    WHERE subrogation_record_id = p_subrogation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_delete: delete a Subrogation_Record row by id.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_delete(
    IN p_subrogation_record_id BIGINT
)
BEGIN
    DELETE FROM subrogation_record WHERE subrogation_record_id = p_subrogation_record_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_list_by_claim: list all Subrogation_Record rows for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_list_by_claim(
    IN p_claim_id BIGINT
)
BEGIN
    SELECT subrogation_record_id, claim_id, third_party_identifier,
           recovery_amount, recorded_date, created_at
    FROM subrogation_record
    WHERE claim_id = p_claim_id
    ORDER BY recorded_date DESC, subrogation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_find_by_third_party: find Subrogation_Record rows matching a
-- third_party_identifier value.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_find_by_third_party(
    IN p_third_party_identifier VARCHAR(100)
)
BEGIN
    SELECT subrogation_record_id, claim_id, third_party_identifier,
           recovery_amount, recorded_date, created_at
    FROM subrogation_record
    WHERE third_party_identifier = p_third_party_identifier
    ORDER BY recorded_date DESC, subrogation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_sum_recovered_by_claim: sum recovery_amount for a Claim's
-- Subrogation_Record rows. Returns 0.00 (not NULL) when the Claim has no
-- Subrogation_Record rows.
-- Requirement 11.7 (subrogation tracking report reflects recovered totals).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_sum_recovered_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total_recovered DECIMAL(12,2)
)
BEGIN
    SELECT COALESCE(SUM(recovery_amount), 0.00)
    INTO p_total_recovered
    FROM subrogation_record
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_exists_for_claim: check whether a Claim has any Subrogation_Record
-- rows.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_exists_for_claim(
    IN p_claim_id BIGINT,
    OUT p_flag TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_flag
    FROM subrogation_record
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_count_by_claim: count Subrogation_Record rows for a Claim.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_count_by_claim(
    IN p_claim_id BIGINT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_total
    FROM subrogation_record
    WHERE claim_id = p_claim_id;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_find_by_date_range: find Subrogation_Record rows with recorded_date
-- within an inclusive date range.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_find_by_date_range(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT subrogation_record_id, claim_id, third_party_identifier,
           recovery_amount, recorded_date, created_at
    FROM subrogation_record
    WHERE recorded_date BETWEEN p_start_date AND p_end_date
    ORDER BY recorded_date DESC, subrogation_record_id DESC;
END$$

-- -----------------------------------------------------------------------------
-- sp_sub_validate_claim_status: check whether a Claim's current status is
-- 'Settled' or 'Closed', the only statuses eligible for Subrogation_Record
-- creation.
-- Requirement 11.2/11.3: backs the lifecycle procedure's eligibility check.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_sub_validate_claim_status(
    IN p_claim_id BIGINT,
    OUT p_is_valid TINYINT(1)
)
BEGIN
    SELECT COUNT(*) > 0
    INTO p_is_valid
    FROM claim
    WHERE claim_id = p_claim_id
      AND status IN ('Settled', 'Closed');
END$$

DELIMITER ;
