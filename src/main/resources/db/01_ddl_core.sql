-- =============================================================================
-- ICPS Database - 01_ddl_core.sql
-- Core claim-chain tables: claimant, adjuster, policy_reference, claim,
-- claim_status_history, claim_adjuster_assignment_history
--
-- Dialect: MySQL 8.x, InnoDB engine, utf8mb4 charset/collation.
--
-- LOAD ORDER NOTE:
--   This file is self-contained and can be run standalone against an empty
--   `icps` schema (all FKs referenced here are defined within this same file).
--   However, within the overall ICPS schema build, this file MUST be loaded
--   FIRST, before:
--     - 02_ddl_financial.sql          (damage_assessment, reserve, reserve_history,
--                                       settlement -> FK to claim)
--     - 03_ddl_fraud_document_litigation_subrogation.sql
--                                      (fraud_flag, fraud_score, document_metadata,
--                                       litigation_record, subrogation_record -> FK to claim)
--     - 04_ddl_lookup_config_audit.sql (app_user -> FK to adjuster;
--                                       claim_status_transition_rule, etc.)
--   Task 3.5 is responsible for executing all DDL files together in this order
--   against the real `icps` schema. Do NOT run this against the real schema
--   until the companion files are ready.
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. claimant
-- -----------------------------------------------------------------------------
CREATE TABLE claimant (
    claimant_id     BIGINT          NOT NULL AUTO_INCREMENT,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    address_line1   VARCHAR(200)    NULL,
    address_city    VARCHAR(100)    NULL,
    address_state   VARCHAR(2)      NOT NULL,
    address_zip     VARCHAR(10)     NULL,
    phone           VARCHAR(20)     NULL,
    email           VARCHAR(150)    NULL,
    created_at      DATETIME        NOT NULL,
    PRIMARY KEY (claimant_id),
    KEY idx_claimant_state (address_state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------------------------------
-- 2. adjuster
-- -----------------------------------------------------------------------------
CREATE TABLE adjuster (
    adjuster_id     BIGINT          NOT NULL AUTO_INCREMENT,
    username        VARCHAR(50)     NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL,
    PRIMARY KEY (adjuster_id),
    UNIQUE KEY uq_adjuster_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------------------------------
-- 3. policy_reference
-- -----------------------------------------------------------------------------
CREATE TABLE policy_reference (
    policy_reference_id    BIGINT          NOT NULL AUTO_INCREMENT,
    policy_number           VARCHAR(50)     NOT NULL,
    policy_type             VARCHAR(30)     NOT NULL,  -- e.g. AUTO / PROPERTY / LIABILITY
    coverage_limit           DECIMAL(12,2)   NOT NULL,
    deductible               DECIMAL(12,2)   NOT NULL,
    effective_start_date     DATE            NOT NULL,
    effective_end_date       DATE            NOT NULL,
    PRIMARY KEY (policy_reference_id),
    UNIQUE KEY uq_policy_number (policy_number),
    KEY idx_policy_number (policy_number),
    CONSTRAINT chk_policy_coverage_limit_nonneg CHECK (coverage_limit >= 0),
    CONSTRAINT chk_policy_deductible_nonneg CHECK (deductible >= 0),
    CONSTRAINT chk_policy_date_range CHECK (effective_end_date >= effective_start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------------------------------
-- 4. claim
-- -----------------------------------------------------------------------------
CREATE TABLE claim (
    claim_id              BIGINT          NOT NULL AUTO_INCREMENT,
    claimant_id            BIGINT          NOT NULL,
    policy_reference_id     BIGINT          NOT NULL,
    adjuster_id             BIGINT          NULL,
    loss_date               DATE            NOT NULL,
    loss_description         VARCHAR(2000)   NOT NULL,
    status                   VARCHAR(20)     NOT NULL,  -- Open/Investigating/Approved/Denied/Settled/Closed
    under_fraud_review       TINYINT(1)      NOT NULL DEFAULT 0,
    net_paid_amount          DECIMAL(12,2)   NULL,
    version                  INT             NOT NULL DEFAULT 0,  -- optimistic lock, Req 6.7
    created_at               DATETIME        NOT NULL,
    updated_at               DATETIME        NOT NULL,
    PRIMARY KEY (claim_id),
    KEY idx_claim_status (status),
    KEY idx_claim_adjuster (adjuster_id),
    KEY idx_claim_claimant (claimant_id),
    CONSTRAINT fk_claim_claimant
        FOREIGN KEY (claimant_id) REFERENCES claimant (claimant_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_claim_policy_reference
        FOREIGN KEY (policy_reference_id) REFERENCES policy_reference (policy_reference_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_claim_adjuster
        FOREIGN KEY (adjuster_id) REFERENCES adjuster (adjuster_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------------------------------
-- 5. claim_status_history
--
-- IMPORTANT (Req 14.3): This table is an append-only audit trail. It must
-- NEVER receive UPDATE or DELETE grants, and no application code path
-- (REST, JSP, batch, or administrative) may update or delete existing rows.
-- Only INSERT (via sp_claim_status_history_append / lifecycle procedures)
-- and SELECT access are permitted. Do not create update/delete stored
-- procedures against this table, and do not GRANT UPDATE/DELETE on it to
-- the application database user.
-- -----------------------------------------------------------------------------
CREATE TABLE claim_status_history (
    history_id      BIGINT          NOT NULL AUTO_INCREMENT,
    claim_id        BIGINT          NOT NULL,
    prior_status    VARCHAR(20)     NULL,
    new_status      VARCHAR(20)     NOT NULL,
    changed_by      VARCHAR(50)     NOT NULL,
    changed_at      DATETIME        NOT NULL,
    note            VARCHAR(500)    NULL,  -- used for adjuster-reassignment detail (Req 3.2/3.3)
    PRIMARY KEY (history_id),
    KEY idx_csh_claim (claim_id, changed_at),
    CONSTRAINT fk_csh_claim
        FOREIGN KEY (claim_id) REFERENCES claim (claim_id)
        ON DELETE CASCADE ON UPDATE RESTRICT
        -- CASCADE here is reserved for test-teardown convenience only; the
        -- application never exposes a Claim delete path that would trigger it
        -- for claims with history (see sp_claim_delete_cascade_admin, admin-only).
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -----------------------------------------------------------------------------
-- 6. claim_adjuster_assignment_history
-- -----------------------------------------------------------------------------
CREATE TABLE claim_adjuster_assignment_history (
    assignment_id       BIGINT          NOT NULL AUTO_INCREMENT,
    claim_id             BIGINT          NOT NULL,
    prior_adjuster_id     BIGINT          NULL,
    new_adjuster_id       BIGINT          NOT NULL,
    assigned_at           DATETIME        NOT NULL,
    PRIMARY KEY (assignment_id),
    KEY idx_caah_claim (claim_id),
    CONSTRAINT fk_caah_claim
        FOREIGN KEY (claim_id) REFERENCES claim (claim_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_caah_prior_adjuster
        FOREIGN KEY (prior_adjuster_id) REFERENCES adjuster (adjuster_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_caah_new_adjuster
        FOREIGN KEY (new_adjuster_id) REFERENCES adjuster (adjuster_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
