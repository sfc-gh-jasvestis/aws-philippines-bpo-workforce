-- ============================================================================
-- BPO Workforce Analytics & Attrition Prediction
-- Philippines is the world's BPO capital with 1.7M agents — Snowflake ML predicts attrition 60 days out, classifies flight-risk agents, surfaces top drivers, and alerts HR before critical talent walks.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS BPO_WORKFORCE;
CREATE WAREHOUSE IF NOT EXISTS BPO_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE BPO_WORKFORCE;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE BPO_WH;
