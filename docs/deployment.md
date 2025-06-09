# Deployment Guide

## Quick Start Options

### Local Development
```bash
./scripts/local-setup.sh
./scripts/start-dev.sh
```

### AWS Production
```bash
./scripts/deploy-aws.sh
```

### Docker
```bash
docker-compose up -d
```

## AWS Setup

1. Copy `.env.example` to `.env` and populate all values.
   The AWS section defines region, instance type, key pair and repository URL.
2. Configure the AWS CLI using `aws configure` so the script can create
   resources.
3. Run the deployment script:

```bash
./scripts/deploy-aws.sh
```

The script provisions an EC2 instance, installs all dependencies, deploys the
smart contract via Hardhat and starts the backend, bot and frontend with PM2.
After a few minutes it prints the public IP address where the dashboard can be
reached.

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
