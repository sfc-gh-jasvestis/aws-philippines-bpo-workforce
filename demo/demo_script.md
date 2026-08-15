# Demo Script: BPO Workforce Analytics & Attrition Prediction
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake predicts agent attrition across 45 BPO sites, classifies flight-risk employees with ML, surfaces retention drivers with TOP_INSIGHTS, and notifies HR via SES — all native SQL, no external ML platform needed"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Maria Cristina Santos-Reyes** | Chief People Officer | React App (SPCS) | Attrition rates, cost-per-hire, workforce capacity, succession planning |
| **James Benedict Tan** | Workforce Planning Manager | Amazon QuickSight | Shift scheduling, agent utilization, training effectiveness, flight-risk scoring |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | SITES (45), AGENTS (28000), ATTENDANCE_LOGS (850000), PERFORMANCE_SCORES (112000), SEPARATIONS (4200), TRAINING_RECORDS (65000), COMPENSATION_BENCHMARKS (200), LABOR_MARKET (12) |
| **CURATED** | 4 Dynamic Tables | SITE_ATTRITION_SUMMARY, AGENT_RISK_PROFILE, ATTRITION_TIMESERIES, TRAINING_EFFECTIVENESS |
| **ML** | ML.CLASSIFICATION + ML.TOP_INSIGHTS | Forecasting + anomaly detection |
| **AI** | AI_CLASSIFY, COMPLETE | Classification + extraction |
| **Search** | Cortex Search | 65000 documents indexed |
| **Agent** | WORKFORCE_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

The Philippines is the world's BPO capital — $32.5 billion in revenue, 1.7 million workers. But the industry hemorrhages talent at 30-40% annually. One major BPO company with 28,000 agents across 45 sites is losing ₱420M per year to attrition. Traditional HRIS reports detect trends too late — by the time HR notices, the agent's already signed with a competitor down the road in BGC.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Four hundred twenty million pesos in annual attrition cost across 45 BPO sites."

**Action**: Point at the ₱420M attrition cost KPI

### [0:45–1:30] ATTRITION ANALYTICS

**Show**: Attrition Analytics tab

> "Cebu IT Park running 11.2% monthly attrition — highest in the network."

**Action**: Click Cebu IT Park in the site list

### [1:30–2:15] RETENTION INTELLIGENCE

**Show**: Retention Intelligence tab

> "Training completion correlates with 34% lower attrition — programs work."

**Action**: Show training effectiveness chart

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Maria Cristina asks: 'What's our cost of attrition for Cebu this quarter?'"

**Action**: Type: 'What is the attrition cost for Cebu Q3?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services replaced or complemented."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.CLASSIFICATION for attrition prediction** — Only demo using native Snowflake classification for HR/people analytics
2. **ML.TOP_INSIGHTS for driver analysis** — Reveals non-obvious attrition drivers without data science team
3. **SES notification integration** — End-to-end: predict → classify → alert HR via email — no middleware
4. **Philippine BPO labor market context** — ₱32.5B industry-specific data with Filipino names, sites, compensation benchmarks
5. **Training effectiveness correlation** — Links L&D investment directly to retention outcomes via Dynamic Tables
6. **28,000 agent profiles scored weekly** — Scale demo — not toy 100-row dataset but realistic enterprise BPO headcount


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM BPO_WORKFORCE.RAW.AGENTS` → 28000
- [ ] `SELECT COUNT(*) FROM BPO_WORKFORCE.RAW.ATTENDANCE_LOGS` → 850000
- [ ] `SELECT COUNT(DISTINCT SITE_ID) FROM BPO_WORKFORCE.CURATED.SITE_ATTRITION_SUMMARY WHERE ATTRITION_STATUS = 'CRITICAL'` → 3

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM BPO_WORKFORCE.ML.ATTRITION_CLASSIFICATION_RESULTS WHERE FLIGHT_RISK_SCORE > 0.75` → ~1247
- [ ] `SELECT COUNT(*) FROM BPO_WORKFORCE.ML.ATTRITION_TOP_INSIGHTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM BPO_WORKFORCE.AI.SEPARATION_CLASSIFICATION` → 4200

