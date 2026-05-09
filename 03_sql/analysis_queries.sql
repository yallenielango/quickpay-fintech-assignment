-- ===================================================================
--  QuickPay Fintech Assignment — Part 2: SQL Business Analysis
--  File  : 03_sql/analysis_queries.sql
--  Table : cleaned_transactions  (from 01_data/processed/cleaned_transactions.csv)
--  Run   : python run_sql_queries.py   OR   any SQLite / PostgreSQL client
-- ===================================================================

-- Q1
-- Count transactions by status
-- Gives an overall picture of the payment pipeline health
SELECT
    status,
    COUNT(*) AS transaction_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cleaned_transactions), 2) AS percentage
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- Q2
-- Calculate total captured GMV by merchant
-- GMV = Gross Merchandise Value; we only count 'captured' (settled) transactions
SELECT
    merchant_name,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount_usd), 2) AS captured_gmv_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name
ORDER BY captured_gmv_usd DESC;

-- Q3
-- Top 10 merchants by captured GMV
-- Same as Q2 but limited to 10 and includes average transaction size
SELECT
    merchant_name,
    COUNT(*) AS total_captured_txns,
    ROUND(SUM(amount_usd), 2) AS captured_gmv_usd,
    ROUND(AVG(amount_usd), 2) AS avg_transaction_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name
ORDER BY captured_gmv_usd DESC
LIMIT 10;

-- Q4
-- Daily GMV and successful transaction count
-- Useful for spotting trends, peak days, or sudden drops
SELECT
    transaction_date AS date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'captured' THEN 1 ELSE 0 END) AS successful_transactions,
    ROUND(SUM(CASE WHEN status = 'captured' THEN amount_usd ELSE 0 END), 2) AS daily_captured_gmv_usd,
    ROUND(SUM(amount_usd), 2) AS daily_total_gmv_usd
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date ASC;

-- Q5
-- Merchants with chargeback ratio above 1%
-- Chargeback ratio = number of chargebacks / total transactions × 100
SELECT
    merchant_name,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END) AS chargeback_count,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'chargeback' THEN 1 ELSE 0 END) / COUNT(*),
    2) AS chargeback_ratio_pct,
    ROUND(SUM(CASE WHEN status = 'chargeback' THEN amount_usd ELSE 0 END), 2) AS chargeback_amount_usd
FROM cleaned_transactions
GROUP BY merchant_name
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;

-- Q6
-- Regions with average risk score above 50 and more than 20 transactions
-- Identifies high-risk geographic areas requiring closer monitoring
SELECT
    gateway_region,
    COUNT(*) AS transaction_count,
    ROUND(AVG(risk_score), 2) AS avg_risk_score,
    MAX(risk_score) AS max_risk_score,
    SUM(CASE WHEN high_risk_flag = 1 THEN 1 ELSE 0 END) AS high_risk_transaction_count
FROM cleaned_transactions
GROUP BY gateway_region
HAVING AVG(risk_score) > 50
   AND COUNT(*) > 20
ORDER BY avg_risk_score DESC;

-- Q7
-- Users with 3 or more failed or chargeback transactions on the same day
-- Strong indicator of fraudulent activity or account compromise
SELECT
    user_id,
    transaction_date,
    COUNT(*) AS failed_or_chargeback_count,
    GROUP_CONCAT(DISTINCT status) AS statuses_seen
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY failed_or_chargeback_count DESC;

-- Q8
-- Chargeback count, unique affected users, and chargeback amount by merchant
-- Key merchant-level chargeback exposure report for risk team
SELECT
    merchant_name,
    COUNT(*) AS chargeback_count,
    COUNT(DISTINCT user_id) AS unique_affected_users,
    ROUND(SUM(amount_usd), 2) AS total_chargeback_amount_usd,
    ROUND(AVG(amount_usd), 2) AS avg_chargeback_amount_usd
FROM cleaned_transactions
WHERE status = 'chargeback'
GROUP BY merchant_name
ORDER BY chargeback_count DESC;
