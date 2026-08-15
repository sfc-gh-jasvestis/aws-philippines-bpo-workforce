-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_RETRAIN_ATTRITION_MODEL
  WAREHOUSE = BPO_WH
  SCHEDULE = 'USING CRON 0 0 * * SUN UTC'
  COMMENT = 'Retrain attrition classification model weekly'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SCORE_AGENTS
  WAREHOUSE = BPO_WH
  AFTER APP.TASK_RETRAIN_ATTRITION_MODEL
  COMMENT = 'Score all agents for flight risk'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_NOTIFY_HR
  WAREHOUSE = BPO_WH
  AFTER APP.TASK_SCORE_AGENTS
  COMMENT = 'Send SES notification for critical flight risks'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_NOTIFY_HR RESUME;
ALTER TASK APP.TASK_SCORE_AGENTS RESUME;
ALTER TASK APP.TASK_RETRAIN_ATTRITION_MODEL RESUME;
