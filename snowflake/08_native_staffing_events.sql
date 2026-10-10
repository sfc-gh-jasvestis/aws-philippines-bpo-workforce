-- ============================================================================
-- 08_native_staffing_events.sql - Snowflake-only build: live team staffing feed without AWS.
-- Creates RAW.LIVE_STAFFING_EVENTS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_STAFFING_EVENTS(N), which inserts synthetic
-- interval staffing events (calls waiting, longest wait) with the same ranges and ~10% GAP rate as
-- aws/publish_staffing_events.py. Rows are inserted directly; this simulates an interval
-- staffing feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_STAFFING_EVENTS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_STAFFING_EVENTS (
  TEAM_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, QUEUE_CALLS FLOAT, WAIT_SECONDS FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_STAFFING_EVENTS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_STAFFING_EVENTS (TEAM_ID, EVENT_TS, QUEUE_CALLS, WAIT_SECONDS, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'TM-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS TEAM_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_GAP,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the gap offset is applied outside it.
    SELECT TEAM_ID, TS,
           ROUND(IFF(IS_GAP, 46, 9) * EXP(NORMAL(0, 0.5, RANDOM())), 0),
           ROUND(IFF(IS_GAP, 540, 40) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_GAP, 'GAP', 'OK'), TS, 'APP.SIMULATE_STAFFING_EVENTS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_STAFFING_EVENTS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_STAFFING_EVENTS(5);
