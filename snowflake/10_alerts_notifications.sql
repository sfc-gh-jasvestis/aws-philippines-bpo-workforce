-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_philippines_bpo_workforce_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: ATTRITION_SPIKE_ALERT
CREATE OR REPLACE ALERT APP.ATTRITION_SPIKE_ALERT
  WAREHOUSE = BPO_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Attrition rate exceeds critical threshold at site'
IF (EXISTS (
  SELECT 1 FROM CURATED.SITE_ATTRITION_SUMMARY
  WHERE 1=1 -- Condition: MONTHLY_ATTRITION_RATE > 8% for any site
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_workforce_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] BPO Workforce Analytics & Attrition Prediction: Attrition rate exceeds critical threshold at site',
    'Attrition rate exceeds critical threshold at site'
  );

ALTER ALERT APP.ATTRITION_SPIKE_ALERT RESUME;

-- Alert: HIGH_PERFORMER_FLIGHT_ALERT
CREATE OR REPLACE ALERT APP.HIGH_PERFORMER_FLIGHT_ALERT
  WAREHOUSE = BPO_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'High-performer flagged as flight risk'
IF (EXISTS (
  SELECT 1 FROM CURATED.SITE_ATTRITION_SUMMARY
  WHERE 1=1 -- Condition: HIGH_PERFORMER = TRUE AND FLIGHT_RISK_SCORE > 0.75
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_workforce_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] BPO Workforce Analytics & Attrition Prediction: High-performer flagged as flight risk',
    'High-performer flagged as flight risk'
  );

ALTER ALERT APP.HIGH_PERFORMER_FLIGHT_ALERT RESUME;

