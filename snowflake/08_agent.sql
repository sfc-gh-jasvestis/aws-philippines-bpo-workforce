-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for BPO Workforce Analytics & Attrition Prediction
-- ============================================================================
USE DATABASE BPO_WORKFORCE;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.WORKFORCE_INTELLIGENCE_AGENT
  COMMENT = 'BPO Workforce Analytics & Attrition Prediction AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'BPO_WORKFORCE.APP.BPO_WORKFORCE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'BPO_WORKFORCE.SEARCH.HR_POLICY_SEARCH', TOOL_DESCRIPTION => 'Search documents for BPO & IT Services information')
  )
  SYSTEM_PROMPT = 'You are the Workforce Intelligence Agent for a Philippine BPO company with 28,000 agents across 45 sites in NCR, Cebu, Clark, and Davao.';
