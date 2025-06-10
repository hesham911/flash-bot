#!/usr/bin/env python3
"""Weekly model retraining helper."""
from ai.trainer import ArbitrageAITrainer


def main() -> None:
    trainer = ArbitrageAITrainer()
    if trainer.train_model():
        trainer.save_model()
        print("✅ Model retrained")
    else:
        print("❌ Training failed")


if __name__ == "__main__":
    main()
