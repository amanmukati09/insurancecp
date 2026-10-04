# ICPS - Insurance Claims Processing System

## 1. Overview

ICPS (Insurance Claims Processing System) is a from-scratch, legacy-representative Java web
application built as a **test fixture for legacy-modernization tooling**. It is not a port of
an existing system - it is an original ~20,000 LOC application deliberately built to resemble
authentic legacy Java enterprise code, including intentional legacy code smells, mixed
persistence strategies, and a mix of server-rendered JSP screens and REST JSON APIs.

ICPS covers the end-to-end insurance claims lifecycle: First Notice of Loss (FNOL) intake,
adjuster assignment, damage assessment, reserve tracking, settlement processing, status
lifecycle management, fraud flagging, litigation tracking, subrogation recovery, and claims
reporting.

**Stack:**

- Java 8
- Spring MVC 5.3.x (plain Spring, **not** Spring Boot) - XML (`applicationContext.xml`,
  `spring-mvc-servlet.xml`) + annotation-based (`WebMvcConfig`) configuration
- Hibernate 5 (entity CRUD for `Claimant`, `Adjuster`, `Document_Metadata`)
- Spring JDBC / `SimpleJdbcCall` (all other entities, invoking stored procedures exclusively)
- MySQL 8.x - 23 tables, 200 stored procedures/functions (CRUD, lifecycle, reporting)
- Apache Tomcat 9 (WAR deployment)
- Logback (logging)
- Maven (build)
- JUnit 4 + jqwik (property-based tests)

All build, database setup, deployment, and verification steps below were performed on a
**remote Linux (Amazon Linux, EC2) host** - nothing was built or run on a local workstation.
Project working directory on the remote host: `/home/ec2-user/icps`.

## 2. Prerequisites

- Java 8 JDK (Amazon Corretto 8 was used on the build host: `/usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64`)
- Maven 3.6+ (Maven 3.8.4 was used)
- MySQL 8.x server
- Tomcat 9

On the EC2 build host, multiple JDKs were installed side by side (8, 17, 21); Java 8 was
selected explicitly via `JAVA_HOME` for the build (see Section 5) rather than relying on
whatever `java` resolves to by default.

## 3. Database setup

All commands below are run on the database host (same EC2 instance in this deployment) with
a MySQL 8.x server already installed and running.

### 3.1 Create the database and application user

```sql
CREATE DATABASE icps CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE USER 'icps_app'@'localhost' IDENTIFIED BY '<password>';
GRANT ALL PRIVILEGES ON icps.* TO 'icps_app'@'localhost';
FLUSH PRIVILEGES;
```

In this deployment the application user is `icps_app`, scoped to the `icps` schema only
(not a global/root account).

### 3.2 Load the DDL (run in order)

All SQL scripts live under `src/main/resources/db/`. Load the DDL files first, in numeric
order - later scripts have foreign keys into tables created by earlier ones:

```bash
mysql -u icps_app -p icps < src/main/resources/db/01_ddl_core.sql
mysql -u icps_app -p icps < src/main/resources/db/02_ddl_financial.sql
mysql -u icps_app -p icps < src/main/resources/db/03_ddl_fraud_doc_litigation_subrogation.sql
mysql -u icps_app -p icps < src/main/resources/db/04_ddl_lookup_audit.sql
```

| File | Contents |
|---|---|
| `01_ddl_core.sql` | `claimant`, `adjuster`, `policy_reference`, `claim`, `claim_status_history`, `claim_adjuster_assignment_history` |
| `02_ddl_financial.sql` | `damage_assessment`, `reserve`, `reserve_history`, `settlement` |
| `03_ddl_fraud_doc_litigation_subrogation.sql` | `fraud_flag`, `fraud_score`, `fraud_score_config`, `document_metadata`, `document_type_lookup`, `litigation_record`, `subrogation_record` |
| `04_ddl_lookup_audit.sql` | `app_user`, `claim_status_transition_rule`, `report_cache_adjuster_caseload`, `report_cache_claims_aging`, `audit_log`, `sp_execution_log` |

Verify all 23 tables exist:

```bash
mysql -u icps_app -p icps -e "SHOW TABLES;"
```

### 3.3 Load the stored procedures (run in order)

Stored procedures are split into CRUD (10-14), lifecycle (20-24), and reporting (30-32)
script groups. Load them in this exact order:

```bash
# CRUD procedures (132 total)
mysql -u icps_app -p icps < src/main/resources/db/10_sp_crud_claimant_adjuster_policy.sql
mysql -u icps_app -p icps < src/main/resources/db/11_sp_crud_claim_history.sql
mysql -u icps_app -p icps < src/main/resources/db/12_sp_crud_damage_reserve.sql
mysql -u icps_app -p icps < src/main/resources/db/13_sp_crud_settlement_fraud.sql
mysql -u icps_app -p icps < src/main/resources/db/14_sp_crud_document_litigation_subrogation.sql

# Lifecycle business-logic procedures (35 total)
mysql -u icps_app -p icps < src/main/resources/db/20_sp_lifecycle_claim_transitions.sql
mysql -u icps_app -p icps < src/main/resources/db/21_sp_lifecycle_cursor_integrity.sql
mysql -u icps_app -p icps < src/main/resources/db/22_sp_lifecycle_fraud_subrogation.sql
mysql -u icps_app -p icps < src/main/resources/db/23_sp_lifecycle_reserve_settlement.sql
mysql -u icps_app -p icps < src/main/resources/db/24_sp_lifecycle_validation_helpers.sql

# Reporting procedures (23 total)
mysql -u icps_app -p icps < src/main/resources/db/30_sp_report_primary.sql
mysql -u icps_app -p icps < src/main/resources/db/31_sp_report_supporting.sql
mysql -u icps_app -p icps < src/main/resources/db/32_sp_report_additional.sql
```

### 3.4 Load seed data (run in order)

```bash
mysql -u icps_app -p icps < src/main/resources/db/40_seed_reference_lookup.sql
mysql -u icps_app -p icps < src/main/resources/db/41_seed_claims_financial.sql
mysql -u icps_app -p icps < src/main/resources/db/42_seed_fraud_document_litigation_subrogation.sql
```

Seed data includes 100+ Claims distributed across all six statuses (at least 10 per status),
8 Adjusters (at least one inactive), 40+ Policy References, damage assessments, reserves,
settlements for Settled/Closed claims, fraud flags, documents, litigation records, and
subrogation records.

### 3.5 Verify the procedure count

```bash
mysql -u icps_app -p icps -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='icps' AND routine_type='PROCEDURE';"
```

Expected result: **200**.

## 4. DataSource configuration

The DataSource is configured in
`src/main/webapp/WEB-INF/spring/applicationContext.xml`:

```xml
<bean id="dataSource" class="org.apache.commons.dbcp2.BasicDataSource" destroy-method="close">
    <property name="driverClassName" value="com.mysql.cj.jdbc.Driver" />
    <property name="url" value="jdbc:mysql://localhost:3306/icps?useSSL=false&amp;serverTimezone=UTC" />
    <property name="username" value="icps_app" />
    <property name="password" value="..." />
    <property name="initialSize" value="5" />
    <property name="maxTotal" value="20" />
</bean>
```

**The connection URL, username, and password are hardcoded directly in this XML file.** This
is an intentional, legacy-style choice for this test fixture (ICPS is meant to resemble an
authentic older-generation Spring XML application, and modernization tooling benefits from
having a concrete hardcoded-credentials pattern to detect). It is **not** how a real
production deployment should be configured.

**Improvement area for a real deployment:** externalize these values - e.g. via a
`PropertyPlaceholderConfigurer`/`.properties` file outside source control, environment
variables, JNDI `DataSource` lookup from the Tomcat container, or a secrets manager - rather
than committing credentials into `applicationContext.xml`.

## 5. Build

Java 8 must be selected explicitly for the Maven build. On the EC2 build host, Corretto 8 is
installed at `/usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64` (this path is distro-dependent -
on other hosts/distros it may be e.g. `/usr/lib/jvm/java-8-openjdk-amd64`):

```bash
JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64 mvn clean package
```

This runs the full JUnit 4 test suite (19 tests, including jqwik property-based tests) as
part of the `package` phase and produces `target/icps.war`. The build must complete with zero
test failures before proceeding to deployment.

## 6. Deploy to Tomcat 9

Tomcat 9 is installed at `/opt/tomcat9` (`CATALINA_HOME`) and runs as the `tomcat9` systemd
service on this host.

```bash
cp target/icps.war /opt/tomcat9/webapps/icps.war
sudo systemctl restart tomcat9
```

Tomcat's exploded-webapp auto-deploy will also pick up a dropped-in WAR without a restart, but
restarting guarantees a clean context reload. After deployment, tail the logs to confirm clean
startup:

```bash
tail -f /opt/tomcat9/logs/icps.log
tail -f /opt/tomcat9/logs/catalina.out
```

The application is then available at:

```
http://<host>:8080/icps/
```

## 7. Verify

### 7.1 JSP screens (server-rendered views)

- `GET /icps/claims/new` - FNOL claim intake form
- `GET /icps/claims/{claimId}` - claim detail/status view
- `GET /icps/adjusters/{adjusterId}/worklist` - adjuster worklist
- `GET /icps/claims/{claimId}/settlement` - settlement approval screen

### 7.2 REST JSON API

- `/icps/api/claimants`
- `/icps/api/adjusters`
- `/icps/api/claims` (incl. `/icps/api/claims/{claimId}/status-transitions`, `/icps/api/claims/{claimId}/status-history`)
- `/icps/api/policy-references`
- `/icps/api/claims/{claimId}/damage-assessments`
- `/icps/api/claims/{claimId}/reserve`
- `/icps/api/claims/{claimId}/settlement`
- `/icps/api/claims/{claimId}/fraud-flags`
- `/icps/api/claims/{claimId}/documents`
- `/icps/api/claims/{claimId}/litigation-records`
- `/icps/api/claims/{claimId}/subrogation-records`
- `/icps/api/reports/*` (adjuster-caseload, claims-aging, reserve-adequacy, fraud-summary, subrogation)

All endpoints were verified against the seeded database with `curl` as part of the deployment
checkpoint, confirming HTTP 200 for the JSP screens and returned field values matching the
corresponding seed records for the REST endpoints.

## 8. Project structure

```
icps/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/com/icps/
│   │   │   ├── config/          Spring Java config (WebMvcConfig)
│   │   │   ├── controller/      JSP (ModelAndView) + @RestController classes
│   │   │   ├── dao/
│   │   │   │   ├── hibernate/   Hibernate DAO impls (Claimant, Adjuster, Document_Metadata)
│   │   │   │   └── jdbc/        SimpleJdbcCall DAO impls (all stored-procedure-backed entities)
│   │   │   ├── dto/
│   │   │   ├── exception/       GlobalErrorHandler (@ControllerAdvice) + custom exceptions
│   │   │   ├── model/           Hibernate entities + JDBC POJOs
│   │   │   │   └── rowmapper/   RowMapper classes for JDBC DAOs
│   │   │   ├── service/         business services (interfaces)
│   │   │   │   └── impl/        business service implementations
│   │   │   └── util/            ClaimFormatUtil, RegionPolicyRuleHelper
│   │   ├── resources/
│   │   │   ├── db/              DDL, stored procedure, and seed SQL scripts (01-42)
│   │   │   └── spring/          logback.xml, other resource-level config
│   │   └── webapp/
│   │       └── WEB-INF/
│   │           ├── spring/      applicationContext.xml, spring-mvc-servlet.xml
│   │           └── views/       claimIntakeForm.jsp, claimDetail.jsp, adjusterWorklist.jsp, settlementApproval.jsp
│   └── test/
│       └── java/com/icps/       JUnit 4 + jqwik tests
└── target/
    └── icps.war                build output
```

## 9. Known limitations / intentional legacy characteristics

These are **by design**, not oversights - ICPS exists to give legacy-modernization tooling
realistic patterns to detect and reason about:

- **`ClaimFormatUtil`** - a static utility class (currency formatting, date formatting,
  claim-identifier generation/parsing) called from multiple controller/service classes, a
  classic legacy static-helper smell.
- **`RegionPolicyRuleHelper`** - a branching helper class (`getHandlingRule`) that switches on
  claimant address state and policy type, representing legacy embedded business-rule
  branching outside a rules engine.
- **`SettlementApprovalController`** - contains an embedded `if/else` branch on claim status
  plus an inline penny-reconciliation proration calculation directly in the controller method
  body, rather than being fully delegated to the service layer.
- **`GlobalErrorHandler`** - includes a broad `catch (Exception e)` fallback handler alongside
  its specific exception handlers, representing the common legacy "catch-all at the top"
  pattern; it logs via Logback and returns a generic response without leaking exception
  details.
- **Hardcoded DataSource credentials** in `applicationContext.xml` (see Section 4) - kept
  intentionally for this fixture, flagged as an improvement area for real deployments.
- **Absolute Logback file path** (`/opt/tomcat9/logs/icps.log`) in `logback.xml` - tied to this
  specific Tomcat installation path rather than a container-relative or externally configured
  path; a real multi-environment deployment should externalize this (e.g. via a
  `CATALINA_BASE`-relative path or system property).
