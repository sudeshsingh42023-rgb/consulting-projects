# SQL Credit & Fraud Risk Analysis

A self-contained SQL case study: 10 real business questions a Credit & Fraud
Risk analyst would ask, answered with actual SQL against a synthetic
transactions database (SQLite). Built to directly demonstrate SQL skills
with evidence, not just list SQL as a skill on a resume.

> **Data note:** All data is synthetically generated (`build_database.py`)
> with a fraud pattern deliberately injected, so this is safe to publish
> publicly — no real financial data involved.

## Why this project

SQL is listed as a core tool in Amex's Credit & Fraud Risk apprenticeship
JD, and it's one place I didn't have concrete proof of hands-on use. This
project is that proof: 10 queries, run against a real (if synthetic)
database, with real results in `results.md`.

## Structure
## Run it yourself

```bash
pip install pandas numpy tabulate
python build_database.py
python run_queries.py
```

Takes under a minute end to end.

## The 10 questions answered

1. What's the overall fraud rate, and does it differ by customer risk segment?
2. Which merchant categories have the highest fraud rate?
3. How does the fraud rate trend month over month?
4. Which customers have unusually high average spend vs. the base rate? *(outlier detection)*
5. What does a customer's cumulative spend look like over time? *(window function: running total)*
6. Who are the top 3 spenders within each risk segment? *(window function: RANK)*
7. Can transactions be flagged into risk bands using simple business rules? *(CASE WHEN)*
8. Which customers transact with foreign merchants, and how much of that is fraud-flagged?
9. Do fraud transactions skew toward higher amounts than legit ones, by category?
10. Which recently-onboarded customers already have a fraud flag? *(new-account fraud watchlist)*

## Key findings (from `results.md`, actual run output)

- **Fraud rate is highest in the "Low" customer risk segment (2.13%)** —
  counterintuitive at first glance, but explained by segment size: Low-risk
  customers make up the majority of transaction volume, so even a small
  fraud rate produces more absolute fraud cases there than in the smaller
  High-risk segment.
- **Jewelry has the highest per-category fraud rate at 7.55%**, more than
  double the next-highest category (Gambling, 4.24%) — consistent with
  high-value, high-resale-value goods being an attractive fraud target.
- **Fraud transactions average 7–10x the size of legit transactions**
  across every category (e.g. Fuel: ₹31,390 avg fraud vs ₹2,742 avg legit) —
  amount is a strong standalone fraud signal in this data.
- The **outlier-spend query (Q4) returned zero customers**, i.e. no customer's
  average spend exceeded 3x the base rate — a legitimate negative result,
  included here rather than dropped, since real analysis sometimes finds
  no outliers.

## Tech used

SQL (SQLite) — joins, CTEs, window functions (`RANK() OVER`, running
totals), `CASE WHEN` business-rule logic, conditional aggregation, date
functions · Python (pandas) for orchestration and result export.
