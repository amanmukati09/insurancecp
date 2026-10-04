-- =============================================================================
-- ICPS Database - 40_seed_reference_lookup.sql
-- Seed data for reference and lookup tables: claimant, adjuster,
-- policy_reference, claim_status_transition_rule, fraud_score_config,
-- document_type_lookup.
--
-- Requirements: 16.7, 17.6
--
-- LOAD ORDER NOTE: This file has no FK dependencies on claim-chain data
-- (claim, damage_assessment, etc.) and must be loaded BEFORE 41/42 (claims
-- and dependent financial/audit/fraud/document/litigation/subrogation seed
-- files), which reference claimant_id/adjuster_id/policy_reference_id
-- generated here. Run after all DDL files (01-04) have been executed.
--
-- All data below is synthetic / fabricated for test-fixture purposes only.
-- No real PII is used.
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- 1. claimant (60 rows)
--
-- Varied first_name/last_name/address_city/address_state/address_zip/phone/
-- email/created_at (spread over the last 2 years). At least 15 of the 60
-- rows use "high litigation" states (CA, FL, NY, IL) to support
-- RegionPolicyRuleHelper branching tests.
-- -----------------------------------------------------------------------------
INSERT INTO claimant
    (first_name, last_name, address_line1, address_city, address_state, address_zip, phone, email, created_at)
VALUES
    ('James',    'Walker',      '12 Maple St',       'Los Angeles',   'CA', '90012', '213-555-0101', 'james.walker01@example.com',    DATE_SUB(NOW(), INTERVAL 720 DAY)),
    ('Maria',    'Garcia',      '45 Sunset Blvd',     'San Diego',     'CA', '92101', '619-555-0102', 'maria.garcia02@example.com',    DATE_SUB(NOW(), INTERVAL 705 DAY)),
    ('Robert',   'Nguyen',      '78 Ocean Ave',       'Miami',         'FL', '33101', '305-555-0103', 'robert.nguyen03@example.com',   DATE_SUB(NOW(), INTERVAL 690 DAY)),
    ('Linda',    'Smith',       '301 Palm Dr',        'Orlando',       'FL', '32801', '407-555-0104', 'linda.smith04@example.com',     DATE_SUB(NOW(), INTERVAL 675 DAY)),
    ('Michael',  'Johnson',     '19 Broadway',        'New York',      'NY', '10001', '212-555-0105', 'michael.johnson05@example.com', DATE_SUB(NOW(), INTERVAL 660 DAY)),
    ('Patricia', 'Williams',    '88 Fifth Ave',       'Buffalo',       'NY', '14201', '716-555-0106', 'patricia.williams06@example.com', DATE_SUB(NOW(), INTERVAL 645 DAY)),
    ('David',    'Brown',       '55 LaSalle St',      'Chicago',       'IL', '60601', '312-555-0107', 'david.brown07@example.com',      DATE_SUB(NOW(), INTERVAL 630 DAY)),
    ('Barbara',  'Davis',       '140 State St',       'Springfield',   'IL', '62701', '217-555-0108', 'barbara.davis08@example.com',    DATE_SUB(NOW(), INTERVAL 615 DAY)),
    ('Richard',  'Miller',      '23 Elm St',          'Sacramento',    'CA', '95814', '916-555-0109', 'richard.miller09@example.com',   DATE_SUB(NOW(), INTERVAL 600 DAY)),
    ('Susan',    'Wilson',      '67 Pine Rd',         'Tampa',         'FL', '33602', '813-555-0110', 'susan.wilson10@example.com',     DATE_SUB(NOW(), INTERVAL 585 DAY)),
    ('Joseph',   'Moore',       '91 Riverside Dr',    'Albany',        'NY', '12201', '518-555-0111', 'joseph.moore11@example.com',     DATE_SUB(NOW(), INTERVAL 570 DAY)),
    ('Jessica',  'Taylor',      '14 Lakeshore Dr',    'Peoria',        'IL', '61602', '309-555-0112', 'jessica.taylor12@example.com',   DATE_SUB(NOW(), INTERVAL 555 DAY)),
    ('Thomas',   'Anderson',    '33 Hollywood Blvd',  'Burbank',       'CA', '91502', '818-555-0113', 'thomas.anderson13@example.com',  DATE_SUB(NOW(), INTERVAL 540 DAY)),
    ('Karen',    'Thomas',      '72 Bayshore Dr',     'Jacksonville',  'FL', '32202', '904-555-0114', 'karen.thomas14@example.com',     DATE_SUB(NOW(), INTERVAL 525 DAY)),
    ('Charles',  'Jackson',     '8 Hudson St',        'Rochester',     'NY', '14604', '585-555-0115', 'charles.jackson15@example.com',  DATE_SUB(NOW(), INTERVAL 510 DAY)),
    ('Nancy',    'White',       '150 Michigan Ave',   'Naperville',    'IL', '60540', '630-555-0116', 'nancy.white16@example.com',      DATE_SUB(NOW(), INTERVAL 495 DAY)),
    ('Christopher', 'Harris',   '29 Redwood Dr',      'Fresno',        'CA', '93650', '559-555-0117', 'christopher.harris17@example.com', DATE_SUB(NOW(), INTERVAL 480 DAY)),
    ('Betty',    'Martin',      '61 Gulf Blvd',       'St. Petersburg','FL', '33701', '727-555-0118', 'betty.martin18@example.com',     DATE_SUB(NOW(), INTERVAL 465 DAY)),
    ('Daniel',   'Thompson',    '5 Park Ave',         'Syracuse',      'NY', '13202', '315-555-0119', 'daniel.thompson19@example.com',  DATE_SUB(NOW(), INTERVAL 450 DAY)),
    ('Lisa',     'Garcia',      '44 Prairie Ave',     'Rockford',      'IL', '61101', '815-555-0120', 'lisa.garcia20@example.com',      DATE_SUB(NOW(), INTERVAL 435 DAY)),
    ('Paul',     'Martinez',    '910 Mission St',     'San Francisco', 'CA', '94103', '415-555-0121', 'paul.martinez21@example.com',    DATE_SUB(NOW(), INTERVAL 420 DAY)),
    ('Sandra',   'Robinson',    '18 Coastal Hwy',     'Fort Lauderdale','FL','33301', '954-555-0122', 'sandra.robinson22@example.com',  DATE_SUB(NOW(), INTERVAL 405 DAY)),
    ('Mark',     'Clark',       '77 Wall St',         'New York',      'NY', '10005', '212-555-0123', 'mark.clark23@example.com',       DATE_SUB(NOW(), INTERVAL 390 DAY)),
    ('Donna',    'Rodriguez',   '22 Lincoln Ave',     'Evanston',      'IL', '60201', '847-555-0124', 'donna.rodriguez24@example.com',  DATE_SUB(NOW(), INTERVAL 375 DAY)),
    ('George',   'Lewis',       '36 Pacific Coast Hwy','Long Beach',   'CA', '90802', '562-555-0125', 'george.lewis25@example.com',     DATE_SUB(NOW(), INTERVAL 360 DAY)),
    ('Carol',    'Lee',         '93 Beach Dr',        'Clearwater',    'FL', '33755', '727-555-0126', 'carol.lee26@example.com',        DATE_SUB(NOW(), INTERVAL 345 DAY)),
    ('Kenneth',  'Walker',      '15 Canal St',        'New York',      'NY', '10013', '212-555-0127', 'kenneth.walker27@example.com',   DATE_SUB(NOW(), INTERVAL 330 DAY)),
    ('Michelle', 'Hall',        '58 Oak Park Ave',    'Oak Park',      'IL', '60302', '708-555-0128', 'michelle.hall28@example.com',    DATE_SUB(NOW(), INTERVAL 315 DAY)),
    ('Steven',   'Allen',       '41 Vine St',         'Oakland',       'CA', '94607', '510-555-0129', 'steven.allen29@example.com',     DATE_SUB(NOW(), INTERVAL 300 DAY)),
    ('Dorothy',  'Young',       '27 Harbor Blvd',     'Pensacola',     'FL', '32501', '850-555-0130', 'dorothy.young30@example.com',    DATE_SUB(NOW(), INTERVAL 285 DAY)),
    ('Edward',   'King',        '63 Flatbush Ave',    'Brooklyn',      'NY', '11201', '718-555-0131', 'edward.king31@example.com',      DATE_SUB(NOW(), INTERVAL 270 DAY)),
    ('Amy',      'Wright',      '34 Grand Ave',       'Decatur',       'IL', '62521', '217-555-0132', 'amy.wright32@example.com',       DATE_SUB(NOW(), INTERVAL 255 DAY)),
    ('Brian',    'Scott',       '81 Market St',       'San Jose',      'CA', '95113', '408-555-0133', 'brian.scott33@example.com',      DATE_SUB(NOW(), INTERVAL 240 DAY)),
    ('Angela',   'Green',       '12 Coral Way',       'Hialeah',       'FL', '33010', '305-555-0134', 'angela.green34@example.com',     DATE_SUB(NOW(), INTERVAL 225 DAY)),
    ('Ronald',   'Baker',       '49 Erie Blvd',       'Schenectady',   'NY', '12305', '518-555-0135', 'ronald.baker35@example.com',     DATE_SUB(NOW(), INTERVAL 210 DAY)),
    ('Melissa',  'Adams',       '17 Washington St',   'Aurora',        'IL', '60505', '630-555-0136', 'melissa.adams36@example.com',    DATE_SUB(NOW(), INTERVAL 195 DAY)),
    ('Kevin',    'Nelson',      '26 Sierra Ave',      'Bakersfield',   'CA', '93301', '661-555-0137', 'kevin.nelson37@example.com',     DATE_SUB(NOW(), INTERVAL 180 DAY)),
    ('Deborah',  'Hill',        '38 Seaboard Ave',    'Tallahassee',   'FL', '32301', '850-555-0138', 'deborah.hill38@example.com',     DATE_SUB(NOW(), INTERVAL 165 DAY)),
    ('Jason',    'Ramirez',     '52 Columbus Ave',    'Yonkers',       'NY', '10701', '914-555-0139', 'jason.ramirez39@example.com',    DATE_SUB(NOW(), INTERVAL 150 DAY)),
    ('Stephanie','Campbell',    '70 Lakeview Dr',     'Joliet',        'IL', '60431', '815-555-0140', 'stephanie.campbell40@example.com', DATE_SUB(NOW(), INTERVAL 135 DAY)),
    ('Timothy',  'Mitchell',    '9 Center St',        'Omaha',         'NE', '68102', '402-555-0141', 'timothy.mitchell41@example.com', DATE_SUB(NOW(), INTERVAL 710 DAY)),
    ('Rebecca',  'Roberts',     '20 Main St',         'Des Moines',    'IA', '50301', '515-555-0142', 'rebecca.roberts42@example.com',  DATE_SUB(NOW(), INTERVAL 695 DAY)),
    ('Jeffrey',  'Carter',      '11 Market Sq',       'Portland',      'OR', '97201', '503-555-0143', 'jeffrey.carter43@example.com',   DATE_SUB(NOW(), INTERVAL 680 DAY)),
    ('Laura',    'Phillips',    '48 Capitol Ave',     'Denver',        'CO', '80202', '303-555-0144', 'laura.phillips44@example.com',   DATE_SUB(NOW(), INTERVAL 665 DAY)),
    ('Ryan',     'Evans',       '64 Peachtree St',    'Atlanta',       'GA', '30303', '404-555-0145', 'ryan.evans45@example.com',       DATE_SUB(NOW(), INTERVAL 650 DAY)),
    ('Kathleen', 'Turner',      '31 Riverfront Dr',   'Columbus',      'OH', '43215', '614-555-0146', 'kathleen.turner46@example.com',  DATE_SUB(NOW(), INTERVAL 635 DAY)),
    ('Gary',     'Torres',      '53 Congress Ave',    'Austin',        'TX', '78701', '512-555-0147', 'gary.torres47@example.com',      DATE_SUB(NOW(), INTERVAL 620 DAY)),
    ('Sharon',   'Parker',      '16 Music Row',       'Nashville',     'TN', '37203', '615-555-0148', 'sharon.parker48@example.com',    DATE_SUB(NOW(), INTERVAL 605 DAY)),
    ('Nicholas', 'Collins',     '24 Independence Mall','Philadelphia', 'PA', '19106', '215-555-0149', 'nicholas.collins49@example.com', DATE_SUB(NOW(), INTERVAL 590 DAY)),
    ('Cynthia',  'Edwards',     '39 Freedom Trail',   'Boston',        'MA', '02108', '617-555-0150', 'cynthia.edwards50@example.com',  DATE_SUB(NOW(), INTERVAL 575 DAY)),
    ('Jacob',    'Stewart',     '42 Space Center Blvd','Houston',      'TX', '77058', '713-555-0151', 'jacob.stewart51@example.com',    DATE_SUB(NOW(), INTERVAL 400 DAY)),
    ('Shirley',  'Sanchez',     '87 Fountain Sq',     'Cincinnati',    'OH', '45202', '513-555-0152', 'shirley.sanchez52@example.com',  DATE_SUB(NOW(), INTERVAL 385 DAY)),
    ('Jonathan', 'Morris',      '13 Capitol Mall',    'Phoenix',       'AZ', '85004', '602-555-0153', 'jonathan.morris53@example.com',  DATE_SUB(NOW(), INTERVAL 370 DAY)),
    ('Virginia', 'Rogers',      '28 Riverwalk',       'San Antonio',   'TX', '78205', '210-555-0154', 'virginia.rogers54@example.com',  DATE_SUB(NOW(), INTERVAL 355 DAY)),
    ('Scott',    'Reed',        '35 Monument Ave',    'Richmond',      'VA', '23219', '804-555-0155', 'scott.reed55@example.com',       DATE_SUB(NOW(), INTERVAL 340 DAY)),
    ('Cheryl',   'Cook',        '46 Country Club Rd', 'Charlotte',     'NC', '28202', '704-555-0156', 'cheryl.cook56@example.com',      DATE_SUB(NOW(), INTERVAL 325 DAY)),
    ('Eric',     'Bell',        '57 Lake Michigan Dr','Milwaukee',     'WI', '53202', '414-555-0157', 'eric.bell57@example.com',        DATE_SUB(NOW(), INTERVAL 120 DAY)),
    ('Teresa',   'Murphy',      '68 Twin Cities Rd',  'Minneapolis',   'MN', '55401', '612-555-0158', 'teresa.murphy58@example.com',    DATE_SUB(NOW(), INTERVAL 95 DAY)),
    ('Frank',    'Bailey',      '79 Puget Sound Ave', 'Seattle',       'WA', '98101', '206-555-0159', 'frank.bailey59@example.com',     DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('Judith',   'Rivera',      '82 Desert Vista Rd', 'Las Vegas',     'NV', '89101', '702-555-0160', 'judith.rivera60@example.com',    DATE_SUB(NOW(), INTERVAL 30 DAY));

-- -----------------------------------------------------------------------------
-- 2. adjuster (8 rows: 7 active, 1 inactive)
-- -----------------------------------------------------------------------------
INSERT INTO adjuster
    (username, first_name, last_name, is_active, created_at)
VALUES
    ('jsantos',   'Jennifer', 'Santos',   1, DATE_SUB(NOW(), INTERVAL 700 DAY)),
    ('mcarter',   'Marcus',   'Carter',   1, DATE_SUB(NOW(), INTERVAL 680 DAY)),
    ('lkowalski', 'Laura',    'Kowalski', 1, DATE_SUB(NOW(), INTERVAL 660 DAY)),
    ('tbrennan',  'Thomas',   'Brennan',  1, DATE_SUB(NOW(), INTERVAL 640 DAY)),
    ('apatel',    'Anita',    'Patel',    1, DATE_SUB(NOW(), INTERVAL 620 DAY)),
    ('rfoster',   'Raymond',  'Foster',   1, DATE_SUB(NOW(), INTERVAL 600 DAY)),
    ('kobrien',   'Kelly',    'O''Brien', 1, DATE_SUB(NOW(), INTERVAL 580 DAY)),
    ('dholloway', 'Dennis',   'Holloway', 0, DATE_SUB(NOW(), INTERVAL 560 DAY));

-- -----------------------------------------------------------------------------
-- 3. policy_reference (40 rows: ~even split AUTO/PROPERTY/LIABILITY,
--    varied coverage_limit/deductible, mostly current date ranges, with
--    5 rows carrying an effective_end_date in the past (expired policies)).
-- -----------------------------------------------------------------------------
INSERT INTO policy_reference
    (policy_number, policy_type, coverage_limit, deductible, effective_start_date, effective_end_date)
VALUES
    ('POL-AU-00001', 'AUTO',      50000.00,   500.00, DATE_SUB(CURDATE(), INTERVAL 18 MONTH), DATE_ADD(CURDATE(), INTERVAL 6 MONTH)),
    ('POL-AU-00002', 'AUTO',      75000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 12 MONTH), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    ('POL-AU-00003', 'AUTO',     100000.00,   750.00, DATE_SUB(CURDATE(), INTERVAL 24 MONTH), DATE_ADD(CURDATE(), INTERVAL 1 MONTH)),
    ('POL-AU-00004', 'AUTO',      25000.00,   250.00, DATE_SUB(CURDATE(), INTERVAL 20 MONTH), DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    ('POL-AU-00005', 'AUTO',      60000.00,   500.00, DATE_SUB(CURDATE(), INTERVAL 15 MONTH), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    ('POL-AU-00006', 'AUTO',     150000.00,  2000.00, DATE_SUB(CURDATE(), INTERVAL 10 MONTH), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    ('POL-AU-00007', 'AUTO',      40000.00,   500.00, DATE_SUB(CURDATE(), INTERVAL 22 MONTH), DATE_SUB(CURDATE(), INTERVAL 10 MONTH)),
    ('POL-AU-00008', 'AUTO',      80000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 14 MONTH), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    ('POL-AU-00009', 'AUTO',      35000.00,   250.00, DATE_SUB(CURDATE(), INTERVAL 11 MONTH), DATE_ADD(CURDATE(), INTERVAL 13 MONTH)),
    ('POL-AU-00010', 'AUTO',     120000.00,  1500.00, DATE_SUB(CURDATE(), INTERVAL 9 MONTH),  DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),
    ('POL-AU-00011', 'AUTO',      55000.00,   500.00, DATE_SUB(CURDATE(), INTERVAL 19 MONTH), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    ('POL-AU-00012', 'AUTO',      95000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 13 MONTH), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    ('POL-AU-00013', 'AUTO',      30000.00,   250.00, DATE_SUB(CURDATE(), INTERVAL 23 MONTH), DATE_SUB(CURDATE(), INTERVAL 11 MONTH)),
    ('POL-PR-00001', 'PROPERTY', 250000.00,  2500.00, DATE_SUB(CURDATE(), INTERVAL 17 MONTH), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    ('POL-PR-00002', 'PROPERTY', 300000.00,  5000.00, DATE_SUB(CURDATE(), INTERVAL 12 MONTH), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    ('POL-PR-00003', 'PROPERTY', 150000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 21 MONTH), DATE_ADD(CURDATE(), INTERVAL 3 MONTH)),
    ('POL-PR-00004', 'PROPERTY', 500000.00,  5000.00, DATE_SUB(CURDATE(), INTERVAL 16 MONTH), DATE_ADD(CURDATE(), INTERVAL 8 MONTH)),
    ('POL-PR-00005', 'PROPERTY', 200000.00,  2000.00, DATE_SUB(CURDATE(), INTERVAL 10 MONTH), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    ('POL-PR-00006', 'PROPERTY', 175000.00,  1500.00, DATE_SUB(CURDATE(), INTERVAL 20 MONTH), DATE_SUB(CURDATE(), INTERVAL 8 MONTH)),
    ('POL-PR-00007', 'PROPERTY', 220000.00,  2500.00, DATE_SUB(CURDATE(), INTERVAL 14 MONTH), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    ('POL-PR-00008', 'PROPERTY', 400000.00,  4000.00, DATE_SUB(CURDATE(), INTERVAL 11 MONTH), DATE_ADD(CURDATE(), INTERVAL 13 MONTH)),
    ('POL-PR-00009', 'PROPERTY', 125000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 18 MONTH), DATE_ADD(CURDATE(), INTERVAL 6 MONTH)),
    ('POL-PR-00010', 'PROPERTY', 275000.00,  3000.00, DATE_SUB(CURDATE(), INTERVAL 9 MONTH),  DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),
    ('POL-PR-00011', 'PROPERTY', 350000.00,  4000.00, DATE_SUB(CURDATE(), INTERVAL 24 MONTH), DATE_SUB(CURDATE(), INTERVAL 12 MONTH)),
    ('POL-PR-00012', 'PROPERTY', 180000.00,  1500.00, DATE_SUB(CURDATE(), INTERVAL 15 MONTH), DATE_ADD(CURDATE(), INTERVAL 9 MONTH)),
    ('POL-PR-00013', 'PROPERTY', 225000.00,  2000.00, DATE_SUB(CURDATE(), INTERVAL 13 MONTH), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    ('POL-PR-00014', 'PROPERTY', 310000.00,  3500.00, DATE_SUB(CURDATE(), INTERVAL 19 MONTH), DATE_ADD(CURDATE(), INTERVAL 5 MONTH)),
    ('POL-LI-00001', 'LIABILITY', 100000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 16 MONTH), DATE_ADD(CURDATE(), INTERVAL 8 MONTH)),
    ('POL-LI-00002', 'LIABILITY', 300000.00,  2500.00, DATE_SUB(CURDATE(), INTERVAL 12 MONTH), DATE_ADD(CURDATE(), INTERVAL 12 MONTH)),
    ('POL-LI-00003', 'LIABILITY', 500000.00,  5000.00, DATE_SUB(CURDATE(), INTERVAL 20 MONTH), DATE_ADD(CURDATE(), INTERVAL 4 MONTH)),
    ('POL-LI-00004', 'LIABILITY', 150000.00,  1500.00, DATE_SUB(CURDATE(), INTERVAL 10 MONTH), DATE_ADD(CURDATE(), INTERVAL 14 MONTH)),
    ('POL-LI-00005', 'LIABILITY', 250000.00,  2000.00, DATE_SUB(CURDATE(), INTERVAL 22 MONTH), DATE_SUB(CURDATE(), INTERVAL 10 MONTH)),
    ('POL-LI-00006', 'LIABILITY', 400000.00,  4000.00, DATE_SUB(CURDATE(), INTERVAL 17 MONTH), DATE_ADD(CURDATE(), INTERVAL 7 MONTH)),
    ('POL-LI-00007', 'LIABILITY', 200000.00,  2000.00, DATE_SUB(CURDATE(), INTERVAL 14 MONTH), DATE_ADD(CURDATE(), INTERVAL 10 MONTH)),
    ('POL-LI-00008', 'LIABILITY', 350000.00,  3500.00, DATE_SUB(CURDATE(), INTERVAL 11 MONTH), DATE_ADD(CURDATE(), INTERVAL 13 MONTH)),
    ('POL-LI-00009', 'LIABILITY',  75000.00,  1000.00, DATE_SUB(CURDATE(), INTERVAL 9 MONTH),  DATE_ADD(CURDATE(), INTERVAL 15 MONTH)),
    ('POL-LI-00010', 'LIABILITY', 450000.00,  5000.00, DATE_SUB(CURDATE(), INTERVAL 18 MONTH), DATE_ADD(CURDATE(), INTERVAL 6 MONTH)),
    ('POL-LI-00011', 'LIABILITY', 125000.00,  1250.00, DATE_SUB(CURDATE(), INTERVAL 23 MONTH), DATE_SUB(CURDATE(), INTERVAL 11 MONTH)),
    ('POL-LI-00012', 'LIABILITY', 275000.00,  2750.00, DATE_SUB(CURDATE(), INTERVAL 13 MONTH), DATE_ADD(CURDATE(), INTERVAL 11 MONTH)),
    ('POL-LI-00013', 'LIABILITY', 325000.00,  3250.00, DATE_SUB(CURDATE(), INTERVAL 21 MONTH), DATE_ADD(CURDATE(), INTERVAL 3 MONTH)),
    ('POL-LI-00014', 'LIABILITY', 180000.00,  1800.00, DATE_SUB(CURDATE(), INTERVAL 15 MONTH), DATE_ADD(CURDATE(), INTERVAL 9 MONTH));

-- -----------------------------------------------------------------------------
-- 4. claim_status_transition_rule (5 rows: the allowed lifecycle graph, Req 6.2)
-- -----------------------------------------------------------------------------
INSERT INTO claim_status_transition_rule
    (prior_status, new_status)
VALUES
    ('Open',          'Investigating'),
    ('Investigating', 'Approved'),
    ('Investigating', 'Denied'),
    ('Approved',      'Settled'),
    ('Settled',       'Closed'),
    ('Denied',        'Closed');

-- -----------------------------------------------------------------------------
-- 5. fraud_score_config (1 row: Req 8.4 configurable threshold)
-- -----------------------------------------------------------------------------
INSERT INTO fraud_score_config
    (config_key, config_value)
VALUES
    ('FRAUD_REVIEW_THRESHOLD', '70');

-- -----------------------------------------------------------------------------
-- 6. document_type_lookup (6 rows: system-defined document types, Req 9.3)
-- -----------------------------------------------------------------------------
INSERT INTO document_type_lookup
    (document_type, description)
VALUES
    ('POLICE_REPORT',   'Police Report'),
    ('PHOTO',           'Photo Evidence'),
    ('ESTIMATE',        'Repair Estimate'),
    ('CORRESPONDENCE',  'Correspondence'),
    ('MEDICAL_RECORD',  'Medical Record'),
    ('INVOICE',         'Invoice');
