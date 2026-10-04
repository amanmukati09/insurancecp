-- =============================================================================
-- ICPS Database - 42_seed_fraud_document_litigation_subrogation.sql
-- Seed data for fraud, document, litigation, and subrogation records:
-- fraud_flag, document_metadata, litigation_record, subrogation_record.
--
-- Requirements: 16.7, 11.2, 11.4
--
-- LOAD ORDER NOTE: Must be run AFTER 01-04 (DDL), 40_seed_reference_lookup.sql,
-- and 41_seed_claims_financial.sql (claim_id 1-110, settlement rows for
-- claim_id 74-110, and claim.net_paid_amount for claim_id 74-110 must already
-- exist). document_type_lookup must already contain the 6 seeded types
-- (POLICE_REPORT, PHOTO, ESTIMATE, CORRESPONDENCE, MEDICAL_RECORD, INVOICE).
--
-- All data below is synthetic / fabricated for test-fixture purposes only.
-- =============================================================================
SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- 1. fraud_flag
-- Active flags on 15 claims total.
--
-- Group A - threshold-crossing claims (sum of active score_weight > 70),
-- matching the 5 claims already marked under_fraud_review = 1 in
-- 41_seed_claims_financial.sql (claim_id 33, 53, 75, 84, 88):
--   33  -> two active flags, 40 + 40 = 80 (> 70)
--   53  -> two active flags, 45 + 40 = 85 (> 70)
--   75  -> two active flags, 40 + 35 = 75 (> 70)
--   84  -> two active flags, 50 + 25 = 75 (> 70); plus one deactivated flag
--          (is_active = 0) that is excluded from the active sum
--   88  -> single active flag of 75 (> 70); plus one deactivated flag
--          (is_active = 0) that is excluded from the active sum
--
-- Group B - below-threshold claims (active score_weight stays under 70),
-- a mix of statuses, none of which have under_fraud_review set:
--   5 (Open), 14 (Open), 22 (Investigating), 40 (Approved), 50 (Approved),
--   60 (Denied), 70 (Denied), 80 (Settled), 90 (Settled), 100 (Closed)
--   -> one active flag each, score_weight 10-30; claim 60 additionally has
--      a deactivated flag to exercise the is_active=0 path.
-- -----------------------------------------------------------------------------
INSERT INTO fraud_flag
    (claim_id, flag_reason, score_weight, is_active, created_at, updated_at)
VALUES
    -- Group A: threshold-crossing claims
    (33, 'Inconsistent incident timeline', 40, 1, '2025-04-20 09:00:00', '2025-04-20 09:00:00'),
    (33, 'Multiple claims same address', 40, 1, '2025-04-22 09:00:00', '2025-04-22 09:00:00'),

    (53, 'Prior fraud history', 45, 1, '2025-03-22 09:00:00', '2025-03-22 09:00:00'),
    (53, 'Suspicious witness statements', 40, 1, '2025-03-24 09:00:00', '2025-03-24 09:00:00'),

    (75, 'Claim filed shortly after policy inception', 40, 1, '2024-09-02 09:00:00', '2024-09-02 09:00:00'),
    (75, 'Inconsistent incident timeline', 35, 1, '2024-09-04 09:00:00', '2024-09-04 09:00:00'),

    (84, 'Multiple claims same address', 50, 1, '2024-11-01 09:00:00', '2024-11-01 09:00:00'),
    (84, 'Prior fraud history', 25, 1, '2024-11-03 09:00:00', '2024-11-03 09:00:00'),
    (84, 'Suspicious witness statements', 20, 0, '2024-10-30 09:00:00', '2024-11-05 09:00:00'),

    (88, 'Prior fraud history', 75, 1, '2024-05-03 09:00:00', '2024-05-03 09:00:00'),
    (88, 'Inconsistent incident timeline', 15, 0, '2024-05-02 09:00:00', '2024-05-06 09:00:00'),

    -- Group B: below-threshold claims
    (5, 'Suspicious witness statements', 20, 1, '2024-12-20 09:00:00', '2024-12-20 09:00:00'),
    (14, 'Claim filed shortly after policy inception', 15, 1, '2024-08-30 09:00:00', '2024-08-30 09:00:00'),
    (22, 'Inconsistent incident timeline', 25, 1, '2024-02-20 09:00:00', '2024-02-20 09:00:00'),
    (40, 'Multiple claims same address', 10, 1, '2024-06-05 09:00:00', '2024-06-05 09:00:00'),
    (50, 'Prior fraud history', 30, 1, '2025-06-06 09:00:00', '2025-06-06 09:00:00'),
    (60, 'Suspicious witness statements', 20, 1, '2024-06-03 09:00:00', '2024-06-03 09:00:00'),
    (60, 'Claim filed shortly after policy inception', 10, 0, '2024-06-02 09:00:00', '2024-06-05 09:00:00'),
    (70, 'Inconsistent incident timeline', 15, 1, '2024-04-20 09:00:00', '2024-04-20 09:00:00'),
    (80, 'Multiple claims same address', 25, 1, '2024-11-17 09:00:00', '2024-11-17 09:00:00'),
    (90, 'Prior fraud history', 10, 1, '2024-11-04 09:00:00', '2024-11-04 09:00:00'),
    (100, 'Suspicious witness statements', 30, 1, '2025-01-10 09:00:00', '2025-01-10 09:00:00');

-- -----------------------------------------------------------------------------
-- 2. document_metadata
-- 1-4 rows across a broad sample of claims (~200 rows total), file names
-- and storage references keyed by claim id, document_type drawn from the
-- 6 seeded document_type_lookup values.
-- -----------------------------------------------------------------------------
INSERT INTO document_metadata
    (claim_id, file_name, document_type, file_size_bytes, storage_reference, uploaded_at)
VALUES
    (1, 'police_report_1.pdf', 'POLICE_REPORT', 245000, '/storage/claims/1/police_report_1.pdf', '2024-08-06 11:00:00'),
    (1, 'photo_1_a.jpg', 'PHOTO', 1850000, '/storage/claims/1/photo_1_a.jpg', '2024-08-06 11:05:00'),
    (2, 'police_report_2.pdf', 'POLICE_REPORT', 198000, '/storage/claims/2/police_report_2.pdf', '2024-11-18 11:00:00'),
    (2, 'estimate_2.pdf', 'ESTIMATE', 54000, '/storage/claims/2/estimate_2.pdf', '2024-11-19 09:00:00'),
    (3, 'correspondence_3.pdf', 'CORRESPONDENCE', 32000, '/storage/claims/3/correspondence_3.pdf', '2024-02-09 11:00:00'),
    (4, 'photo_4_a.jpg', 'PHOTO', 2100000, '/storage/claims/4/photo_4_a.jpg', '2025-06-10 11:00:00'),
    (4, 'photo_4_b.jpg', 'PHOTO', 1950000, '/storage/claims/4/photo_4_b.jpg', '2025-06-10 11:05:00'),
    (5, 'police_report_5.pdf', 'POLICE_REPORT', 210000, '/storage/claims/5/police_report_5.pdf', '2024-12-17 11:00:00'),
    (5, 'medical_record_5.pdf', 'MEDICAL_RECORD', 410000, '/storage/claims/5/medical_record_5.pdf', '2024-12-18 09:00:00'),
    (6, 'police_report_6.pdf', 'POLICE_REPORT', 230000, '/storage/claims/6/police_report_6.pdf', '2024-06-10 11:00:00'),
    (7, 'photo_7_a.jpg', 'PHOTO', 1750000, '/storage/claims/7/photo_7_a.jpg', '2024-07-06 11:00:00'),
    (8, 'medical_record_8.pdf', 'MEDICAL_RECORD', 380000, '/storage/claims/8/medical_record_8.pdf', '2024-08-14 11:00:00'),
    (8, 'photo_8_a.jpg', 'PHOTO', 1620000, '/storage/claims/8/photo_8_a.jpg', '2024-08-15 09:00:00'),
    (9, 'estimate_9.pdf', 'ESTIMATE', 61000, '/storage/claims/9/estimate_9.pdf', '2024-10-10 11:00:00'),
    (10, 'photo_10_a.jpg', 'PHOTO', 2050000, '/storage/claims/10/photo_10_a.jpg', '2025-01-06 11:00:00'),
    (10, 'estimate_10.pdf', 'ESTIMATE', 72000, '/storage/claims/10/estimate_10.pdf', '2025-01-07 09:00:00'),
    (10, 'invoice_10.pdf', 'INVOICE', 45000, '/storage/claims/10/invoice_10.pdf', '2025-01-08 09:00:00'),
    (11, 'police_report_11.pdf', 'POLICE_REPORT', 205000, '/storage/claims/11/police_report_11.pdf', '2024-04-18 11:00:00'),
    (12, 'photo_12_a.jpg', 'PHOTO', 1900000, '/storage/claims/12/photo_12_a.jpg', '2024-09-18 11:00:00'),
    (13, 'correspondence_13.pdf', 'CORRESPONDENCE', 29000, '/storage/claims/13/correspondence_13.pdf', '2024-05-20 11:00:00'),
    (14, 'police_report_14.pdf', 'POLICE_REPORT', 215000, '/storage/claims/14/police_report_14.pdf', '2024-08-28 11:00:00'),
    (14, 'photo_14_a.jpg', 'PHOTO', 1780000, '/storage/claims/14/photo_14_a.jpg', '2024-08-29 09:00:00'),
    (15, 'photo_15_a.jpg', 'PHOTO', 2200000, '/storage/claims/15/photo_15_a.jpg', '2024-11-18 11:00:00'),
    (15, 'estimate_15.pdf', 'ESTIMATE', 68000, '/storage/claims/15/estimate_15.pdf', '2024-11-19 09:00:00'),
    (16, 'police_report_16.pdf', 'POLICE_REPORT', 240000, '/storage/claims/16/police_report_16.pdf', '2025-02-06 11:00:00'),
    (17, 'photo_17_a.jpg', 'PHOTO', 1680000, '/storage/claims/17/photo_17_a.jpg', '2024-05-19 11:00:00'),
    (18, 'photo_18_a.jpg', 'PHOTO', 2300000, '/storage/claims/18/photo_18_a.jpg', '2024-07-16 11:00:00'),
    (18, 'estimate_18.pdf', 'ESTIMATE', 75000, '/storage/claims/18/estimate_18.pdf', '2024-07-17 09:00:00'),
    (19, 'correspondence_19.pdf', 'CORRESPONDENCE', 31000, '/storage/claims/19/correspondence_19.pdf', '2024-10-04 11:00:00'),
    (20, 'police_report_20.pdf', 'POLICE_REPORT', 198000, '/storage/claims/20/police_report_20.pdf', '2025-05-15 11:00:00'),
    (20, 'photo_20_a.jpg', 'PHOTO', 1550000, '/storage/claims/20/photo_20_a.jpg', '2025-05-16 09:00:00'),
    (21, 'correspondence_21.pdf', 'CORRESPONDENCE', 27000, '/storage/claims/21/correspondence_21.pdf', '2024-06-21 11:00:00'),
    (22, 'photo_22_a.jpg', 'PHOTO', 1900000, '/storage/claims/22/photo_22_a.jpg', '2024-02-16 11:00:00'),
    (22, 'estimate_22.pdf', 'ESTIMATE', 83000, '/storage/claims/22/estimate_22.pdf', '2024-02-17 09:00:00'),
    (23, 'photo_23_a.jpg', 'PHOTO', 2050000, '/storage/claims/23/photo_23_a.jpg', '2024-10-15 11:00:00'),
    (24, 'photo_24_a.jpg', 'PHOTO', 2150000, '/storage/claims/24/photo_24_a.jpg', '2025-01-30 11:00:00'),
    (24, 'estimate_24.pdf', 'ESTIMATE', 69000, '/storage/claims/24/estimate_24.pdf', '2025-01-31 09:00:00'),
    (25, 'police_report_25.pdf', 'POLICE_REPORT', 225000, '/storage/claims/25/police_report_25.pdf', '2025-04-25 11:00:00'),
    (26, 'photo_26_a.jpg', 'PHOTO', 1890000, '/storage/claims/26/photo_26_a.jpg', '2024-12-20 11:00:00'),
    (27, 'police_report_27.pdf', 'POLICE_REPORT', 203000, '/storage/claims/27/police_report_27.pdf', '2025-01-05 11:00:00'),
    (27, 'invoice_27.pdf', 'INVOICE', 41000, '/storage/claims/27/invoice_27.pdf', '2025-01-06 09:00:00'),
    (28, 'photo_28_a.jpg', 'PHOTO', 1770000, '/storage/claims/28/photo_28_a.jpg', '2025-03-16 11:00:00'),
    (29, 'photo_29_a.jpg', 'PHOTO', 1920000, '/storage/claims/29/photo_29_a.jpg', '2024-12-12 11:00:00'),
    (29, 'estimate_29.pdf', 'ESTIMATE', 59000, '/storage/claims/29/estimate_29.pdf', '2024-12-13 09:00:00'),
    (30, 'correspondence_30.pdf', 'CORRESPONDENCE', 35000, '/storage/claims/30/correspondence_30.pdf', '2024-03-28 11:00:00'),
    (31, 'police_report_31.pdf', 'POLICE_REPORT', 212000, '/storage/claims/31/police_report_31.pdf', '2025-01-26 11:00:00'),
    (32, 'photo_32_a.jpg', 'PHOTO', 2000000, '/storage/claims/32/photo_32_a.jpg', '2025-06-07 11:00:00'),
    (33, 'police_report_33.pdf', 'POLICE_REPORT', 220000, '/storage/claims/33/police_report_33.pdf', '2025-04-18 11:00:00'),
    (33, 'photo_33_a.jpg', 'PHOTO', 1830000, '/storage/claims/33/photo_33_a.jpg', '2025-04-19 09:00:00'),
    (33, 'correspondence_33.pdf', 'CORRESPONDENCE', 33000, '/storage/claims/33/correspondence_33.pdf', '2025-04-21 09:00:00'),
    (34, 'medical_record_34.pdf', 'MEDICAL_RECORD', 420000, '/storage/claims/34/medical_record_34.pdf', '2024-06-18 11:00:00'),
    (35, 'photo_35_a.jpg', 'PHOTO', 2100000, '/storage/claims/35/photo_35_a.jpg', '2025-04-02 11:00:00'),
    (36, 'correspondence_36.pdf', 'CORRESPONDENCE', 28000, '/storage/claims/36/correspondence_36.pdf', '2024-11-18 11:00:00'),
    (37, 'police_report_37.pdf', 'POLICE_REPORT', 199000, '/storage/claims/37/police_report_37.pdf', '2024-10-21 11:00:00'),
    (38, 'estimate_38.pdf', 'ESTIMATE', 77000, '/storage/claims/38/estimate_38.pdf', '2024-12-19 11:00:00'),
    (38, 'photo_38_a.jpg', 'PHOTO', 1690000, '/storage/claims/38/photo_38_a.jpg', '2024-12-20 09:00:00'),
    (39, 'police_report_39.pdf', 'POLICE_REPORT', 207000, '/storage/claims/39/police_report_39.pdf', '2024-06-15 11:00:00'),
    (40, 'photo_40_a.jpg', 'PHOTO', 1960000, '/storage/claims/40/photo_40_a.jpg', '2024-06-01 11:00:00'),
    (40, 'correspondence_40.pdf', 'CORRESPONDENCE', 30000, '/storage/claims/40/correspondence_40.pdf', '2024-06-02 09:00:00'),
    (41, 'estimate_41.pdf', 'ESTIMATE', 64000, '/storage/claims/41/estimate_41.pdf', '2025-05-26 11:00:00'),
    (42, 'police_report_42.pdf', 'POLICE_REPORT', 218000, '/storage/claims/42/police_report_42.pdf', '2024-06-16 11:00:00'),
    (43, 'correspondence_43.pdf', 'CORRESPONDENCE', 36000, '/storage/claims/43/correspondence_43.pdf', '2025-04-16 11:00:00'),
    (44, 'photo_44_a.jpg', 'PHOTO', 1810000, '/storage/claims/44/photo_44_a.jpg', '2024-05-28 11:00:00'),
    (44, 'estimate_44.pdf', 'ESTIMATE', 71000, '/storage/claims/44/estimate_44.pdf', '2024-05-29 09:00:00'),
    (45, 'medical_record_45.pdf', 'MEDICAL_RECORD', 395000, '/storage/claims/45/medical_record_45.pdf', '2024-10-03 11:00:00'),
    (46, 'photo_46_a.jpg', 'PHOTO', 2250000, '/storage/claims/46/photo_46_a.jpg', '2024-06-16 11:00:00'),
    (47, 'police_report_47.pdf', 'POLICE_REPORT', 201000, '/storage/claims/47/police_report_47.pdf', '2024-05-25 11:00:00'),
    (48, 'photo_48_a.jpg', 'PHOTO', 2080000, '/storage/claims/48/photo_48_a.jpg', '2024-11-20 11:00:00'),
    (49, 'correspondence_49.pdf', 'CORRESPONDENCE', 26000, '/storage/claims/49/correspondence_49.pdf', '2023-12-30 11:00:00'),
    (50, 'photo_50_a.jpg', 'PHOTO', 1990000, '/storage/claims/50/photo_50_a.jpg', '2025-06-04 11:00:00'),
    (50, 'estimate_50.pdf', 'ESTIMATE', 66000, '/storage/claims/50/estimate_50.pdf', '2025-06-05 09:00:00'),
    (51, 'police_report_51.pdf', 'POLICE_REPORT', 214000, '/storage/claims/51/police_report_51.pdf', '2024-08-13 11:00:00'),
    (52, 'photo_52_a.jpg', 'PHOTO', 1870000, '/storage/claims/52/photo_52_a.jpg', '2024-09-10 11:00:00'),
    (53, 'medical_record_53.pdf', 'MEDICAL_RECORD', 405000, '/storage/claims/53/medical_record_53.pdf', '2025-03-21 11:00:00'),
    (53, 'correspondence_53.pdf', 'CORRESPONDENCE', 34000, '/storage/claims/53/correspondence_53.pdf', '2025-03-22 09:00:00'),
    (54, 'photo_54_a.jpg', 'PHOTO', 2020000, '/storage/claims/54/photo_54_a.jpg', '2024-02-28 11:00:00'),
    (55, 'police_report_55.pdf', 'POLICE_REPORT', 222000, '/storage/claims/55/police_report_55.pdf', '2025-03-23 11:00:00'),
    (56, 'estimate_56.pdf', 'ESTIMATE', 58000, '/storage/claims/56/estimate_56.pdf', '2025-03-28 11:00:00'),
    (57, 'correspondence_57.pdf', 'CORRESPONDENCE', 37000, '/storage/claims/57/correspondence_57.pdf', '2024-09-03 11:00:00'),
    (58, 'police_report_58.pdf', 'POLICE_REPORT', 209000, '/storage/claims/58/police_report_58.pdf', '2024-07-29 11:00:00'),
    (58, 'correspondence_58.pdf', 'CORRESPONDENCE', 39000, '/storage/claims/58/correspondence_58.pdf', '2024-07-30 09:00:00'),
    (59, 'photo_59_a.jpg', 'PHOTO', 1940000, '/storage/claims/59/photo_59_a.jpg', '2025-05-12 11:00:00'),
    (60, 'police_report_60.pdf', 'POLICE_REPORT', 196000, '/storage/claims/60/police_report_60.pdf', '2024-06-01 11:00:00'),
    (61, 'correspondence_61.pdf', 'CORRESPONDENCE', 40000, '/storage/claims/61/correspondence_61.pdf', '2025-03-19 11:00:00'),
    (62, 'police_report_62.pdf', 'POLICE_REPORT', 211000, '/storage/claims/62/police_report_62.pdf', '2025-01-09 11:00:00'),
    (63, 'medical_record_63.pdf', 'MEDICAL_RECORD', 388000, '/storage/claims/63/medical_record_63.pdf', '2024-04-04 11:00:00'),
    (64, 'photo_64_a.jpg', 'PHOTO', 1760000, '/storage/claims/64/photo_64_a.jpg', '2024-06-30 11:00:00'),
    (65, 'police_report_65.pdf', 'POLICE_REPORT', 204000, '/storage/claims/65/police_report_65.pdf', '2024-09-06 11:00:00'),
    (66, 'correspondence_66.pdf', 'CORRESPONDENCE', 42000, '/storage/claims/66/correspondence_66.pdf', '2024-09-07 11:00:00'),
    (67, 'photo_67_a.jpg', 'PHOTO', 1880000, '/storage/claims/67/photo_67_a.jpg', '2024-05-24 11:00:00'),
    (68, 'police_report_68.pdf', 'POLICE_REPORT', 217000, '/storage/claims/68/police_report_68.pdf', '2024-12-15 11:00:00'),
    (69, 'correspondence_69.pdf', 'CORRESPONDENCE', 38000, '/storage/claims/69/correspondence_69.pdf', '2025-06-13 11:00:00'),
    (70, 'photo_70_a.jpg', 'PHOTO', 1930000, '/storage/claims/70/photo_70_a.jpg', '2024-04-18 11:00:00'),
    (71, 'correspondence_71.pdf', 'CORRESPONDENCE', 29500, '/storage/claims/71/correspondence_71.pdf', '2024-12-18 11:00:00'),
    (72, 'police_report_72.pdf', 'POLICE_REPORT', 208000, '/storage/claims/72/police_report_72.pdf', '2024-05-07 11:00:00'),
    (73, 'photo_73_a.jpg', 'PHOTO', 1970000, '/storage/claims/73/photo_73_a.jpg', '2024-10-19 11:00:00'),
    (74, 'estimate_74.pdf', 'ESTIMATE', 62000, '/storage/claims/74/estimate_74.pdf', '2024-07-25 11:00:00'),
    (74, 'invoice_74.pdf', 'INVOICE', 48000, '/storage/claims/74/invoice_74.pdf', '2024-08-10 09:00:00'),
    (75, 'medical_record_75.pdf', 'MEDICAL_RECORD', 399000, '/storage/claims/75/medical_record_75.pdf', '2024-09-06 11:00:00'),
    (75, 'invoice_75.pdf', 'INVOICE', 51000, '/storage/claims/75/invoice_75.pdf', '2024-09-20 09:00:00'),
    (76, 'photo_76_a.jpg', 'PHOTO', 2010000, '/storage/claims/76/photo_76_a.jpg', '2025-01-04 11:00:00'),
    (76, 'invoice_76.pdf', 'INVOICE', 53000, '/storage/claims/76/invoice_76.pdf', '2025-01-20 09:00:00'),
    (77, 'estimate_77.pdf', 'ESTIMATE', 67000, '/storage/claims/77/estimate_77.pdf', '2024-10-23 11:00:00'),
    (78, 'photo_78_a.jpg', 'PHOTO', 1850000, '/storage/claims/78/photo_78_a.jpg', '2025-01-13 11:00:00'),
    (79, 'invoice_79.pdf', 'INVOICE', 46000, '/storage/claims/79/invoice_79.pdf', '2024-09-26 11:00:00'),
    (80, 'medical_record_80.pdf', 'MEDICAL_RECORD', 412000, '/storage/claims/80/medical_record_80.pdf', '2024-11-15 11:00:00'),
    (80, 'invoice_80.pdf', 'INVOICE', 49000, '/storage/claims/80/invoice_80.pdf', '2024-11-30 09:00:00'),
    (81, 'police_report_81.pdf', 'POLICE_REPORT', 206000, '/storage/claims/81/police_report_81.pdf', '2024-12-10 11:00:00'),
    (82, 'photo_82_a.jpg', 'PHOTO', 1920000, '/storage/claims/82/photo_82_a.jpg', '2025-02-26 11:00:00'),
    (83, 'estimate_83.pdf', 'ESTIMATE', 73000, '/storage/claims/83/estimate_83.pdf', '2024-11-09 11:00:00'),
    (84, 'photo_84_a.jpg', 'PHOTO', 2170000, '/storage/claims/84/photo_84_a.jpg', '2024-11-04 11:00:00'),
    (84, 'correspondence_84.pdf', 'CORRESPONDENCE', 44000, '/storage/claims/84/correspondence_84.pdf', '2024-11-20 09:00:00'),
    (85, 'invoice_85.pdf', 'INVOICE', 47000, '/storage/claims/85/invoice_85.pdf', '2024-12-25 11:00:00'),
    (86, 'photo_86_a.jpg', 'PHOTO', 2040000, '/storage/claims/86/photo_86_a.jpg', '2025-04-07 11:00:00'),
    (87, 'estimate_87.pdf', 'ESTIMATE', 70000, '/storage/claims/87/estimate_87.pdf', '2025-06-11 11:00:00'),
    (88, 'invoice_88.pdf', 'INVOICE', 54000, '/storage/claims/88/invoice_88.pdf', '2024-05-08 11:00:00'),
    (88, 'correspondence_88.pdf', 'CORRESPONDENCE', 41000, '/storage/claims/88/correspondence_88.pdf', '2024-05-20 09:00:00'),
    (89, 'photo_89_a.jpg', 'PHOTO', 1990000, '/storage/claims/89/photo_89_a.jpg', '2024-12-07 11:00:00'),
    (90, 'estimate_90.pdf', 'ESTIMATE', 65000, '/storage/claims/90/estimate_90.pdf', '2024-11-02 11:00:00'),
    (91, 'invoice_91.pdf', 'INVOICE', 50000, '/storage/claims/91/invoice_91.pdf', '2024-11-23 11:00:00'),
    (92, 'photo_92_a.jpg', 'PHOTO', 1860000, '/storage/claims/92/photo_92_a.jpg', '2025-01-23 11:00:00'),
    (93, 'invoice_93.pdf', 'INVOICE', 56000, '/storage/claims/93/invoice_93.pdf', '2025-06-12 11:00:00'),
    (94, 'medical_record_94.pdf', 'MEDICAL_RECORD', 418000, '/storage/claims/94/medical_record_94.pdf', '2025-01-28 11:00:00'),
    (95, 'police_report_95.pdf', 'POLICE_REPORT', 213000, '/storage/claims/95/police_report_95.pdf', '2024-11-29 11:00:00'),
    (96, 'estimate_96.pdf', 'ESTIMATE', 60000, '/storage/claims/96/estimate_96.pdf', '2025-06-12 11:00:00'),
    (97, 'photo_97_a.jpg', 'PHOTO', 1790000, '/storage/claims/97/photo_97_a.jpg', '2023-11-30 11:00:00'),
    (98, 'invoice_98.pdf', 'INVOICE', 52000, '/storage/claims/98/invoice_98.pdf', '2025-03-17 11:00:00'),
    (99, 'photo_99_a.jpg', 'PHOTO', 2060000, '/storage/claims/99/photo_99_a.jpg', '2024-10-23 11:00:00'),
    (100, 'estimate_100.pdf', 'ESTIMATE', 63000, '/storage/claims/100/estimate_100.pdf', '2025-01-08 11:00:00'),
    (100, 'correspondence_100.pdf', 'CORRESPONDENCE', 32500, '/storage/claims/100/correspondence_100.pdf', '2025-01-09 09:00:00'),
    (101, 'invoice_101.pdf', 'INVOICE', 55000, '/storage/claims/101/invoice_101.pdf', '2024-12-12 11:00:00'),
    (102, 'photo_102_a.jpg', 'PHOTO', 1910000, '/storage/claims/102/photo_102_a.jpg', '2025-06-13 11:00:00'),
    (103, 'estimate_103.pdf', 'ESTIMATE', 59500, '/storage/claims/103/estimate_103.pdf', '2025-01-16 11:00:00'),
    (104, 'invoice_104.pdf', 'INVOICE', 43000, '/storage/claims/104/invoice_104.pdf', '2025-01-08 11:00:00'),
    (105, 'photo_105_a.jpg', 'PHOTO', 2090000, '/storage/claims/105/photo_105_a.jpg', '2025-01-11 11:00:00'),
    (106, 'estimate_106.pdf', 'ESTIMATE', 61500, '/storage/claims/106/estimate_106.pdf', '2024-12-11 11:00:00'),
    (107, 'invoice_107.pdf', 'INVOICE', 57000, '/storage/claims/107/invoice_107.pdf', '2023-12-05 11:00:00'),
    (108, 'photo_108_a.jpg', 'PHOTO', 1740000, '/storage/claims/108/photo_108_a.jpg', '2025-02-21 11:00:00'),
    (109, 'estimate_109.pdf', 'ESTIMATE', 64500, '/storage/claims/109/estimate_109.pdf', '2025-04-18 11:00:00'),
    (110, 'invoice_110.pdf', 'INVOICE', 58500, '/storage/claims/110/invoice_110.pdf', '2025-04-12 11:00:00'),
    (3, 'photo_3_a.jpg', 'PHOTO', 1710000, '/storage/claims/3/photo_3_a.jpg', '2024-02-10 09:00:00'),
    (6, 'estimate_6.pdf', 'ESTIMATE', 56000, '/storage/claims/6/estimate_6.pdf', '2024-06-11 09:00:00'),
    (7, 'estimate_7.pdf', 'ESTIMATE', 60500, '/storage/claims/7/estimate_7.pdf', '2024-07-07 09:00:00'),
    (9, 'photo_9_a.jpg', 'PHOTO', 1820000, '/storage/claims/9/photo_9_a.jpg', '2024-10-11 09:00:00'),
    (11, 'photo_11_a.jpg', 'PHOTO', 1740000, '/storage/claims/11/photo_11_a.jpg', '2024-04-19 09:00:00'),
    (12, 'estimate_12.pdf', 'ESTIMATE', 57500, '/storage/claims/12/estimate_12.pdf', '2024-09-19 09:00:00'),
    (13, 'photo_13_a.jpg', 'PHOTO', 1800000, '/storage/claims/13/photo_13_a.jpg', '2024-05-21 09:00:00'),
    (16, 'photo_16_a.jpg', 'PHOTO', 1960000, '/storage/claims/16/photo_16_a.jpg', '2025-02-07 09:00:00'),
    (17, 'estimate_17.pdf', 'ESTIMATE', 63500, '/storage/claims/17/estimate_17.pdf', '2024-05-20 09:00:00'),
    (19, 'photo_19_a.jpg', 'PHOTO', 1870000, '/storage/claims/19/photo_19_a.jpg', '2024-10-05 09:00:00'),
    (21, 'photo_21_a.jpg', 'PHOTO', 1790000, '/storage/claims/21/photo_21_a.jpg', '2024-06-22 09:00:00'),
    (23, 'estimate_23.pdf', 'ESTIMATE', 68500, '/storage/claims/23/estimate_23.pdf', '2024-10-16 09:00:00'),
    (25, 'photo_25_a.jpg', 'PHOTO', 1980000, '/storage/claims/25/photo_25_a.jpg', '2025-04-26 09:00:00'),
    (26, 'estimate_26.pdf', 'ESTIMATE', 61000, '/storage/claims/26/estimate_26.pdf', '2024-12-21 09:00:00'),
    (28, 'estimate_28.pdf', 'ESTIMATE', 59000, '/storage/claims/28/estimate_28.pdf', '2025-03-17 09:00:00'),
    (30, 'photo_30_a.jpg', 'PHOTO', 1840000, '/storage/claims/30/photo_30_a.jpg', '2024-03-29 09:00:00'),
    (31, 'photo_31_a.jpg', 'PHOTO', 1860000, '/storage/claims/31/photo_31_a.jpg', '2025-01-27 09:00:00'),
    (34, 'photo_34_a.jpg', 'PHOTO', 1920000, '/storage/claims/34/photo_34_a.jpg', '2024-06-19 09:00:00'),
    (36, 'photo_36_a.jpg', 'PHOTO', 1760000, '/storage/claims/36/photo_36_a.jpg', '2024-11-19 09:00:00'),
    (37, 'estimate_37.pdf', 'ESTIMATE', 62500, '/storage/claims/37/estimate_37.pdf', '2024-10-22 09:00:00'),
    (39, 'estimate_39.pdf', 'ESTIMATE', 60000, '/storage/claims/39/estimate_39.pdf', '2024-06-16 09:00:00'),
    (41, 'photo_41_a.jpg', 'PHOTO', 1990000, '/storage/claims/41/photo_41_a.jpg', '2025-05-27 09:00:00'),
    (42, 'estimate_42.pdf', 'ESTIMATE', 58500, '/storage/claims/42/estimate_42.pdf', '2024-06-17 09:00:00'),
    (46, 'estimate_46.pdf', 'ESTIMATE', 65500, '/storage/claims/46/estimate_46.pdf', '2024-06-17 09:00:00'),
    (47, 'photo_47_a.jpg', 'PHOTO', 1880000, '/storage/claims/47/photo_47_a.jpg', '2024-05-26 09:00:00'),
    (48, 'estimate_48.pdf', 'ESTIMATE', 63000, '/storage/claims/48/estimate_48.pdf', '2024-11-21 09:00:00'),
    (49, 'photo_49_a.jpg', 'PHOTO', 1700000, '/storage/claims/49/photo_49_a.jpg', '2023-12-31 09:00:00'),
    (51, 'photo_51_a.jpg', 'PHOTO', 1910000, '/storage/claims/51/photo_51_a.jpg', '2024-08-14 09:00:00'),
    (52, 'estimate_52.pdf', 'ESTIMATE', 59500, '/storage/claims/52/estimate_52.pdf', '2024-09-11 09:00:00'),
    (54, 'estimate_54.pdf', 'ESTIMATE', 61500, '/storage/claims/54/estimate_54.pdf', '2024-02-29 09:00:00'),
    (55, 'photo_55_a.jpg', 'PHOTO', 2000000, '/storage/claims/55/photo_55_a.jpg', '2025-03-24 09:00:00'),
    (56, 'photo_56_a.jpg', 'PHOTO', 1750000, '/storage/claims/56/photo_56_a.jpg', '2025-03-29 09:00:00'),
    (57, 'photo_57_a.jpg', 'PHOTO', 1820000, '/storage/claims/57/photo_57_a.jpg', '2024-09-04 09:00:00'),
    (59, 'estimate_59.pdf', 'ESTIMATE', 64000, '/storage/claims/59/estimate_59.pdf', '2025-05-13 09:00:00'),
    (62, 'photo_62_a.jpg', 'PHOTO', 1870000, '/storage/claims/62/photo_62_a.jpg', '2025-01-10 09:00:00'),
    (64, 'estimate_64.pdf', 'ESTIMATE', 57000, '/storage/claims/64/estimate_64.pdf', '2024-07-01 09:00:00'),
    (65, 'photo_65_a.jpg', 'PHOTO', 1790000, '/storage/claims/65/photo_65_a.jpg', '2024-09-07 09:00:00'),
    (67, 'estimate_67.pdf', 'ESTIMATE', 62000, '/storage/claims/67/estimate_67.pdf', '2024-05-25 09:00:00'),
    (68, 'photo_68_a.jpg', 'PHOTO', 1800000, '/storage/claims/68/photo_68_a.jpg', '2024-12-16 09:00:00'),
    (71, 'photo_71_a.jpg', 'PHOTO', 1830000, '/storage/claims/71/photo_71_a.jpg', '2024-12-19 09:00:00'),
    (73, 'estimate_73.pdf', 'ESTIMATE', 66000, '/storage/claims/73/estimate_73.pdf', '2024-10-20 09:00:00'),
    (82, 'estimate_82.pdf', 'ESTIMATE', 59000, '/storage/claims/82/estimate_82.pdf', '2025-02-27 09:00:00'),
    (85, 'photo_85_a.jpg', 'PHOTO', 1940000, '/storage/claims/85/photo_85_a.jpg', '2024-12-26 09:00:00'),
    (87, 'photo_87_a.jpg', 'PHOTO', 1960000, '/storage/claims/87/photo_87_a.jpg', '2025-06-12 09:00:00'),
    (91, 'estimate_91.pdf', 'ESTIMATE', 60500, '/storage/claims/91/estimate_91.pdf', '2024-11-24 09:00:00'),
    (92, 'estimate_92.pdf', 'ESTIMATE', 58000, '/storage/claims/92/estimate_92.pdf', '2025-01-24 09:00:00'),
    (94, 'photo_94_a.jpg', 'PHOTO', 1900000, '/storage/claims/94/photo_94_a.jpg', '2025-01-29 09:00:00'),
    (96, 'photo_96_a.jpg', 'PHOTO', 1950000, '/storage/claims/96/photo_96_a.jpg', '2025-06-13 09:00:00'),
    (97, 'estimate_97.pdf', 'ESTIMATE', 61500, '/storage/claims/97/estimate_97.pdf', '2023-12-01 09:00:00'),
    (99, 'estimate_99.pdf', 'ESTIMATE', 59500, '/storage/claims/99/estimate_99.pdf', '2024-10-24 09:00:00'),
    (102, 'estimate_102.pdf', 'ESTIMATE', 62500, '/storage/claims/102/estimate_102.pdf', '2025-06-14 09:00:00'),
    (103, 'photo_103_a.jpg', 'PHOTO', 1870000, '/storage/claims/103/photo_103_a.jpg', '2025-01-17 09:00:00'),
    (104, 'photo_104_a.jpg', 'PHOTO', 1920000, '/storage/claims/104/photo_104_a.jpg', '2025-01-09 09:00:00'),
    (106, 'photo_106_a.jpg', 'PHOTO', 1890000, '/storage/claims/106/photo_106_a.jpg', '2024-12-12 09:00:00'),
    (107, 'photo_107_a.jpg', 'PHOTO', 1760000, '/storage/claims/107/photo_107_a.jpg', '2023-12-06 09:00:00'),
    (108, 'estimate_108.pdf', 'ESTIMATE', 60000, '/storage/claims/108/estimate_108.pdf', '2025-02-22 09:00:00'),
    (109, 'photo_109_a.jpg', 'PHOTO', 1930000, '/storage/claims/109/photo_109_a.jpg', '2025-04-19 09:00:00');

-- -----------------------------------------------------------------------------
-- 3. litigation_record
-- 6 rows, each on a different Denied claim (claim_id 58, 61, 63, 66, 69, 72
-- are all 'Denied' per 41_seed_claims_financial.sql), filing_date shortly
-- after the Denied status was recorded.
-- -----------------------------------------------------------------------------
INSERT INTO litigation_record
    (claim_id, case_reference, filing_date, status, attorney_name, created_at)
VALUES
    (58, 'CASE-2024-00118', '2024-08-12', 'Active', 'Daniel Marsh', '2024-08-12 10:00:00'),
    (61, 'CASE-2025-00042', '2025-03-28', 'Active', 'Patricia Nolan', '2025-03-28 10:00:00'),
    (63, 'CASE-2024-00205', '2024-04-15', 'Dismissed', 'Gregory Shaw', '2024-04-15 10:00:00'),
    (66, 'CASE-2024-00231', '2024-09-16', 'Active', 'Monica Reyes', '2024-09-16 10:00:00'),
    (69, 'CASE-2025-00098', '2025-06-20', 'Settled', 'Harold Dixon', '2025-06-20 10:00:00'),
    (72, 'CASE-2024-00147', '2024-05-14', 'Dismissed', 'Lauren Chase', '2024-05-14 10:00:00');

-- -----------------------------------------------------------------------------
-- 4. subrogation_record
-- 12 claims from Settled/Closed status with recovery_amount strictly between
-- 0.01 and the claim's net_paid_amount (per 41_seed_claims_financial.sql),
-- recorded_date after the claim's settlement approved_at date.
--
-- claim_id | net_paid_amount | settlement.approved_at      | recovery_amount
-- 74       | 17339.01        | 2024-08-15 12:00:00         | 3500.00
-- 76       | 94924.29        | 2025-01-25 12:00:00         | 20000.00
-- 78       | 1917.93         | 2025-02-03 12:00:00         | 500.00
-- 81       | 16434.69        | 2024-12-31 12:00:00         | 4000.00
-- 83       | 32518.69        | 2024-11-30 12:00:00         | 8500.00
-- 86       | 49131.05        | 2025-04-28 12:00:00         | 12000.00
-- 89       | 21653.46        | 2024-12-28 12:00:00         | 5000.00
-- 93       | 104315.55       | 2025-06-30 12:00:00         | 25000.00
-- 95       | 19547.45        | 2024-12-17 12:00:00         | 6000.00
-- 98       | 43236.05        | 2025-04-04 12:00:00         | 9500.00
-- 101      | 42885.48        | 2024-12-30 12:00:00         | 11000.00
-- 105      | 87561.11        | 2025-02-01 12:00:00         | 18000.00
-- -----------------------------------------------------------------------------
INSERT INTO subrogation_record
    (claim_id, third_party_identifier, recovery_amount, recorded_date, created_at)
VALUES
    (74, 'Meridian Mutual Insurance Co.', 3500.00, '2024-08-25', '2024-08-25 10:00:00'),
    (76, 'Granite State Casualty Co.', 20000.00, '2025-02-10', '2025-02-10 10:00:00'),
    (78, 'Harborview Indemnity Group', 500.00, '2025-02-15', '2025-02-15 10:00:00'),
    (81, 'Union Crest Insurance Co.', 4000.00, '2025-01-15', '2025-01-15 10:00:00'),
    (83, 'Pinnacle Assurance Partners', 8500.00, '2024-12-10', '2024-12-10 10:00:00'),
    (86, 'Coastal Reciprocal Exchange', 12000.00, '2025-05-10', '2025-05-10 10:00:00'),
    (89, 'Vanguard Fidelity Insurance Co.', 5000.00, '2025-01-10', '2025-01-10 10:00:00'),
    (93, 'Summit Point Casualty Co.', 25000.00, '2025-07-15', '2025-07-15 10:00:00'),
    (95, 'Keystone Reliance Insurance Co.', 6000.00, '2024-12-28', '2024-12-28 10:00:00'),
    (98, 'Beacon Hill Mutual Group', 9500.00, '2025-04-18', '2025-04-18 10:00:00'),
    (101, 'Lakeshore Assurance Co.', 11000.00, '2025-01-14', '2025-01-14 10:00:00'),
    (105, 'Redwood Casualty Exchange', 18000.00, '2025-02-12', '2025-02-12 10:00:00');
