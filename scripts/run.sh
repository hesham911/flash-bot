#!/bin/bash
# Full setup and start script for FlashLoan Bot
set -e

GREEN='\033[0;32m'
NC='\033[0m'
log(){ echo -e "${GREEN}[INFO]${NC} $1"; }

# Clone repository if not present
REPO_URL="${REPO_URL:-https://github.com/your-org/flash-bot.git}"
BRANCH="${BRANCH:-main}"
TARGET_DIR="flash-bot"

if [ ! -d "$TARGET_DIR" ]; then
  log "\ud83d\udce5 Cloning repository from $REPO_URL"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

git checkout "$BRANCH"

# Setup environment variables
if [ ! -f .env ]; then
  cp .env.example .env
  log "\ud83d\uddd2\ufe0f .env created from example. Update values before production."
fi

# Export variables for subsequent commands
set -a
source .env
set +a

log "\u2699\ufe0f Running local setup"
./scripts/local-setup.sh

log "\ud83d\ude80 Deploying contracts"
cd contract
npx hardhat run scripts/deploy.js --network polygon
DEPLOYED_ADDRESS=$(node -p "require('./deployments.json').contractAddress")
cd ..

if [ -n "$DEPLOYED_ADDRESS" ]; then
  sed -i "s/^CONTRACT_ADDRESS=.*/CONTRACT_ADDRESS=$DEPLOYED_ADDRESS/" .env
  log "\ud83d\udcdd Updated CONTRACT_ADDRESS in .env"
fi

log "\ud83d\udcbb Building frontend"
cd frontend && npm run build && cd ..

log "\ud83d\udd27 Starting services"
npm install -g pm2 serve >/dev/null 2>&1
pm2 start ecosystem.config.js
pm2 start --name flashloan-frontend npx serve -s frontend/dist -l 80
pm2 save

log "\u2705 All services started"
