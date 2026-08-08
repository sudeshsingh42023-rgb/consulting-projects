"""
build_database.py
-------------------
Creates a small SQLite database (risk_analysis.db) with 3 tables —
customers, merchants, transactions — using synthetic but realistic data.

Run this first. It takes a few seconds and needs nothing but pandas/numpy,
which come with any standard Python data-science setup.
"""
import sqlite3
import numpy as np
import pandas as pd
from datetime import datetime, timedelta

rng = np.random.default_rng(7)

N_CUSTOMERS = 300
N_MERCHANTS = 60
N_TRANSACTIONS = 6000

# ---- customers ----
customers = pd.DataFrame({
    "customer_id": [f"C{1000+i}" for i in range(N_CUSTOMERS)],
    "signup_date": [
        (datetime(2019, 1, 1) + timedelta(days=int(d))).date().isoformat()
        for d in rng.integers(0, 2200, N_CUSTOMERS)
    ],
    "credit_limit": rng.choice([50000, 100000, 200000, 300000, 500000], N_CUSTOMERS),
    "risk_segment": rng.choice(["Low", "Medium", "High"], N_CUSTOMERS, p=[0.6, 0.3, 0.1]),
})

# ---- merchants ----
categories = ["Grocery", "Electronics", "Travel", "Dining", "Fuel",
              "Online Retail", "Jewelry", "Utilities", "Entertainment", "Gambling"]
merchants = pd.DataFrame({
    "merchant_id": [f"M{200+i}" for i in range(N_MERCHANTS)],
    "category": rng.choice(categories, N_MERCHANTS),
    "country": rng.choice(["IN", "US", "AE", "SG", "UK"], N_MERCHANTS, p=[0.6, 0.2, 0.1, 0.05, 0.05]),
})

# ---- transactions ----
high_risk_cats = {"Jewelry", "Online Retail", "Gambling", "Electronics"}
n_fraud = int(N_TRANSACTIONS * 0.02)
n_legit = N_TRANSACTIONS - n_fraud

def make_txns(n, fraud):
    cust_idx = rng.integers(0, N_CUSTOMERS, n)
    mer_idx = rng.integers(0, N_MERCHANTS, n)
    dates = [
        (datetime(2026, 1, 1) + timedelta(days=int(d))).date().isoformat()
        for d in rng.integers(0, 180, n)
    ]
    amounts = np.round(rng.gamma(3, 8000, n) if fraud else rng.gamma(2, 1400, n), 2)
    if fraud:
        for i in range(n):
            if rng.random() < 0.6:
                cat = rng.choice(list(high_risk_cats))
                candidates = np.where(merchants["category"] == cat)[0]
                if len(candidates):
                    mer_idx[i] = rng.choice(candidates)
    return pd.DataFrame({
        "transaction_id": [f"T{rng.integers(10**8, 10**9-1)}" for _ in range(n)],
        "customer_id": [customers['customer_id'][i] for i in cust_idx],
        "merchant_id": [merchants['merchant_id'][i] for i in mer_idx],
        "txn_date": dates,
        "amount": amounts,
        "is_fraud": int(fraud),
    })

transactions = pd.concat([make_txns(n_fraud, True), make_txns(n_legit, False)], ignore_index=True)
transactions = transactions.sample(frac=1, random_state=7).reset_index(drop=True)

# ---- write to SQLite ----
conn = sqlite3.connect("risk_analysis.db")
customers.to_sql("customers", conn, if_exists="replace", index=False)
merchants.to_sql("merchants", conn, if_exists="replace", index=False)
transactions.to_sql("transactions", conn, if_exists="replace", index=False)
conn.close()

print(f"Built risk_analysis.db with {len(customers)} customers, "
      f"{len(merchants)} merchants, {len(transactions)} transactions "
      f"({n_fraud} fraud / {n_legit} legit).")
