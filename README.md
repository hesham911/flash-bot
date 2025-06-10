# 🚀 FlashLoan Arbitrage Intelligence System

A complete automated flashloan-based arbitrage bot with AI integration, web dashboard, and comprehensive monitoring.

## 🏗️ Architecture Overview

```
flashloan-bot/
├── ai/                     # AI model and training scripts
├── backend/               # Express API server
├── bot/                   # Core arbitrage logic
├── contract/              # Smart contracts
├── frontend/              # React dashboard
├── data/                  # SQLite databases
├── logs/                  # Application logs
├── scripts/               # Deployment scripts
└── docs/                  # Documentation
```

## 🚀 Quick Start

### Local Development
```bash
# Setup and start development environment
./scripts/local-setup.sh
./start-dev.sh
```

### AWS Production Deployment
```bash
# One-command AWS deployment
./scripts/quick-deploy.sh --domain yourdomain.com --email admin@yourdomain.com
```

### Docker Deployment
```bash
# Local testing
docker-compose up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

## 🧪 Testing Modes

1. **Training Mode** (Zero Risk): `TRAINING_MODE=true`
2. **Simulation Mode**: Paper trading with backtesting
3. **Small Live Mode**: Real trades with $100-1000 amounts
4. **Production Mode**: Full operation after validation

## 📊 Expected Performance

- **Training**: 15-30% success rate, $0.50+ avg profit
- **Production**: $20-100 daily profit potential
- **Cost**: ~$40-50/month AWS hosting

## 🛡️ Security Features

- Training mode for risk-free testing
- Emergency stop mechanisms
- Comprehensive monitoring
- Gradual scaling approach

## 📚 Documentation

- [Deployment Guide](docs/deployment.md)
- [Configuration Guide](docs/configuration.md)
- [API Documentation](docs/api.md)
- [Trading Strategies](docs/strategies.md)

## 🔍 Pair Liquidity Analysis

Use the analysis script to record pairs with strong liquidity and volume.

```bash
python3 analyzer/analyze_pairs.py
```

Schedule it hourly with cron:

```cron
0 * * * * /usr/bin/python3 /path/to/flash-bot/analyzer/analyze_pairs.py
```

Generate a profitability ranking using logged trades:

```bash
python3 analyzer/rank_pairs.py
```

### Weekly AI Retraining

Schedule the training script to run once per week to keep the model up to date:

```cron
0 3 * * 1 /usr/bin/python3 /path/to/flash-bot/train_model.py >> logs/train.log 2>&1
```

## 🎯 Success Metrics

Ready for production when:
- ✅ 48+ hours stable training
- ✅ 15%+ success rate
- ✅ 75%+ AI accuracy
- ✅ All monitoring active

## 📞 Support

- Check logs: `pm2 logs` or `./status.sh`
- Review documentation in `/docs`
- Test in training mode first
- Monitor Telegram alerts

---

**⚠️ Important**: Always test thoroughly in training mode before using real funds.
