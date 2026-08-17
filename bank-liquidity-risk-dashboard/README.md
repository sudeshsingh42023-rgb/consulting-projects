Bank Liquidity Risk Dashboard — LCR & NSFR Simulation
What this project does

This project simulates two core Basel III liquidity risk ratios — the Liquidity Coverage Ratio (LCR) and Net Stable Funding Ratio (NSFR) — using a synthetic bank balance sheet, SQL, and regulatory factor tables.

LCR answers: can the bank survive 30 days of severe financial stress using only its high-quality liquid assets (HQLA)? A bank is compliant if LCR ≥ 100%.
NSFR answers: does the bank have enough stable funding sources to support its assets over a 1-year horizon? A bank is compliant if NSFR ≥ 100%.
How it was built
Created a mock bank balance sheet in Excel — separate asset and liability line items, each tagged with a category (Cash, Govt Bonds, Retail Loans, Retail Deposits, etc.) and maturity bucket.
Built a regulatory factor lookup table with Basel III haircut percentages (for LCR/HQLA), run-off percentages (for LCR/outflows), and ASF/RSF percentages (for NSFR), sourced from published Basel III guidance.
Loaded all data into SQLite (via DB Browser for SQLite) as three tables: assets, liabilities, bucket_rules.
Wrote SQL queries joining balance sheet data to the factor table to compute:
Total HQLA (haircut-adjusted eligible assets)
Net Cash Outflows over 30 days (run-off-adjusted short-term liabilities)
LCR = HQLA ÷ Net Cash Outflows × 100
Total ASF (stable-funding-adjusted liabilities)
Total RSF (stable-funding-adjusted assets)
NSFR = ASF ÷ RSF × 100
A breach flag for each ratio (BREACH if <100%, else OK)
Results
Metric	Value	Status
LCR	260%	OK (compliant)
NSFR	331.5%	OK (compliant)

Both ratios are comfortably above the 100% regulatory minimum, indicating the simulated bank holds more liquid assets and stable funding than required under these mock conditions.

Important note

This is a self-built simulation using synthetic balance sheet data and self-sourced Basel III methodology, built to demonstrate SQL-based liquidity risk calculation logic. It does not use real bank data and was not built using Oracle OFSAA or any commercial ALM/LRM software — it replicates the underlying regulatory calculation logic using SQL and Excel.

Tools used

SQLite (DB Browser for SQLite), SQL (joins, aggregation, CASE logic), Excel (data preparation), Basel III LCR/NSFR regulatory framework.
