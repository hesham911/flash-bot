#!/usr/bin/env python3
"""Rank token pairs by profitability using trade logs."""
import os
import sqlite3
import pandas as pd
from pathlib import Path

DB_PATH = os.environ.get(
    "DATABASE_PATH",
    str(Path(__file__).resolve().parent.parent / "data" / "arbitrage.db"),
)


def main() -> None:
    if not os.path.exists(DB_PATH):
        print("Database not found")
        return
    conn = sqlite3.connect(DB_PATH)
    df = pd.read_sql_query(
        "SELECT token_pair, profit_usd, status FROM arbitrage_logs", conn
    )
    conn.close()
    if df.empty:
        print("No trade data")
        return

    summary = (
        df.groupby("token_pair")
        .agg(
            trades=("token_pair", "count"),
            successes=("status", lambda x: (x == "success").sum()),
            profit=("profit_usd", "sum"),
        )
        .reset_index()
    )
    summary["success_rate"] = summary["successes"] / summary["trades"]
    summary.sort_values("profit", ascending=False, inplace=True)

    out_path = Path(DB_PATH).resolve().parent / "pair_ranking.csv"
    summary.to_csv(out_path, index=False)
    print(f"Ranking saved to {out_path}")


if __name__ == "__main__":
    main()
