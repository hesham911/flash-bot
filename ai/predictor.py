#!/usr/bin/env python3
"""Predict expected profit using trained arbitrage model"""
import os
import sys
import joblib

MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'arbitrage_model.joblib')

def main():
    try:
        amount = float(sys.argv[1])
        slippage = float(sys.argv[2])
        gas_price = float(sys.argv[3])
        volatility = float(sys.argv[4])
    except (IndexError, ValueError):
        print(0)
        return

    if not os.path.exists(MODEL_PATH):
        print(0)
        return

    try:
        model = joblib.load(MODEL_PATH)
        prediction = model.predict([[amount, slippage, gas_price, volatility]])[0]
        print(float(prediction))
    except Exception:
        print(0)

if __name__ == '__main__':
    main()
