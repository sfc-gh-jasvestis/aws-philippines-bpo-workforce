# BPO Workforce Analytics & Attrition Prediction

**Philippines - BPO & IT Services**
Use case: Workforce Analytics

> Philippines is the world's BPO capital with 1.7M agents — Snowflake ML predicts attrition 60 days out, classifies flight-risk agents, surfaces top drivers, and alerts HR before critical talent walks.

## Why Snowflake

Snowflake predicts agent attrition across 45 BPO sites, classifies flight-risk employees with ML, surfaces retention drivers with TOP_INSIGHTS, and notifies HR via SES — all native SQL, no external ML platform needed

- **ML.CLASSIFICATION for attrition prediction** - Only demo using native Snowflake classification for HR/people analytics
- **ML.TOP_INSIGHTS for driver analysis** - Reveals non-obvious attrition drivers without data science team
- **SES notification integration** - End-to-end: predict → classify → alert HR via email — no middleware
- **Philippine BPO labor market context** - ₱32.5B industry-specific data with Filipino names, sites, compensation benchmarks
- **Training effectiveness correlation** - Links L&D investment directly to retention outcomes via Dynamic Tables
- **28,000 agent profiles scored weekly** - Scale demo — not toy 100-row dataset but realistic enterprise BPO headcount

## What is deployed

| | |
|---|---|
| Database | `PH_BPO_WORKFORCE` |
| Service | `PH_BPO_WORKFORCE_APP` |
| Compute pool | `SEA_DEMOS_PHILIPPINES_POOL` |
| Dimension table | `RAW.LABOR_MARKET` (20 rows) |
| Fact table | `RAW.ATTENDANCE_LOGS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | PHP (₱) |

Regions in play: Metro Manila, Cebu, Davao, Pampanga, Iloilo
Segments: Voice Agent, Chat Agent, Team Lead, Back Office

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh PH_BPO_WORKFORCE
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Total Headcount | `24,800` | total across Labor Market |
| Attrition Rate | `4.8%/mo` | average per event |
| Training Completion | `92%` | average per event |
| Open Positions | `847` | total across Labor Market |
| Avg Tenure | `2.4 yrs` | average per event |
| Promotion Rate | `12%` | average per event |
| Engagement Score | `4.1/5` | average per event |


## Demo flow

1. Executive Cockpit
2. Attrition Analytics
3. Retention Intelligence
4. Ask AI
5. Architecture & Data

## Talking points

- **₱420M** - annual attrition cost across 45 BPO sites
- **3 of 45 sites** - above 9% monthly attrition (CRITICAL)
- **1,247 agents** - flagged as high flight risk (>0.75 score)
- **11.2%** - monthly attrition at Cebu IT Park (highest)
- **34% lower attrition** - for agents completing training programs
- **28,000 agents** - scored weekly by ML.CLASSIFICATION

## Business impact

- Philippines BPO industry revenue reached $32.5B in 2023, employing 1.7M workers (IBPAP)
- Average BPO attrition in Philippines is 30-40% annually — highest in APAC services (Everest Group)
- Cost of replacing a BPO agent is 50-200% of annual salary including training (SHRM)
- AI-driven workforce analytics reduces attrition by 20-35% in contact centers (McKinsey Operations)

---
Generated from `generator/demo_specs/aws-philippines-bpo-workforce.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-philippines-bpo-workforce` instead.
