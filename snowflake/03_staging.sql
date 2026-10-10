-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.TEAM_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.TEAM_DAILY observation
    LEFT JOIN RAW.TEAMS team ON team.ID = observation.ENTITY_ID
    WHERE team.ID IS NULL OR observation.CONTACTS_HANDLED < 0
       OR observation.LABOUR_COST_PHP < 0
       OR observation.GAP_COUNT < 0 OR observation.GAP_COUNT > observation.WORKFORCE_EVENT_COUNT
       OR observation.WORKFORCE_EVENT_COUNT > observation.CONTACTS_HANDLED
       OR observation.SLA_BREACHED > observation.GAP_COUNT
       OR observation.QA_COMPLETED > observation.QA_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
