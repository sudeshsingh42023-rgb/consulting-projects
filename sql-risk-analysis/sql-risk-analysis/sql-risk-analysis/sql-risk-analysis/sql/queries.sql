-- ============================================================================
-- queries.sql
-- Credit & Fraud Risk analysis queries against risk_analysis.db
-- Each query answers a real business question a CFR analyst would ask.
-- ============================================================================

-- Q1. Overall fraud rate, and fraud rate by customer risk segment.
-- Tests: JOIN, GROUP BY, aggregate ratio.
SELECT
    c.risk_segment,
    COUNT(*)                                   AS total_transactions,
    SUM(t.is_fraud)                            AS fraud_transactions,
    ROUND(100.0 * SUM(t.is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.risk_segment
ORDER BY fraud_rate_pct DESC;


-- Q2. Top 5 merchant categories by fraud rate (only categories with at least
-- 50 transactions, to avoid small-sample noise).
-- Tests: JOIN, GROUP BY, HAVING.
SELECT
    m.category,
    COUNT(*)                                     AS total_transactions,
    SUM(t.is_fraud)                              AS fraud_transactions,
    ROUND(100.0 * SUM(t.is_fraud) / COUNT(*), 2)   AS fraud_rate_pct
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.category
HAVING COUNT(*) >= 50
ORDER BY fraud_rate_pct DESC
LIMIT 5;


-- Q3. Monthly fraud trend — transaction count and fraud rate per month.
-- Tests: date functions, GROUP BY, aggregate ratio.
SELECT
    strftime('%Y-%m', txn_date)                 AS txn_month,
    COUNT(*)                                     AS total_transactions,
    SUM(is_fraud)                                AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 2)     AS fraud_rate_pct
FROM transactions
GROUP BY txn_month
ORDER BY txn_month;


-- Q4. Customers whose average transaction amount is more than 3x the
-- overall average — a simple outlier-spending flag.
-- Tests: CTE, subquery, aggregate comparison.
WITH customer_avg AS (
    SELECT customer_id, AVG(amount) AS avg_amount, COUNT(*) AS txn_count
    FROM transactions
    GROUP BY customer_id
),
overall_avg AS (
    SELECT AVG(amount) AS overall_avg_amount FROM transactions
)
SELECT
    ca.customer_id,
    ca.txn_count,
    ROUND(ca.avg_amount, 2) AS customer_avg_amount,
    ROUND(oa.overall_avg_amount, 2) AS overall_avg_amount
FROM customer_avg ca, overall_avg oa
WHERE ca.avg_amount > 3 * oa.overall_avg_amount
ORDER BY ca.avg_amount DESC;


-- Q5. Running (cumulative) total of transaction amount per customer,
-- ordered by date — useful for spotting sudden spending spikes.
-- Tests: window function (SUM OVER PARTITION).
SELECT
    customer_id,
    txn_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY txn_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM transactions
WHERE customer_id = (SELECT customer_id FROM transactions GROUP BY customer_id ORDER BY COUNT(*) DESC LIMIT 1)
ORDER BY txn_date;


-- Q6. Rank customers within each risk segment by total spend, using a
-- window function — e.g. to find the top 3 spenders per segment.
-- Tests: RANK() OVER PARTITION, subquery filtering (SQLite has no QUALIFY).
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.risk_segment,
        SUM(t.amount) AS total_spend
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    GROUP BY c.customer_id, c.risk_segment
),
ranked AS (
    SELECT
        risk_segment,
        customer_id,
        ROUND(total_spend, 2) AS total_spend,
        RANK() OVER (PARTITION BY risk_segment ORDER BY total_spend DESC) AS spend_rank
    FROM customer_spend
)
SELECT *
FROM ranked
WHERE spend_rank <= 3
ORDER BY risk_segment, spend_rank;


-- Q7. Flag transactions as Low/Medium/High/Critical risk using business
-- rules (odd hour proxy via foreign+high-risk-category combo, since this
-- table doesn't store hour — combined with amount-to-limit ratio).
-- Tests: CASE WHEN, JOIN.
SELECT
    t.transaction_id,
    t.amount,
    c.credit_limit,
    ROUND(1.0 * t.amount / c.credit_limit, 4) AS amount_to_limit_ratio,
    m.category,
    CASE
        WHEN t.amount > c.credit_limit * 0.5 THEN 'Critical'
        WHEN t.amount > c.credit_limit * 0.25 AND m.category IN ('Jewelry','Online Retail','Gambling') THEN 'High'
        WHEN t.amount > c.credit_limit * 0.1 THEN 'Medium'
        ELSE 'Low'
    END AS rule_based_risk_band
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN merchants m ON t.merchant_id = m.merchant_id
ORDER BY amount_to_limit_ratio DESC
LIMIT 20;


-- Q8. Which customers transacted with foreign merchants for the first time
-- this data covers, and how many of those were flagged fraud?
-- Tests: JOIN, GROUP BY, conditional aggregation.
SELECT
    c.customer_id,
    COUNT(*) FILTER (WHERE m.country != 'IN')                    AS foreign_txns,
    COUNT(*) FILTER (WHERE m.country != 'IN' AND t.is_fraud = 1) AS foreign_fraud_txns
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY c.customer_id
HAVING foreign_txns > 0
ORDER BY foreign_fraud_txns DESC
LIMIT 15;


-- Q9. Average transaction amount comparison: fraud vs legit, by category.
-- Tests: GROUP BY multiple columns, conditional aggregation.
SELECT
    m.category,
    ROUND(AVG(CASE WHEN t.is_fraud = 1 THEN t.amount END), 2) AS avg_fraud_amount,
    ROUND(AVG(CASE WHEN t.is_fraud = 0 THEN t.amount END), 2) AS avg_legit_amount
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY avg_fraud_amount DESC;


-- Q10. Customers who signed up in the last 12 months (of the data window)
-- but already have a fraud flag — a "new account fraud" watchlist.
-- Tests: date filtering, JOIN, DISTINCT.
SELECT DISTINCT
    c.customer_id,
    c.signup_date,
    c.risk_segment
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.is_fraud = 1
  AND c.signup_date >= date('2026-01-01', '-12 months')
ORDER BY c.signup_date DESC;
