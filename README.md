# quickpay-fintech-assignment
QuickPay Fintech Data Analyst Assignment

## Student Details

| Field | Value |
|---|---|
| Student Name | Yalleni Elango
 |
| Student ID | bitsom_ftai_260187 |
| Public GitHub Repository | quickpay-fintech-assignment |

---

## Tools Used

| Task | Tool / Language |
|---|---|
| Part 1 — Data Cleaning & Business Logic | Python 3 · Pandas · openpyxl |
| Part 2 — SQL Business Analysis | SQLite via Python `sqlite3` |
| Part 3 — Reconciliation Workflow | Python 3 · Pandas |
| Part 4 — JSON Normalization | Python 3 · Pandas · `json` |
| Part 5 — Dashboard Visualization | Google Looker Studio |

---

## Key Findings

| Metric | Value |
|---|---|
| Total Transactions Analysed | 30 |
| Total GMV (USD) | $116,080.00 |
| Captured (Confirmed) GMV | $82,355.50 |
| Success Rate | 63.33% |
| Chargeback Rate | 13.33% |
| Amount at Risk | $49,984.50 |
| High Value Transactions | 7 |
| High Risk Transactions | 9 |
| Top Region (GMV) | APAC |
| Top Merchant (Captured GMV) | Beta Stores ($33,431) |
| Fraud Alert | User U008 — 4 failures/chargebacks on 2026-03-05 |

### Reconciliation Summary (Ledger vs Gateway)
| Finding | Count |
|---|---|
| Matched transactions | 5 |
| Missing in Gateway | 2 (R004, R010) |
| Missing in Ledger | 1 (R011) |
| Amount mismatches | 2 (R002, R008) |
| Status mismatches | 1 (R005) |
| Total issues | 6 of 11 unique transactions |

---

## Repository Structure

```
quickpay-fintech-assignment/
├── README.md
├── run_all.py                            
├── 01_data/
│   ├── raw/                              
│   │   ├── transactions_raw.csv
│   │   ├── merchant_master.csv
│   │   ├── users.csv
│   │   ├── ledger.csv
│   │   ├── gateway.csv
│   │   ├── exchange_rates.csv
│   │   └── api_response_sample.json
│   └── processed/                        
│       ├── cleaned_transactions.csv
│       ├── merchant_risk_summary.csv
│       ├── missing_in_gateway.csv
│       ├── missing_in_ledger.csv
│       ├── amount_mismatches.csv
│       ├── status_mismatches.csv
│       ├── reconciliation_report.csv
│       ├── api_normalized.csv
│       ├── daily_summary.csv
│       ├── payment_method_breakdown.csv
│       ├── region_breakdown.csv
│       └── merchant_performance_summary.csv
├── 02_spreadsheet/
│   ├── spreadsheet_workbook.xlsx
│   └── spreadsheet_answers.md
├── 03_sql/
│   ├── analysis_queries.sql
│   ├── run_sql_queries.py
│   └── sql_answers.md
├── 04_python/
│   ├── fintech_pipeline.ipynb
│   └── summary_metrics.json
└── 05_visualization/
    └── dashboard_link.txt
```
