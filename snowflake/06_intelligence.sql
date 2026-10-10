-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live staffing-gap alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_STAFFING_EVENTS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic workforce-event knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.WORKFORCE_SOP_DOCS AS
WITH types AS (
  SELECT DISTINCT r.EVENT_TYPE, a.CATEGORY
  FROM RAW.TEAM_DAILY r JOIN RAW.TEAMS a ON a.ID = r.ENTITY_ID
  WHERE r.GAP_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, EVENT_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  EVENT_TYPE,
  CATEGORY || ' - ' || EVENT_TYPE || ' staffing response' AS TITLE,
  'Synthetic demo SOP. Line of business: ' || CATEGORY || '. Workforce event: ' || EVENT_TYPE || '. '
  || 'Step 1: the real-time analyst logs the event, notes the affected queues and the interval-level staffing shortfall, and informs the team lead. '
  || 'Step 2: ' || CASE
       WHEN EVENT_TYPE = 'Unplanned absence surge' THEN 'offer voluntary overtime to agents on rest days, move cross-skilled agents from lower-priority queues, and defer offline coaching sessions until the interval recovers.'
       WHEN EVENT_TYPE = 'Call volume spike' THEN 'compare actual volume with the forecast, open the overflow queue to a sister team, and agree a temporary service-level target with the client account manager.'
       WHEN EVENT_TYPE = 'Resignation cluster' THEN 'ask HR business partners to hold stay conversations with the team, review schedule fairness and night-differential rotation, and request backfill from the next training wave.'
       WHEN EVENT_TYPE = 'CRM slowdown' THEN 'switch agents to the offline case template, raise a priority ticket with the client IT desk, and add handle-time allowance to the interval forecast until the system recovers.'
       WHEN EVENT_TYPE = 'Knowledge base gap' THEN 'publish an interim answer from the subject-matter expert, brief agents at the next huddle, and log the article gap with the client content owner.'
       WHEN EVENT_TYPE = 'Dialer outage' THEN 'move agents to manual dialling for the priority segment, notify the client, and recalculate the day''s contact plan once the dialer is back.'
       WHEN EVENT_TYPE = 'Script compliance hold' THEN 'pause the affected campaign, have QA review the flagged calls, and resume only after the team lead confirms the corrected script with every agent.'
       WHEN EVENT_TYPE = 'Network link down' THEN 'fail over to the backup link, confirm that agent desktops and softphones reconnect, and escalate to the network operations centre if the backup link is also down.'
       WHEN EVENT_TYPE = 'Backlog surge' THEN 'prioritise cases by client deadline, borrow trained agents from voice teams for the backlog, and report the expected clearance date to the client.'
       WHEN EVENT_TYPE = 'Chat platform outage' THEN 'route chats to email or callback, post a status message on the client channel, and log the outage window with the platform vendor.'
       ELSE 'review the event against the team profile and escalate to workforce management if unexplained.'
     END
  || ' Step 3: if unplanned absence on the team stays above 8% or average handle time stays above 12 minutes after the fix, keep the event open and request a team review with workforce management. '
  || 'Step 4: record the resolution; if the team was understaffed against forecast or the client service level was breached, log it for the weekly workforce report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.WORKFORCE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, EVENT_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, EVENT_TYPE, CONTENT FROM SEARCH.WORKFORCE_SOP_DOCS);

-- ---------- Unplanned absence anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.ABSENCE_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, ABSENCE_PCT::FLOAT AS ABSENCE
FROM RAW.TEAM_DAILY;
CREATE OR REPLACE VIEW ML.ABSENCE_TRAIN AS
SELECT * FROM ML.ABSENCE_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ABSENCE_SERIES);
CREATE OR REPLACE VIEW ML.ABSENCE_DETECT AS
SELECT * FROM ML.ABSENCE_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ABSENCE_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.ABSENCE_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ABSENCE_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ABSENCE',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.ABSENCE_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS ABSENCE, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.ABSENCE_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ABSENCE_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ABSENCE'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.WORKFORCE_ANALYTICS
  TABLES (
    teams AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'teams', 'agent teams', 'pods')
      COMMENT = 'One row per fictional BPO agent team in a Philippine city, 90-day totals',
    risk AS ML.GAP_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day staffing-gap probability per team',
    events AS CURATED.EVENT_TYPE_SUMMARY PRIMARY KEY (EVENT_TYPE)
      COMMENT = 'Workforce events, staffing-gap events and client SLA breaches by event type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Company-wide totals per day'
  )
  RELATIONSHIPS (risk_team AS risk (ENTITY_ID) REFERENCES teams)
  FACTS (
    teams.events_f AS WORKFORCE_EVENT_COUNT,
    teams.gaps_f AS GAP_COUNT,
    teams.breaches_f AS SLA_BREACH_COUNT,
    teams.contacts_f AS CONTACTS_HANDLED,
    teams.cost_f AS LABOUR_COST_PHP,
    teams.qa_due_f AS QA_DUE,
    teams.qa_done_f AS QA_COMPLETED,
    risk.gap_prob_f AS GAP_PROB_7D,
    events.type_events_f AS WORKFORCE_EVENT_COUNT,
    events.type_gaps_f AS GAP_COUNT,
    events.type_breaches_f AS SLA_BREACH_COUNT,
    events.type_cost_f AS EXPOSED_LABOUR_COST_PHP,
    daily.day_events_f AS WORKFORCE_EVENT_COUNT,
    daily.day_gaps_f AS GAP_COUNT,
    daily.day_cost_f AS LABOUR_COST_PHP
  )
  DIMENSIONS (
    teams.team_code AS ENTITY_ID WITH SYNONYMS = ('team', 'team id', 'entity'),
    teams.team_name AS ENTITY_NAME,
    teams.city AS REGION WITH SYNONYMS = ('city', 'region', 'site location')
      COMMENT = 'Philippine city of the team''s site',
    teams.line_of_business AS CATEGORY WITH SYNONYMS = ('line of business', 'LOB', 'team type'),
    teams.risk_tier AS RISK_TIER COMMENT = 'Team staffing risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    events.workforce_event_type AS EVENT_TYPE WITH SYNONYMS = ('event type', 'workforce event', 'disruption type'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    teams.team_total AS COUNT(teams.team_code)
      WITH SYNONYMS = ('number of teams', 'number of entities', 'how many teams'),
    teams.event_free_contact_pct AS 100 * (SUM(teams.contacts_f) - SUM(teams.events_f)) / NULLIF(SUM(teams.contacts_f), 0)
      WITH SYNONYMS = ('event-free contact rate')
      COMMENT = 'Contacts not touched by a workforce event / contacts handled',
    teams.gap_share_pct AS 100 * SUM(teams.gaps_f) / NULLIF(SUM(teams.events_f), 0)
      WITH SYNONYMS = ('event gap rate')
      COMMENT = 'Staffing-gap events / workforce events logged',
    teams.events_logged AS SUM(teams.events_f) WITH SYNONYMS = ('workforce events', 'event volume'),
    teams.staffing_gap_events AS SUM(teams.gaps_f) WITH SYNONYMS = ('staffing gaps', 'understaffed events'),
    teams.client_sla_breaches AS SUM(teams.breaches_f) WITH SYNONYMS = ('SLA breaches', 'service-level misses'),
    teams.total_contacts_handled AS SUM(teams.contacts_f),
    teams.total_labour_cost_php AS SUM(teams.cost_f) WITH SYNONYMS = ('labour cost', 'labour cost in PHP'),
    teams.qa_calibration_pct AS 100 * SUM(teams.qa_done_f) / NULLIF(SUM(teams.qa_due_f), 0)
      COMMENT = 'QA calibration reviews completed / reviews due',
    risk.avg_gap_prob AS AVG(risk.gap_prob_f),
    events.type_events AS SUM(events.type_events_f),
    events.type_gaps AS SUM(events.type_gaps_f),
    events.type_breaches AS SUM(events.type_breaches_f),
    events.type_gap_share_pct AS 100 * SUM(events.type_gaps_f) / NULLIF(SUM(events.type_events_f), 0),
    daily.daily_events AS SUM(daily.day_events_f),
    daily.daily_gaps AS SUM(daily.day_gaps_f),
    daily.daily_labour_cost_php AS SUM(daily.day_cost_f)
  )
  COMMENT = 'Synthetic Philippine BPO workforce operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.WORKFORCE_AGENT
  COMMENT = 'Workforce operations assistant over a synthetic Philippine BPO'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give team IDs and numbers with units (PHP, %). Data is team-level only; never discuss individual agents."
  orchestration: "Use workforce_analyst for teams, cities, lines of business, contacts handled, labour cost, workforce events, staffing-gap events, client SLA breaches, QA calibration compliance, event types and staffing-gap risk. Use sop_search for staffing-response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: workforce_analyst
      description: "Team count, contacts handled, labour cost in PHP, workforce events, staffing-gap events, client SLA breaches, event-free contact rate, QA calibration compliance, event types and staffing-gap risk scores by team, city and line of business"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic staffing-response SOPs by line of business and workforce event type"
tool_resources:
  workforce_analyst:
    semantic_view: __DEMO_DB__.APP.WORKFORCE_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.WORKFORCE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;
-- ---------- Live staffing-gap alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), TEAM_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, QUEUE_CALLS FLOAT, WAIT_SECONDS FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION PH_BPO_WORKFORCE_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (TEAM_ID, EVENT_TS, QUEUE_CALLS, WAIT_SECONDS, SOP_HINT)
    SELECT p.TEAM_ID, p.EVENT_TS, p.QUEUE_CALLS, p.WAIT_SECONDS,
           'Check ' || r.CATEGORY || ' staffing-response SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_STAFFING_EVENTS p
    JOIN RAW.TEAMS r ON r.ID = p.TEAM_ID
    LEFT JOIN ML.GAP_RISK_SCORES s ON s.ENTITY_ID = p.TEAM_ID
    WHERE p.STATUS = 'GAP'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.TEAM_ID = p.TEAM_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('PH_BPO_WORKFORCE_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Team staffing-gap alert',
      'New live staffing-gap events logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_GAP_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_STAFFING_EVENTS p
    WHERE p.STATUS = 'GAP'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.TEAM_ID = p.TEAM_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.EVENT_TYPE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.GAP_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.GAP_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.GAP_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'AVG_TENURE_YEARS', AVG_TENURE_YEARS,
             'ABSENCE_PCT', ABSENCE_PCT, 'AVG_HANDLE_MIN', AVG_HANDLE_MIN,
             'ABSENCE_7D', ABSENCE_7D, 'GAPS_30D', GAPS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:GAP::FLOAT, 4) AS GAP_PROB_7D,
         CASE WHEN PRED:probability:GAP::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:GAP::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
