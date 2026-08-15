-- ============================================================================
-- 06_ML_MODELS.SQL — ML Functions for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA ML;

-- ML.CLASSIFICATION: ATTRITION_CLASSIFIER
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION ML.ATTRITION_CLASSIFIER(
  INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'CURATED.AGENT_RISK_PROFILE'),
  TARGET_COLNAME => 'WILL_RESIGN_60D'
);

-- ML.TOP_INSIGHTS: ATTRITION_DRIVERS
-- Call: SELECT * FROM TABLE(ML.ATTRITION_DRIVERS!GET_INSIGHTS(INPUT_DATA => ...));

