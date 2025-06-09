// FlashLoan Arbitrage Bot - Main Entry Point
const { ethers } = require('ethers');
const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
require('dotenv').config();

const FLASHLOAN_ABI = [
    'function initiateFlashloan(address asset, uint256 amount, uint8 dex, address intermediate, uint24 fee)'
];

class ArbitrageBot {
    constructor() {
        this.isRunning = false;
        this.failureCount = 0;
        this.config = {
            trainingMode: process.env.TRAINING_MODE === 'true',
            flashloanAmount: process.env.FLASHLOAN_AMOUNT || '5000',
            minProfitPercent: parseFloat(process.env.MIN_PROFIT_PERCENT) || 0.5,
            runInterval: parseInt(process.env.RUN_INTERVAL_SEC) || 12,
            stopLoss: parseInt(process.env.STOP_LOSS_COUNT) || 3
        };

        this.db = new sqlite3.Database(process.env.DATABASE_PATH || './data/arbitrage.db');
        this.provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
        const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
        this.contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, FLASHLOAN_ABI, wallet);
        this.oneInchKey = process.env.ONEINCH_API_KEY;

        this.asset = process.env.USDC_ADDRESS;
        this.intermediate = process.env.USDT_ADDRESS;
        this.poolFee = parseInt(process.env.UNISWAP_FEE) || 3000; // 0.3%

        console.log('🤖 Arbitrage Bot initialized');
        console.log(`📊 Training Mode: ${this.config.trainingMode}`);
        console.log(`💰 Flash Loan Amount: $${this.config.flashloanAmount}`);
    }

    async fetchUniswapPrice(amount) {
        const url = `https://api.1inch.io/v5.0/137/quote?fromTokenAddress=${this.asset}&toTokenAddress=${this.intermediate}&amount=${amount}&protocols=UNISWAP_V3`;
        const headers = this.oneInchKey ? { Authorization: `Bearer ${this.oneInchKey}` } : {};
        const res = await axios.get(url, { headers });
        return parseFloat(res.data.toTokenAmount);
    }

    async fetchSushiPrice(amount) {
        const url = `https://api.1inch.io/v5.0/137/quote?fromTokenAddress=${this.asset}&toTokenAddress=${this.intermediate}&amount=${amount}&protocols=SUSHI`;
        const headers = this.oneInchKey ? { Authorization: `Bearer ${this.oneInchKey}` } : {};
        const res = await axios.get(url, { headers });
        return parseFloat(res.data.toTokenAmount);
    }

    logTrade(pair, amountUsd, profitUsd, status) {
        this.db.run(
            'INSERT INTO arbitrage_logs (token_pair, amount_usd, profit_usd, status) VALUES (?,?,?,?)',
            [pair, amountUsd, profitUsd, status],
            err => {
                if (err) console.error('DB log error:', err.message);
            }
        );
    }

    async checkAndExecute() {
        const amount = ethers.utils.parseUnits(this.config.flashloanAmount, 6).toString();
        try {
            const uni = await this.fetchUniswapPrice(amount);
            const sushi = await this.fetchSushiPrice(amount);
            const diff = Math.abs(uni - sushi);
            const base = Math.min(uni, sushi);
            const diffPercent = base === 0 ? 0 : (diff / base) * 100;

            if (diffPercent >= this.config.minProfitPercent) {
                const dex = uni > sushi ? 0 : 1; // buy cheap, sell expensive
                const profit = (diffPercent / 100) * parseFloat(this.config.flashloanAmount);

                if (!this.config.trainingMode) {
                    await this.contract.initiateFlashloan(this.asset, amount, dex, this.intermediate, this.poolFee);
                }

                this.logTrade(`${this.asset}/${this.intermediate}`, this.config.flashloanAmount, profit, 'success');
                this.failureCount = 0;
            } else {
                this.logTrade(`${this.asset}/${this.intermediate}`, this.config.flashloanAmount, 0, 'skipped');
            }
        } catch (err) {
            console.error('Trade error:', err.message);
            this.failureCount += 1;
            this.logTrade(`${this.asset}/${this.intermediate}`, this.config.flashloanAmount, 0, 'error');

            if (this.failureCount >= this.config.stopLoss) {
                console.error('🚨 Stop loss triggered');
                await this.stop();
            }
        }
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
                if (this.config.trainingMode) {
                    console.log('🧠 Training mode: Scanning opportunities...');
                }

                await this.checkAndExecute();

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

    async stop() {
        if (!this.isRunning) {
            console.log('⏹️  Bot already stopped');
            return;
        }

        this.isRunning = false;
        console.log('🛑 Stopping Arbitrage Bot...');
        this.db.close(err => {
            if (err) {
                console.error('DB close error:', err.message);
            }
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
