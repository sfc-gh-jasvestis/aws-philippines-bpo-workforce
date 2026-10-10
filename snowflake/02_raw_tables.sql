-- Synthetic team-day workforce observations for a fictional Philippine BPO, Bagwis Contact Services.
-- A team is one fictional agent team at a site in one of five Philippine cities. Rows are
-- team-level aggregates only: there are no agent-level or personal records.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-team staffing-gap propensity, drift between QA calibration
-- reviews, missed reviews, line-weighted workforce event types, events absorbed
-- without a staffing gap, and two city-wide typhoon site closures.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.TEAMS AS
WITH teams AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS TEAM_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT TEAM_INDEX,
         MOD(ABS(HASH(TEAM_INDEX, 'phbpow-tenure')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(TEAM_INDEX, 'phbpow-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(TEAM_INDEX, 'phbpow-qa')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(TEAM_INDEX, 'phbpow-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(TEAM_INDEX, 'phbpow-tier')), 1000000) / 1e6 AS U_TIER
  FROM teams
)
SELECT 'TM-' || LPAD(TEAM_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic team ' || LPAD(TEAM_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and line of business is present.
       CASE MOD(TEAM_INDEX, 5) WHEN 0 THEN 'Makati City' WHEN 1 THEN 'Cebu City'
            WHEN 2 THEN 'Davao City' WHEN 3 THEN 'Iloilo City' ELSE 'Bacolod City' END AS REGION,
       CASE MOD(TEAM_INDEX, 8) WHEN 0 THEN 'Voice customer care' WHEN 1 THEN 'Voice customer care'
            WHEN 2 THEN 'Voice customer care' WHEN 3 THEN 'Technical support' WHEN 4 THEN 'Technical support'
            WHEN 5 THEN 'Collections' WHEN 6 THEN 'Back-office processing' ELSE 'Overnight chat support' END AS CATEGORY,
       TEAM_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       -- Average agent tenure on the team, 0.4 to 6.0 years.
       ROUND(0.4 + U_AGE * 5.6, 1) AS AVG_TENURE_YEARS,
       -- Base daily probability of a staffing-gap event 0.6%-3.2%;
       -- ~14% of teams are chronically fragile (x3).
       (0.006 + U_RATE * 0.026) * IFF(U_RATE > 0.86, 3, 1) AS BASE_GAP_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS QA_INTERVAL_DAYS,
       0.5 + U_DISCIPLINE * 0.48 AS QA_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.TEAM_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide typhoon site closures; every team in the city logs an event
  -- that is absorbed by moving its queues to other sites.
  SELECT * FROM VALUES (27, 'Iloilo City'), (63, 'Cebu City') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.TEAM_INDEX, r.CATEGORY, r.REGION, r.AVG_TENURE_YEARS,
         r.BASE_GAP_RATE, r.QA_INTERVAL_DAYS, r.QA_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.TEAM_INDEX * 3, r.QA_INTERVAL_DAYS) AS DAYS_SINCE_QA,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-gap')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-absorb')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbpow-sla')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.TEAMS r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), qa AS (
  SELECT *,
         IFF(DAYS_SINCE_QA = 0, 1, 0) AS QA_DUE,
         IFF(DAYS_SINCE_QA = 0 AND U_DONE < QA_COMPLETION_PROB, 1, 0) AS QA_COMPLETED,
         -- Coaching drift rises between QA calibration reviews; weak review discipline carries it over.
         DAYS_SINCE_QA / QA_INTERVAL_DAYS + (1 - QA_COMPLETION_PROB) AS DRIFT
  FROM base
), gaps AS (
  SELECT *,
         -- Newer teams (short average tenure) are more fragile.
         CASE WHEN U_FAIL < LEAST(0.5, BASE_GAP_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + AVG_TENURE_YEARS))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_GAP_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + AVG_TENURE_YEARS))) THEN 1
              ELSE 0 END AS GAP_RISK_COUNT
  FROM qa
), events AS (
  SELECT *,
         -- About 85% of at-risk days log a workforce event that leaves the team
         -- understaffed against forecast; the rest are covered without one being logged.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, GAP_RISK_COUNT, 0)) AS GAP_COUNT,
         -- Events absorbed without a staffing gap: higher for flexible lines.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Overnight chat support' THEN 0.19
                                                       WHEN 'Technical support' THEN 0.14
                                                       WHEN 'Collections' THEN 0.10 ELSE 0.07 END, 1, 0)) AS CLEARED_COUNT
  FROM gaps
), measured AS (
  SELECT *,
         GAP_COUNT + CLEARED_COUNT AS WORKFORCE_EVENT_COUNT,
         ROUND(CASE CATEGORY WHEN 'Overnight chat support' THEN 780 WHEN 'Technical support' THEN 620
                             WHEN 'Collections' THEN 1400 WHEN 'Back-office processing' THEN 380 ELSE 950 END
               * (0.7 + 0.6 * U_VOLUME) * (1 - 0.15 * GAP_RISK_COUNT)) AS CONTACTS_HANDLED,
         CASE CATEGORY WHEN 'Overnight chat support' THEN 47 WHEN 'Technical support' THEN 85
                       WHEN 'Collections' THEN 40 WHEN 'Back-office processing' THEN 120 ELSE 58 END
           * (0.8 + 0.4 * U_NOISE) AS COST_PER_CONTACT_PHP
  FROM events
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       CONTACTS_HANDLED,
       ROUND(CONTACTS_HANDLED * COST_PER_CONTACT_PHP, 2) AS LABOUR_COST_PHP,
       WORKFORCE_EVENT_COUNT, GAP_COUNT,
       IFF(GAP_COUNT > 0 AND U_SLA < 0.55, 1, 0) AS SLA_BREACHED,
       CASE WHEN WORKFORCE_EVENT_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Typhoon site closure'
            WHEN CATEGORY = 'Voice customer care' THEN IFF(U_TYPE < 0.5, 'Unplanned absence surge', IFF(U_TYPE < 0.8, 'Call volume spike', 'Resignation cluster'))
            WHEN CATEGORY = 'Technical support' THEN IFF(U_TYPE < 0.45, 'CRM slowdown', IFF(U_TYPE < 0.8, 'Call volume spike', 'Knowledge base gap'))
            WHEN CATEGORY = 'Collections' THEN IFF(U_TYPE < 0.55, 'Dialer outage', 'Script compliance hold')
            WHEN CATEGORY = 'Back-office processing' THEN IFF(U_TYPE < 0.45, 'Network link down', IFF(U_TYPE < 0.8, 'Backlog surge', 'Resignation cluster'))
            ELSE IFF(U_TYPE < 0.5, 'Unplanned absence surge', IFF(U_TYPE < 0.75, 'Chat platform outage', 'Network link down')) END AS EVENT_TYPE,
       QA_DUE, QA_COMPLETED,
       -- Unplanned absence (% of scheduled agent hours) and average handle time (minutes).
       ROUND(1.8 + 2.4 * DRIFT + 3.4 * GAP_RISK_COUNT + U_NOISE * 1.1, 2) AS ABSENCE_PCT,
       ROUND(5.5 + 2.6 * DRIFT + 3.2 * GAP_RISK_COUNT + U_NOISE * 1.8, 1) AS AVG_HANDLE_MIN,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Required compliance training coverage per team (snapshot).
CREATE TABLE RAW.TRAINING_RECORDS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Voice customer care' THEN 'Data privacy refresher'
                     WHEN 'Technical support' THEN 'Product certification'
                     WHEN 'Collections' THEN 'Fair collection conduct training'
                     WHEN 'Back-office processing' THEN 'Information security attestation'
                     ELSE 'Chat quality calibration' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'phbpow-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'phbpow-done-cert')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'phbpow-done-cert')), 5) < 1 + MOD(ABS(HASH(ID, 'phbpow-req')), 4),
           MOD(ABS(HASH(ID, 'phbpow-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.TEAMS;
