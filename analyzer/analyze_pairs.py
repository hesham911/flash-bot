#!/usr/bin/env python3
"""Analyze token pairs across DEXes.

Fetches liquidity and volume data from Uniswap and SushiSwap GraphQL APIs,
filters the highest liquidity pairs and saves the result to
``data/top_pairs.json``. Intended to run manually or via cron.
"""

from __future__ import annotations

import json
import os
from datetime import datetime
from typing import List, Dict

import requests

UNISWAP_URL = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3"
SUSHISWAP_URL = "https://api.thegraph.com/subgraphs/name/sushiswap/exchange"

QUERY = """
{
  pairs(first: 100, orderBy: reserveUSD, orderDirection: desc) {
    id
    token0 { symbol }
    token1 { symbol }
    reserveUSD
    volumeUSD
  }
}
"""

def _fetch_pairs(url: str) -> List[Dict[str, str]]:
    """Return pairs from The Graph API."""
    resp = requests.post(url, json={"query": QUERY}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    return data.get("data", {}).get("pairs", [])

def analyze(limit: int = 10, min_liquidity: float = 1_000_000, min_volume: float = 1_000_000) -> List[Dict[str, float]]:
    """Fetch and filter pairs from both DEXes."""
    sources = [("uniswap", UNISWAP_URL), ("sushiswap", SUSHISWAP_URL)]
    pairs = []
    for name, url in sources:
        try:
            for p in _fetch_pairs(url):
                liquidity = float(p.get("reserveUSD", 0))
                volume = float(p.get("volumeUSD", 0))
                if liquidity >= min_liquidity and volume >= min_volume:
                    pairs.append({
                        "source": name,
                        "pair": f"{p['token0']['symbol']}/{p['token1']['symbol']}",
                        "liquidity": liquidity,
                        "volume": volume,
                    })
        except Exception as exc:  # noqa: BLE001
            print(f"Error fetching from {name}: {exc}")

    pairs.sort(key=lambda x: x["volume"], reverse=True)
    return pairs[:limit]

def save_results(pairs: List[Dict[str, float]], path: str) -> None:
    """Write results to JSON file."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    payload = {"updated": datetime.utcnow().isoformat(), "pairs": pairs}
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)


def main() -> None:
    results = analyze()
    save_results(results, os.path.join(os.path.dirname(__file__), "..", "data", "top_pairs.json"))
    print(f"Saved {len(results)} pairs to data/top_pairs.json")


if __name__ == "__main__":
    main()
