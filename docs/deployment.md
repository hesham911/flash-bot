# Deployment Guide

## Quick Start Options

### Local Development
```bash
./scripts/local-setup.sh
./scripts/start-dev.sh
```

### AWS Production
```bash
./scripts/deploy-aws.sh --domain yourdomain.com
```

### Docker
```bash
docker-compose up -d
```

## Configuration

Edit `.env` file with your settings:
- Wallet private key
- API keys (1inch, Telegram)
- Domain and email

## Testing

Always start in training mode:
```bash
TRAINING_MODE=true
```

Run for 48+ hours to collect data before production.
