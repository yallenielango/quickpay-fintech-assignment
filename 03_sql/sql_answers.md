# SQL Answers

> Queries executed against `cleaned_transactions.csv` loaded into an in-memory SQLite database.  
> Table: `cleaned_transactions` (30 rows, 16 columns)  
> Engine: `run_sql_queries.py` → `sqlite3`

---

## Q1

### Query
```sql
SELECT status,
       COUNT(*) AS transaction_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cleaned_transactions), 2) AS percentage
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;
```

### Result Summary
| status | transaction_count | percentage |
|---|---|---|
| captured | 19 | 63.33 |
| failed | 7 | 23.33 |
| chargeback | 4 | 13.33 |

**Interpretation:** Nearly two-thirds of all transactions (63.33%) were successfully captured.
7 transactions (23.33%) failed — likely due to gateway timeouts (E05 errors seen in raw data).
4 transactions (13.33%) resulted in chargebacks, indicating disputed payments requiring investigation.

---

## Q2

### Query
```sql
SELECT merchant_name,
       COUNT(*) AS total_transactions,
       ROUND(SUM(amount_usd), 2) AS captured_gmv_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name
ORDER BY captured_gmv_usd DESC;
```

### Result Summary
| merchant_name | total_transactions | captured_gmv_usd |
|---|---|---|
| Beta Stores | 7 | 33,431.00 |
| Alpha Mart | 8 | 29,984.50 |
| Delta Travels | 2 | 10,300.00 |
| City Pharma | 2 | 8,640.00 |

**Interpretation:** Beta Stores led in captured GMV at $33,431 despite having fewer
transactions than Alpha Mart, indicating higher average transaction values.

---

## Q3

### Query
```sql
SELECT merchant_name,
       COUNT(*) AS total_captured_txns,
       ROUND(SUM(amount_usd), 2) AS captured_gmv_usd,
       ROUND(AVG(amount_usd), 2) AS avg_transaction_usd
FROM cleaned_transactions
WHERE status = 'captured'
GROUP BY merchant_name
ORDER BY captured_gmv_usd DESC
LIMIT 10;
```

### Result Summary
| merchant_name | total_captured_txns | captured_gmv_usd | avg_transaction_usd |
|---|---|---|---|
| Beta Stores | 7 | 33,431.00 | 4,775.86 |
| Alpha Mart | 8 | 29,984.50 | 3,748.06 |
| Delta Travels | 2 | 10,300.00 | 5,150.00 |
| City Pharma | 2 | 8,640.00 | 4,320.00 |

**Interpretation:** The dataset has 4 merchants with captured transactions. All 4 appear in
the top 10 (no other merchants had captures). Delta Travels has the highest average transaction
value at $5,150 per captured transaction.

---

## Q4

### Query
```sql
SELECT transaction_date AS date,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN status='captured' THEN 1 ELSE 0 END) AS successful_transactions,
       ROUND(SUM(CASE WHEN status='captured' THEN amount_usd ELSE 0 END), 2) AS daily_captured_gmv_usd,
       ROUND(SUM(amount_usd), 2) AS daily_total_gmv_usd
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date ASC;
```

### Result Summary
| date | total_txns | successful_txns | daily_captured_gmv | daily_total_gmv |
|---|---|---|---|---|
| 2026-03-01 | 5 | 5 | 26,382.00 | 26,382.00 |
| 2026-03-02 | 6 | 3 | 11,080.00 | 25,049.00 |
| 2026-03-03 | 5 | 4 | 16,031.50 | 18,391.00 |
| 2026-03-04 | 5 | 4 | 13,920.00 | 16,420.00 |
| 2026-03-05 | 6 | 1 | 6,136.00 | 19,232.00 |
| 2026-03-06 | 3 | 2 | 8,806.00 | 10,606.00 |

**Interpretation:** 2026-03-01 was the strongest day — 100% success rate and $26,382 in captured GMV.
2026-03-05 was the worst — only 1 out of 6 transactions captured ($6,136), with 4 failures/chargebacks
all attributed to user U008 (flagged in Q7).

---

## Q5

### Query
```sql
SELECT merchant_name,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN status='chargeback' THEN 1 ELSE 0 END) AS chargeback_count,
       ROUND(100.0 * SUM(CASE WHEN status='chargeback' THEN 1 ELSE 0 END) / COUNT(*), 2) AS chargeback_ratio_pct,
       ROUND(SUM(CASE WHEN status='chargeback' THEN amount_usd ELSE 0 END), 2) AS chargeback_amount_usd
FROM cleaned_transactions
GROUP BY merchant_name
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;
```

### Result Summary
| merchant_name | total_transactions | chargeback_count | chargeback_ratio_pct | chargeback_amount_usd |
|---|---|---|---|---|
| Eco Home | 2 | 1 | 50.00 | 6,649.00 |
| Delta Travels | 4 | 1 | 25.00 | 2,500.00 |
| Beta Stores | 11 | 1 | 9.09 | 1,711.00 |
| Alpha Mart | 11 | 1 | 9.09 | 5,400.00 |

**Interpretation:** All 4 merchants exceed the 1% threshold — this is an unusually high
chargeback environment. Eco Home is the most alarming at 50% (1 chargeback in 2 total transactions).
This dataset covers only 6 days, so volumes are low and ratios are sensitive.

---

## Q6

### Query
```sql
SELECT gateway_region,
       COUNT(*) AS transaction_count,
       ROUND(AVG(risk_score), 2) AS avg_risk_score,
       MAX(risk_score) AS max_risk_score,
       SUM(CASE WHEN high_risk_flag=1 THEN 1 ELSE 0 END) AS high_risk_transaction_count
FROM cleaned_transactions
GROUP BY gateway_region
HAVING AVG(risk_score) > 50 AND COUNT(*) > 20
ORDER BY avg_risk_score DESC;
```

### Result Summary
| gateway_region | transaction_count | avg_risk_score | max_risk_score | high_risk_txn_count |
|---|---|---|---|---|
| APAC | 22 | 65.27 | 86.0 | 7 |

**Interpretation:** Only APAC meets both criteria (avg risk > 50 AND > 20 transactions).
With an average risk score of 65.27 and a maximum of 86, APAC is the highest-risk region
and accounts for 7 of the 9 total high-risk transactions.

---

## Q7

### Query
```sql
SELECT user_id, transaction_date,
       COUNT(*) AS failed_or_chargeback_count,
       GROUP_CONCAT(DISTINCT status) AS statuses_seen
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY failed_or_chargeback_count DESC;
```

### Result Summary
| user_id | transaction_date | failed_or_chargeback_count | statuses_seen |
|---|---|---|---|
| U008 | 2026-03-05 | 4 | failed, chargeback |

**Interpretation:** User U008 had 4 failed/chargeback transactions in a single day (2026-03-05).
This is a strong fraud signal. U008 accounts for T016, T017, T018, and T019 — spanning
Beta Stores and Alpha Mart. Immediate account review and temporary suspension is recommended.

---

## Q8

### Query
```sql
SELECT merchant_name,
       COUNT(*) AS chargeback_count,
       COUNT(DISTINCT user_id) AS unique_affected_users,
       ROUND(SUM(amount_usd), 2) AS total_chargeback_amount_usd,
       ROUND(AVG(amount_usd), 2) AS avg_chargeback_amount_usd
FROM cleaned_transactions
WHERE status = 'chargeback'
GROUP BY merchant_name
ORDER BY chargeback_count DESC;
```

### Result Summary
| merchant_name | chargeback_count | unique_affected_users | total_chargeback_usd | avg_chargeback_usd |
|---|---|---|---|---|
| Eco Home | 1 | 1 | 6,649.00 | 6,649.00 |
| Delta Travels | 1 | 1 | 2,500.00 | 2,500.00 |
| Beta Stores | 1 | 1 | 1,711.00 | 1,711.00 |
| Alpha Mart | 1 | 1 | 5,400.00 | 5,400.00 |

**Interpretation:** Each merchant has exactly 1 chargeback from 1 unique user.
Eco Home has the highest single chargeback value at $6,649. Total chargeback exposure
across all merchants is $16,260. Each chargeback affects a different user, suggesting
isolated incidents rather than a coordinated attack — except U008 who appears in the
Beta Stores and Alpha Mart chargebacks (T018, T007/T029).
