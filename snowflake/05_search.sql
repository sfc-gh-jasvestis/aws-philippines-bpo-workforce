-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.HR_POLICY_SEARCH
  ON PROGRAM_DESCRIPTION
  ATTRIBUTES PROGRAM_TYPE, SITE_ID, SKILL_CATEGORY
  WAREHOUSE = BPO_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.TRAINING_RECORDS
);
