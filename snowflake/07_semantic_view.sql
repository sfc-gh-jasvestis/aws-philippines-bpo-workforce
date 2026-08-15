-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.BPO_WORKFORCE_ANALYTICS
  COMMENT = 'BPO workforce attrition, performance, and capacity analytics'
AS
  TABLES (
    CURATED.SITE_ATTRITION_SUMMARY AS site_attrition_summary,CURATED.AGENT_RISK_PROFILE AS agent_risk_profile,CURATED.ATTRITION_TIMESERIES AS attrition_timeseries,CURATED.TRAINING_EFFECTIVENESS AS training_effectiveness
  );
