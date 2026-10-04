-- =============================================================================
-- 02_ddl_financial.sql
-- Insurance Claims Processing System (ICPS)
--
-- Financial tables: damage_assessment, reserve, reserve_history, settlement
--
-- LOAD ORDER: This file MUST be executed AFTER 01_ddl_core.sql.
-- All tables below carry a foreign key to `claim`, which is defined in
-- 01_ddl_core.sql. Running this file first will fail with an FK/unknown-table
-- error.
--
-- Engine: InnoDB, Charset: utf8mb4 (per design.md Architecture / Table
-- Inventory section). Monetary columns use DECIMAL(12,2) covering up to
-- 999,999,999.99 per Requirements 4/5. Timestamps use DATETIME.
--
-- Requirements: 16.1 (20-25 table schema), 16.2 (PK/FK/CHECK constraints and
-- indexes), 14.2 (reserve_history is insert-only; no UPDATE/DELETE grants).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: damage_assessment
-- One or more per Claim. Drives reserve recalculation (sp_da_sum_by_claim).
-- -----------------------------------------------------------------------------
CREATE TABLE damage_assessment (
    damage_assessment_id   BIGINT          NOT NULL AUTO_INCREMENT,
    claim_id                BIGINT          NOT NULL,
    estimated_cost          DECIMAL(12,2)   NOT NULL,
    description             VARCHAR(1000)   NOT NULL,
    assessment_date         DATE            NOT NULL,
    created_at               DATETIME        NOT NULL,
    PRIMARY KEY (damage_assessment_id),
    CONSTRAINT fk_da_claim
        FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_da_estimated_cost
        CHECK (estimated_cost > 0 AND estimated_cost <= 999999999.99)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_da_claim ON damage_assessment (claim_id);

-- -----------------------------------------------------------------------------
-- Table: reserve
-- Exactly one per Claim (claim_id is UNIQUE). Current + recommended amount.
-- -----------------------------------------------------------------------------
CREATE TABLE reserve (
    reserve_id              BIGINT          NOT NULL AUTO_INCREMENT,
    claim_id                BIGINT          NOT NULL,
    current_amount          DECIMAL(12,2)   NOT NULL,
    recommended_amount      DECIMAL(12,2)   NULL,
    updated_at               DATETIME        NOT NULL,
    PRIMARY KEY (reserve_id),
    CONSTRAINT uq_reserve_claim
        UNIQUE (claim_id),
    CONSTRAINT fk_reserve_claim
        FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_reserve_current_amount
        CHECK (current_amount > 0 AND current_amount <= 999999999.99)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Table: reserve_history
-- Append-only audit trail of Reserve amount changes.
--
-- Requirement 14.2 / 14.3: This table is INSERT-ONLY. No UPDATE or DELETE
-- statements, stored procedures, or application code paths may modify or
-- remove rows once written. This is enforced at the stored-procedure layer
-- (task 4.3: no sp_reserve_history_update / sp_reserve_history_delete
-- procedures are defined) and should additionally be enforced at the
-- database-user privilege level by granting only SELECT and INSERT (never
-- UPDATE/DELETE) on this table to the application's MySQL user.
-- -----------------------------------------------------------------------------
CREATE TABLE reserve_history (
    reserve_history_id      BIGINT          NOT NULL AUTO_INCREMENT,
    reserve_id               BIGINT          NOT NULL,
    prior_amount             DECIMAL(12,2)   NOT NULL,
    new_amount               DECIMAL(12,2)   NOT NULL,
    reason                   VARCHAR(500)    NOT NULL,
    changed_by               VARCHAR(50)     NOT NULL,
    changed_at               DATETIME        NOT NULL,
    PRIMARY KEY (reserve_history_id),
    CONSTRAINT fk_rh_reserve
        FOREIGN KEY (reserve_id) REFERENCES reserve (reserve_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_rh_reserve ON reserve_history (reserve_id, changed_at);

-- -----------------------------------------------------------------------------
-- Table: settlement
-- At most one per Claim (claim_id is UNIQUE) - enforces "only one Settlement
-- per Claim" (Req 7.4) at the DB level in addition to the service-layer check.
-- -----------------------------------------------------------------------------
CREATE TABLE settlement (
    settlement_id            BIGINT          NOT NULL AUTO_INCREMENT,
    claim_id                  BIGINT          NOT NULL,
    payout_amount             DECIMAL(12,2)   NOT NULL,
    approved_by                VARCHAR(50)     NOT NULL,
    approved_at                DATETIME        NOT NULL,
    PRIMARY KEY (settlement_id),
    CONSTRAINT uq_settlement_claim
        UNIQUE (claim_id),
    CONSTRAINT fk_settlement_claim
        FOREIGN KEY (claim_id) REFERENCES claim (claim_id),
    CONSTRAINT chk_settlement_payout_amount
        CHECK (payout_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
