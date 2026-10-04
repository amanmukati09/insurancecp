-- =============================================================================
-- ICPS Database DDL — Fraud, Document, Litigation, and Subrogation Tables
-- File: 03_ddl_fraud_doc_litigation_subrogation.sql
--
-- LOAD ORDER: This file MUST be loaded AFTER 01_ddl_core.sql (which defines
-- the `claim` table referenced by several FKs below) and may be loaded
-- before or after 02_ddl_financial.sql (no cross-dependencies on it).
--
-- Within this file, `document_type_lookup` is defined FIRST because
-- `document_metadata.document_type` has a foreign key referencing it.
--
-- Engine: InnoDB, Charset: utf8mb4 (MySQL 8.x)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: document_type_lookup
-- System-defined list of valid document types for document_metadata.
-- Seed values (POLICE_REPORT, PHOTO, ESTIMATE, CORRESPONDENCE, MEDICAL_RECORD,
-- INVOICE) are inserted later in task 7 (seed data).
-- -----------------------------------------------------------------------------
CREATE TABLE document_type_lookup (
    document_type VARCHAR(50) NOT NULL,
    description   VARCHAR(200) NULL,
    PRIMARY KEY (document_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Table: fraud_flag
-- A record indicating a Claim has been flagged for suspected fraud, with
-- associated scoring factors. Supports active/inactive status (Req 8.1).
-- -----------------------------------------------------------------------------
CREATE TABLE fraud_flag (
    fraud_flag_id BIGINT NOT NULL AUTO_INCREMENT,
    claim_id      BIGINT NOT NULL,
    flag_reason   VARCHAR(200) NOT NULL,
    score_weight  INT NOT NULL,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL,
    updated_at    DATETIME NOT NULL,
    PRIMARY KEY (fraud_flag_id),
    CONSTRAINT fk_ff_claim FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_ff_score_weight CHECK (score_weight BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_ff_claim ON fraud_flag (claim_id, is_active);

-- -----------------------------------------------------------------------------
-- Table: fraud_score
-- One row per Claim; current fraud score snapshot (0-100), recomputed in
-- place by sp_fraud_score_recompute (Req 8.3, 8.4, 8.5).
-- -----------------------------------------------------------------------------
CREATE TABLE fraud_score (
    claim_id       BIGINT NOT NULL,
    score          INT NOT NULL,
    threshold_used INT NOT NULL DEFAULT 70,
    computed_at    DATETIME NOT NULL,
    PRIMARY KEY (claim_id),
    CONSTRAINT fk_fs_claim FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_fs_score CHECK (score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Table: fraud_score_config
-- Key/value configuration, e.g. ('FRAUD_REVIEW_THRESHOLD','70') (Req 8.4).
-- Seed values are inserted later in task 7.
-- -----------------------------------------------------------------------------
CREATE TABLE fraud_score_config (
    config_key   VARCHAR(50) NOT NULL,
    config_value VARCHAR(50) NOT NULL,
    PRIMARY KEY (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Table: document_metadata
-- Metadata describing an attachment associated with a Claim (Req 9.1-9.5).
-- `document_type` FKs to document_type_lookup to enforce the system-defined
-- list (Req 9.3).
-- -----------------------------------------------------------------------------
CREATE TABLE document_metadata (
    document_metadata_id BIGINT NOT NULL AUTO_INCREMENT,
    claim_id             BIGINT NOT NULL,
    file_name            VARCHAR(255) NOT NULL,
    document_type        VARCHAR(50) NOT NULL,
    file_size_bytes       BIGINT NOT NULL,
    storage_reference    VARCHAR(500) NOT NULL,
    uploaded_at           DATETIME NOT NULL,
    PRIMARY KEY (document_metadata_id),
    CONSTRAINT fk_dm_claim FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT fk_dm_document_type FOREIGN KEY (document_type) REFERENCES document_type_lookup (document_type),
    CONSTRAINT chk_dm_file_size CHECK (file_size_bytes BETWEEN 0 AND 2147483647)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_dm_claim ON document_metadata (claim_id);

-- -----------------------------------------------------------------------------
-- Table: litigation_record
-- Tracks legal proceedings associated with a Claim (Req 10.1-10.4).
-- -----------------------------------------------------------------------------
CREATE TABLE litigation_record (
    litigation_record_id BIGINT NOT NULL AUTO_INCREMENT,
    claim_id             BIGINT NOT NULL,
    case_reference        VARCHAR(100) NOT NULL,
    filing_date           DATE NOT NULL,
    status                VARCHAR(30) NULL,
    attorney_name         VARCHAR(150) NULL,
    created_at            DATETIME NOT NULL,
    PRIMARY KEY (litigation_record_id),
    CONSTRAINT fk_lit_claim FOREIGN KEY (claim_id) REFERENCES claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_lit_claim ON litigation_record (claim_id);

-- -----------------------------------------------------------------------------
-- Table: subrogation_record
-- Tracks recovery of claim payout amounts from a third party (Req 11.1-11.7).
-- -----------------------------------------------------------------------------
CREATE TABLE subrogation_record (
    subrogation_record_id   BIGINT NOT NULL AUTO_INCREMENT,
    claim_id                 BIGINT NOT NULL,
    third_party_identifier   VARCHAR(100) NOT NULL,
    recovery_amount           DECIMAL(12,2) NOT NULL,
    recorded_date             DATE NOT NULL,
    created_at                DATETIME NOT NULL,
    PRIMARY KEY (subrogation_record_id),
    CONSTRAINT fk_sub_claim FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_sub_recovery_amount CHECK (recovery_amount >= 0.01)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_sub_claim ON subrogation_record (claim_id);
