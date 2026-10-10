# Philippines BPO Workforce Operations

**Philippines - BPO Contact Centre Workforce**
Use case: Staffing gaps against forecast, client service levels, QA calibration and compliance training

> Workforce monitoring for 40 agent teams of a fictional Philippine BPO in 5 cities: dynamic tables, a holdout-evaluated staffing-gap classifier, a workforce-event forecast and grounded AI answers. Team-level aggregates only; no agent-level records.

## Why Snowflake

- **Dynamic tables** reconcile contacts handled, workforce events, staffing-gap events, client SLA breaches and QA calibration compliance from RAW team data, with checks in `run_core.py`
- **Staffing-gap classification** gives a holdout-evaluated next-7-day probability per team
- **Workforce-event forecast** projects 14 days of company-wide event volume with prediction intervals, for real-time workforce planning
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live staffing**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.TEAMS` (40 rows) |
| Fact table | `RAW.TEAM_DAILY` (3,600 team-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `EVENT_TYPE_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.GAP_RISK_SCORES`, `ML.GAP_RISK_HOLDOUT_METRICS`, `ML.EVENT_FORECAST`, `ML.ABSENCE_ANOMALIES` |

Cities: Makati City, Cebu City, Davao City, Iloilo City, Bacolod City (PHP).
Lines of business: Voice customer care, Technical support, Collections, Back-office processing, Overnight chat support.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Event-Free Contact Rate | 99.98% |
| Workforce Events Logged | 591 |
| Staffing-Gap Events | 204 |
| Event Gap Rate | 34.5% |
| Client SLA Breaches | 85 |
| Labour Cost (PHP M) | 182 |
| Contacts Handled | 2,963,275 |
| QA Calibration Compliance | 69.5% |
| Teams Monitored | 40 |
| Training Coverage | 57.3% |
| Certifications Pending | 25 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily workforce events against staffing-gap events, events and gaps by event type, team table
2. Predictive: holdout metrics, risk bands, 14-day workforce-event forecast, unplanned absence anomalies
3. Quality & Training: QA calibration compliance, training coverage and pending certifications, QA compliance against staffing gaps, then generate the action memo
4. Live Staffing: run `CALL APP.SIMULATE_STAFFING_EVENTS(20)` (Snowflake only) or `python aws/publish_staffing_events.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_GAP_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.98% of contacts are untouched by a workforce event; the 591 events are where real-time workforce time goes, and 34.5% of them leave a team understaffed against forecast.
- Unplanned absence surges produce the most staffing-gap events (54 of 144). Typhoon site closures hit every team in a city at once and are always absorbed by moving queues to other sites.
- The risk model is evaluated on a time-based holdout: precision 0.42 and recall 0.22 at 0.5, against a 0.253 base rate. Present it as triage, not a verdict.
- Typhoon site closures are excluded from model training, because they are not team-driven.
- The data is team-level only: the demo never scores or names individual agents.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
