-- =============================================================================
-- ICPS Database - 04_ddl_lookup_audit.sql
-- Lookup/config/audit/reporting-cache tables: app_user, claim_status_transition_rule,
-- report_cache_adjuster_caseload, report_cache_claims_aging, audit_log, sp_execution_log
--
-- Dialect: MySQL 8.x, InnoDB engine, utf8mb4 charset/collation.
--
-- LOAD ORDER NOTE:
--   `app_user` has a FK to `adjuster`, so this file MUST be loaded AFTER
--   01_ddl_core.sql (which defines `adjuster`). The remaining 5 tables in
--   this file (claim_status_transition_rule, report_cache_adjuster_caseload,
--   report_cache_claims_aging, audit_log, sp_execution_log) have no foreign
--   keys to tables defined in other modules' DDL files -- report_cache_adjuster_caseload
--   stores adjuster_id as a plain column value (no FK) since it is a disposable
--   materialized snapshot refreshed wholesale by the reporting procedure, not a
--   row with referential integrity requirements.
--   Overall load order: 01_ddl_core.sql, 02_ddl_financial.sql,
--   03_ddl_fraud_doc_litigation_subrogation.sql, then this file (04).
--   Task 3.5 is responsible for executing all DDL files together in this order
--   against the real `icps` schema. Do NOT run this against the real schema
--   until the companion files are ready.
-- =============================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;
-- -----------------------------------------------------------------------------
-- 1. app_user
--
-- Backs the authorization check in Req 5.3 (only Adjusters may set/adjust a
-- Reserve) and the adjuster worklist/login linkage in Req 3.5. adjuster_id is
-- nullable because non-adjuster roles (SUPERVISOR/CLERK/ADMIN/
-- SUBROGATION_SPECIALIST) have no corresponding adjuster row.
-- -----------------------------------------------------------------------------
CREATE TABLE app_user (
    user_id         BIGINT          NOT NULL AUTO_INCREMENT,
    username        VARCHAR(50)     NOT NULL,
    role            VARCHAR(30)     NOT NULL,  -- ADJUSTER/SUPERVISOR/CLERK/ADMIN/SUBROGATION_SPECIALIST
    adjuster_id     BIGINT          NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_app_user_username (username),
    KEY idx_app_user_adjuster (adjuster_id),
    CONSTRAINT fk_app_user_adjuster
        FOREIGN KEY (adjuster_id) REFERENCES adjuster (adjuster_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- -----------------------------------------------------------------------------
-- 2. claim_status_transition_rule
--
-- Pure lookup table defining the allowed Claim status transition graph
-- (Req 6.2): Open -> Investigating; Investigating -> Approved or Denied;
-- Approved -> Settled; Settled -> Closed; Denied -> Closed. Used by
-- sp_claim_transition_status to validate a requested transition instead of
-- hardcoding the graph in SQL/Java. Seed rows (the 5 allowed pairs) are
-- inserted later as part of task 7's seed data -- this table is defined
-- empty here.
-- -----------------------------------------------------------------------------
CREATE TABLE claim_status_transition_rule (
    prior_status    VARCHAR(20)     NOT NULL,
    new_status      VARCHAR(20)     NOT NULL,
    PRIMARY KEY (prior_status, new_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- -----------------------------------------------------------------------------
-- 3. report_cache_adjuster_caseload
--
-- Materialization table used by sp_report_adjuster_caseload (Req 13.1) for
-- atomic snapshotting: the procedure truncates/repopulates this table in one
-- transaction so readers never see a partial report. adjuster_id is a plain
-- BIGINT (not a FK) since this is a disposable cache rebuilt wholesale on
-- every report run.
-- -----------------------------------------------------------------------------
CREATE TABLE report_cache_adjuster_caseload (
    adjuster_id         BIGINT          NOT NULL,
    open_claim_count    INT             NOT NULL,
    generated_at        DATETIME        NOT NULL,
    PRIMARY KEY (adjuster_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- -----------------------------------------------------------------------------
-- 4. report_cache_claims_aging
--
-- Materialization table used by sp_report_claims_aging (Req 13.2). Fixed set
-- of 4 aging buckets based on DATEDIFF(CURDATE(), loss_date).
-- -----------------------------------------------------------------------------
CREATE TABLE report_cache_claims_aging (
    aging_bucket    VARCHAR(10)     NOT NULL,  -- '0-30' / '31-60' / '61-90' / '91+'
    claim_count     INT             NOT NULL,
    generated_at    DATETIME        NOT NULL,
    PRIMARY KEY (aging_bucket)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- -----------------------------------------------------------------------------
-- 5. audit_log
--
-- General-purpose audit sink written by several of the >=30 lifecycle
-- procedures (Req 16.5's transaction-control/error-handling procedures log
-- business-level audit events here). entity_name/entity_id form a generic
-- polymorphic reference (no FK) since this table spans every entity type.
-- -----------------------------------------------------------------------------
CREATE TABLE audit_log (
    audit_id        BIGINT          NOT NULL AUTO_INCREMENT,
    entity_name     VARCHAR(50)     NOT NULL,
    entity_id       BIGINT          NOT NULL,
    action          VARCHAR(20)     NOT NULL,
    performed_by    VARCHAR(50)     NOT NULL,
    performed_at    DATETIME        NOT NULL,
    detail          VARCHAR(1000)   NULL,
    PRIMARY KEY (audit_id),
    KEY idx_audit_entity (entity_name, entity_id),
    KEY idx_audit_performed_at (performed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- -----------------------------------------------------------------------------
-- 6. sp_execution_log
--
-- Written by the transaction-controlled procedures' SQLEXCEPTION handlers
-- (Req 16.5) to record stored procedure execution outcomes, independent of
-- the business-level audit_log above.
-- -----------------------------------------------------------------------------
CREATE TABLE sp_execution_log (
    log_id              BIGINT          NOT NULL AUTO_INCREMENT,
    procedure_name      VARCHAR(100)    NOT NULL,
    status               VARCHAR(10)     NOT NULL,  -- SUCCESS/FAILURE
    error_message        VARCHAR(1000)   NULL,
    executed_at           DATETIME        NOT NULL,
    PRIMARY KEY (log_id),
    KEY idx_sp_exec_procedure (procedure_name, executed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
