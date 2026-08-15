-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA CURATED;

-- SITE_ATTRITION_SUMMARY: Site-level attrition rates, cost, and headcount trends
-- Source: SITES, AGENTS, SEPARATIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SITE_ATTRITION_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BPO_WH
AS
SELECT * FROM RAW.SITES;
-- TODO: Replace with actual join/aggregation logic per demo

-- AGENT_RISK_PROFILE: Per-agent flight risk score combining attendance, performance, tenure
-- Source: AGENTS, ATTENDANCE_LOGS, PERFORMANCE_SCORES
CREATE OR REPLACE DYNAMIC TABLE CURATED.AGENT_RISK_PROFILE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BPO_WH
AS
SELECT * FROM RAW.AGENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- ATTRITION_TIMESERIES: Weekly attrition rates by site for ML.FORECAST
-- Source: SEPARATIONS, SITES
CREATE OR REPLACE DYNAMIC TABLE CURATED.ATTRITION_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BPO_WH
AS
SELECT * FROM RAW.SEPARATIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- TRAINING_EFFECTIVENESS: Training program completion vs retention correlation
-- Source: TRAINING_RECORDS, SEPARATIONS, AGENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.TRAINING_EFFECTIVENESS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BPO_WH
AS
SELECT * FROM RAW.TRAINING_RECORDS;
-- TODO: Replace with actual join/aggregation logic per demo

