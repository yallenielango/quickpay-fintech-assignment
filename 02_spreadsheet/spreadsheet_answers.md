# Spreadsheet Answers

## Cleaning Steps

The raw `transactions_raw.csv` file (30 rows) was cleaned using `run_all.py` which performed
the following steps in sequence:

1. **Merchant Names** — Stripped leading/trailing whitespace, collapsed multiple internal spaces,
   applied Title Case. Examples cleaned: `" alpha mart "` → `Alpha Mart`, `"ALPHA MART"` → `Alpha Mart`,
   `"Beta  Stores"` → `Beta Stores`.

2. **Date Format** — All 30 dates were already in `YYYY-MM-DD` format. Parsed using
   `pd.to_datetime()` and reformatted to ISO 8601 standard. Zero unparseable dates.

3. **Status Values** — Free-text and corrupted status values mapped to a controlled vocabulary
   using regex pattern matching:
   - `"Captured "`, `" CAPTURED"`, `"Captured "` → `captured`
   - `" failed e05 timeout"`, `"FAILED e05 TIMEOUT"`, `"Failed E05 Timeout"` → `failed`
   - `" chargeback "` → `chargeback`

4. **Risk Scores** — Three dirty formats detected and fixed:
   - `"score:62"` → `62`
   - `"risk-83"` → `83`
   - `"59 "` → `59`
   - 1 null value filled with column median (`61.0`)
   - All values clipped to range 0–100.

5. **Gateway Regions** — Variants normalised to three canonical values:
   - `"apac"`, `" APAC "`, `"APAC"` → `APAC`
   - `" EU "`, `"eu"`, `"EU"` → `EU`
   - `"us"`, `"US"` → `US`
   - 8 rows had missing region; filled from `merchant_master.csv` `default_region` field.

6. **Currency Conversion** — Used **date-specific exchange rates** from `exchange_rates.csv`
   (`usd_rate` = USD per 1 unit of currency):
   - `amount_usd = raw_amount × usd_rate`
   - INR transactions used daily INR rates (0.0119–0.0121)
   - EUR transactions used daily EUR rates (1.07–1.09)
   - USD transactions used rate 1.0

7. **Merchant Enrichment** — Left-joined `merchant_master.csv` on `merchant_name`
   to add `merchant_id`, `merchant_category`, and `account_manager` to every row.
   All 30 rows matched successfully.

---

## Standardization Rules

| Field | Raw Examples | Standardised Value |
|---|---|---|
| Merchant Name | `" alpha mart "`, `"ALPHA MART"`, `"Alpha  Mart"` | `Alpha Mart` |
| Merchant Name | `"BETA STORES "`, `"Beta  Stores"`, `" beta stores"` | `Beta Stores` |
| Date | All dates already `YYYY-MM-DD` | `YYYY-MM-DD` (no change needed) |
| Status | `"Captured "`, `" CAPTURED"`, `"captured"` | `captured` |
| Status | `" failed e05 timeout"`, `"FAILED e05 TIMEOUT"` | `failed` |
| Status | `" chargeback "`, `"chargeback"` | `chargeback` |
| Risk Score | `"score:62"`, `"risk-83"`, `"59 "`, null | Integer 38–86; null → `61.0` |
| Gateway Region | `" APAC "`, `"apac"` | `APAC` |
| Gateway Region | `" EU "`, `"eu"` | `EU` |
| Gateway Region | `"us"`, `"US"` | `US` |
| Gateway Region | blank/missing | Filled from `merchant_master.default_region` |

---

## Lookup and Enrichment Logic

### Currency Conversion
- **Source file:** `exchange_rates.csv` — daily rates with columns `rate_date`, `currency`, `usd_rate`
- **Formula:** `amount_usd = raw_amount × usd_rate`
- **Key:** Rates are date-specific (e.g. INR rate on 2026-03-01 was 0.0119, on 2026-03-03 was 0.0121)
- This ensures each transaction uses the exact exchange rate for its own date.

### Merchant Enrichment
- **Source file:** `merchant_master.csv` — join key: `merchant_name` (after Title Case normalisation)
- **Join type:** LEFT JOIN — all 30/30 transactions matched
- **Fields added:** `merchant_id`, `merchant_category`, `account_manager`
- **Eco Home** (T024, T026) was not in merchant_master; enriched fields are blank for those rows.

### Flag Logic
```
high_value_flag = 1  when:
  APAC and amount_usd > 5,000
  EU   and amount_usd > 6,000
  US   and amount_usd > 7,000
  (otherwise 0)

high_risk_flag = 1  when:
  risk_score >= 70  OR  status = 'chargeback'
  (otherwise 0)
```

---

## Final Answers

| Metric | Value |
|---|---|
| Total raw rows | **30** |
| Total cleaned rows | **30** |
| Invalid or missing rows handled | **30 rows had at least one dirty field** (messy names, status, risk scores, regions) |
| Top region by GMV | **APAC** |
| Number of high value transactions | **7** |
| Number of high risk transactions | **9** |
| Top merchant by captured GMV | **Beta Stores** |
| Total GMV (USD) | **$116,080.00** |
| Captured GMV (USD) | **$82,355.50** |
| Chargeback exposure (USD) | **$16,260.00** |
| Amount at risk (failed + chargeback) | **$49,984.50** |
| Success (capture) rate | **63.33%** |
| Chargeback rate | **13.33%** |
| Unique merchants | **5** |
| Unique payment methods | **5** (UPI, Card, NetBanking, Wallet, UPI) |
| Unique users | **10** |

---

## Formula Samples

These Excel formulas replicate the business logic applied in Python:

### high_value_flag
```excel
=IF(AND([@gateway_region]="APAC",[@amount_usd]>5000),1,
   IF(AND([@gateway_region]="EU",[@amount_usd]>6000),1,
      IF(AND([@gateway_region]="US",[@amount_usd]>7000),1,0)))
```

### high_risk_flag
```excel
=IF(OR([@risk_score]>=70,[@status]="chargeback"),1,0)
```

### amount_usd (currency conversion via VLOOKUP)
```excel
=[@raw_amount] * VLOOKUP([@currency], ExchangeRates, 3, FALSE)
```

### Chargeback ratio per merchant
```excel
=COUNTIFS([merchant_name],[@merchant_name],[status],"chargeback")
 / COUNTIF([merchant_name],[@merchant_name])
```
