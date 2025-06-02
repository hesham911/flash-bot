#!/bin/bash
# FlashLoan Bot Local Setup

set -e

GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

log_info "🚀 Setting up FlashLoan Arbitrage Bot locally..."

# Copy environment file
if [ ! -f "../.env" ]; then
    cp ../.env.example ../.env
    log_info "📝 .env file created - please configure with your settings"
fi

# Install dependencies
log_info "📦 Installing dependencies..."
cd ../backend && npm install && cd ../scripts
cd ../frontend && npm install && cd ../scripts
cd ../bot && npm install && cd ../scripts
cd ../contract && npm install && cd ../scripts

# Setup Python environment
cd ../ai
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ../scripts

# Initialize database
log_info "🗄️  Initializing database..."
mkdir -p ../data
sqlite3 ../data/arbitrage.db << 'SQL'
CREATE TABLE IF NOT EXISTS arbitrage_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    token_pair TEXT,
    amount_usd REAL,
    profit_usd REAL,
    status TEXT
);

CREATE TABLE IF NOT EXISTS ai_training_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    amount REAL,
    slippage REAL,
    gas_price REAL,
    volatility REAL,
    profit REAL
);
SQL

log_info "✅ Local setup completed!"
log_info "🚀 Run './start-dev.sh' to start development servers"
