-- Generated from generator/demo_specs/aws-philippines-bpo-workforce.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-philippines-bpo-workforce
-- This is the schema that is actually deployed for PH_BPO_WORKFORCE.

-- PH_BPO_WORKFORCE  (BPO Workforce Analytics & Attrition Prediction)
-- generated from generator/demo_specs/aws-philippines-bpo-workforce.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS PH_BPO_WORKFORCE;
CREATE SCHEMA IF NOT EXISTS PH_BPO_WORKFORCE.RAW;
CREATE SCHEMA IF NOT EXISTS PH_BPO_WORKFORCE.CURATED;
CREATE SCHEMA IF NOT EXISTS PH_BPO_WORKFORCE.APP;
USE DATABASE PH_BPO_WORKFORCE;

-- 5 real regions; entity names carry their region so the two always agree
