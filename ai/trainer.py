#!/usr/bin/env python3
"""
FlashLoan Arbitrage AI Trainer
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
import joblib
import sqlite3
import os
from datetime import datetime

class ArbitrageAITrainer:
    def __init__(self, db_path='../data/arbitrage.db'):
        self.db_path = db_path
        self.model = None

    def load_data(self):
        """Load training data from database"""
        if not os.path.exists(self.db_path):
            print("Database not found, creating sample data...")
            return self.create_sample_data()

        conn = sqlite3.connect(self.db_path)
        query = "SELECT * FROM ai_training_data ORDER BY timestamp DESC LIMIT 1000"
        df = pd.read_sql_query(query, conn)
        conn.close()

        return df

    def create_sample_data(self):
        """Create sample data for demonstration"""
        np.random.seed(42)
        n_samples = 100

        data = {
            'amount': np.random.uniform(1000, 10000, n_samples),
            'slippage': np.random.uniform(0.1, 1.0, n_samples),
            'gas_price': np.random.uniform(20, 100, n_samples),
            'volatility': np.random.uniform(0.5, 3.0, n_samples),
            'profit': np.random.uniform(-50, 200, n_samples)
        }

        return pd.DataFrame(data)

    def train_model(self):
        """Train the arbitrage prediction model"""
        print("Loading training data...")
        df = self.load_data()

        if df.empty:
            print("No training data available")
            return False

        # Prepare features
        feature_columns = ['amount', 'slippage', 'gas_price', 'volatility']
        available_features = [col for col in feature_columns if col in df.columns]

        if not available_features:
            print("No suitable features found")
            return False

        X = df[available_features]
        y = df['profit'] if 'profit' in df.columns else df.iloc[:, -1]

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # Train model
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.model.fit(X_train, y_train)

        # Evaluate
        train_score = self.model.score(X_train, y_train)
        test_score = self.model.score(X_test, y_test)

        print(f"Training completed!")
        print(f"Train R²: {train_score:.4f}")
        print(f"Test R²: {test_score:.4f}")

        return True

    def save_model(self, path='models/arbitrage_model.joblib'):
        """Save trained model"""
        os.makedirs(os.path.dirname(path), exist_ok=True)
        joblib.dump(self.model, path)
        print(f"Model saved to {path}")

    def predict(self, features):
        """Make prediction"""
        if self.model is None:
            print("Model not trained")
            return 0

        return self.model.predict([features])[0]

def main():
    trainer = ArbitrageAITrainer()

    if trainer.train_model():
        trainer.save_model()
        print("✅ AI model training completed!")
    else:
        print("❌ Training failed!")

if __name__ == "__main__":
    main()
