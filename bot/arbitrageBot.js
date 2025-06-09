// FlashLoan Arbitrage Bot - Main Entry Point
const { ethers } = require('ethers');
const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
const { spawnSync } = require('child_process');
const path = require('path');
require('dotenv').config();

class ArbitrageBot {
    constructor() {
        this.isRunning = false;
        this.config = {
            trainingMode: process.env.TRAINING_MODE === 'true',
            flashloanAmount: process.env.FLASHLOAN_AMOUNT || '5000',
            minProfitPercent: parseFloat(process.env.MIN_PROFIT_PERCENT) || 0.5,
            runInterval: parseInt(process.env.RUN_INTERVAL_SEC) || 12
        };

        this.dbPath = process.env.DATABASE_PATH || path.join(__dirname, '..', 'data', 'arbitrage.db');
        this.modelPath = path.join(__dirname, '..', 'ai', 'models', 'arbitrage_model.joblib');
        this.db = new sqlite3.Database(this.dbPath, err => {
            if (err) console.error('SQLite error:', err.message);
        });

        console.log('🤖 Arbitrage Bot initialized');
        console.log(`📊 Training Mode: ${this.config.trainingMode}`);
        console.log(`💰 Flash Loan Amount: $${this.config.flashloanAmount}`);
    }

    async start() {
        if (this.isRunning) {
            console.log('⚠️  Bot is already running');
            return;
        }

        this.isRunning = true;
        console.log('🚀 Starting Arbitrage Bot...');

        // Main bot loop would go here
        this.runLoop();
    }

    async runLoop() {
        while (this.isRunning) {
            try {
                const features = await this.gatherFeatures();
                const predicted = await this.predictProfit(features);
                await this.logPrediction(features, predicted);

                if (!this.config.trainingMode && predicted >= this.config.minProfitPercent) {
                    console.log(`✅ Predicted profit ${predicted.toFixed(2)}% \u2013 executing trade`);
                    await this.executeTrade(features.amount);
                } else {
                    console.log(`❌ Predicted profit ${predicted.toFixed(2)}% below threshold`);
                }

                await this.sleep(this.config.runInterval * 1000);
            } catch (error) {
                console.error('❌ Error in main loop:', error.message);
                await this.sleep(5000);
            }
        }
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async gatherFeatures() {
        const amount = parseFloat(this.config.flashloanAmount);
        const slippage = parseFloat(process.env.MAX_SLIPPAGE_PERCENT) || 0.5;
        const gasPrice = await this.getGasPrice();
        const volatility = await this.getVolatility();
        return { amount, slippage, gasPrice, volatility };
    }

    async getGasPrice() {
        try {
            const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
            const price = await provider.getGasPrice();
            return parseFloat(ethers.utils.formatUnits(price, 'gwei'));
        } catch (err) {
            console.error('Failed to fetch gas price:', err.message);
            return 0;
        }
    }

    async getVolatility() {
        try {
            const res = await axios.get('https://api.binance.com/api/v3/ticker/24hr?symbol=ETHUSDT');
            return Math.abs(parseFloat(res.data.priceChangePercent));
        } catch (err) {
            console.error('Failed to fetch volatility:', err.message);
            return 0;
        }
    }

    async predictProfit(features) {
        const args = [
            path.join(__dirname, '..', 'ai', 'predictor.py'),
            features.amount,
            features.slippage,
            features.gasPrice,
            features.volatility
        ].map(String);
        const result = spawnSync('python3', args, { encoding: 'utf8' });
        if (result.error) {
            console.error('Prediction error:', result.error.message);
            return 0;
        }
        const value = parseFloat(result.stdout.trim());
        return isNaN(value) ? 0 : value;
    }

    async logPrediction(features, profit) {
        const stmt = this.db.prepare(
            'INSERT INTO ai_training_data (amount, slippage, gas_price, volatility, profit) VALUES (?, ?, ?, ?, ?)'
        );
        stmt.run([
            features.amount,
            features.slippage,
            features.gasPrice,
            features.volatility,
            profit
        ], err => {
            if (err) console.error('DB insert error:', err.message);
        });
        stmt.finalize();
    }

    async executeTrade(amount) {
        console.log(`📈 Executing trade with amount $${amount}`);
        // Placeholder for real trade logic
    }

    async stop() {
        this.isRunning = false;
        console.log('🛑 Stopping Arbitrage Bot...');
        await new Promise(resolve => {
            this.db.close(err => {
                if (err) {
                    console.error('DB close error:', err.message);
                }
                resolve();
            });
        });
    }
}

// Start bot if run directly
if (require.main === module) {
    const bot = new ArbitrageBot();

    process.on('SIGINT', async () => {
        console.log('\n🛑 Received SIGINT, gracefully shutting down...');
        await bot.stop();
        process.exit(0);
    });

    bot.start().catch(console.error);
}

module.exports = ArbitrageBot;
