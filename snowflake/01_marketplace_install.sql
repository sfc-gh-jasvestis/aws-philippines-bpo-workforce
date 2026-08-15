-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): CEIC ASEAN Macro
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZRC7HPI
--   Using mock table: LABOR_MARKET
CREATE TABLE IF NOT EXISTS RAW.LABOR_MARKET (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

