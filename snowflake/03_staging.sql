-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for BPO Workforce Analytics & Attrition Prediction
-- Country: PHILIPPINES | Currency: PHP
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- SITES: 45 rows — BPO delivery centers across Philippines (NCR, Cebu, Clark, Davao)
-- AGENTS: 28,000 rows — Active BPO agents with tenure, performance, compensation data
-- ATTENDANCE_LOGS: 850,000 rows — 90 days of attendance, tardiness, overtime records
-- PERFORMANCE_SCORES: 112,000 rows — Monthly KPI scores (CSAT, AHT, FCR, schedule adherence)
-- SEPARATIONS: 4,200 rows — 12 months of resignation and termination records
-- TRAINING_RECORDS: 65,000 rows — Certifications, upskilling programs, nesting completion
-- COMPENSATION_BENCHMARKS: 200 rows — Market salary data by role and location
-- LABOR_MARKET: 12 rows — Philippines BPO labor market indicators
