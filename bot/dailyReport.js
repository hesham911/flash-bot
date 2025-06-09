const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const TelegramBot = require('node-telegram-bot-api');
require('dotenv').config();

const dbPath = process.env.DATABASE_PATH || path.join(__dirname, '..', 'data', 'arbitrage.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, err => {
    if (err) {
        console.error('DB open error:', err.message);
        process.exit(1);
    }
});

const query = `
  SELECT
    COUNT(*) AS total,
    SUM(profit_usd) AS totalProfit,
    SUM(CASE WHEN status='success' THEN 1 ELSE 0 END) AS successes,
    SUM(CASE WHEN status='error' THEN 1 ELSE 0 END) AS errors
  FROM arbitrage_logs
  WHERE datetime(timestamp) >= datetime('now', '-1 day')
`;

function sendReport(message) {
    const token = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    if (token && chatId) {
        const bot = new TelegramBot(token, { polling: false });
        bot.sendMessage(chatId, message)
            .then(() => console.log('✅ Sent report to Telegram'))
            .catch(err => console.error('Telegram error:', err.message))
            .finally(() => db.close());
    } else {
        db.close();
    }
}

db.get(query, (err, row) => {
    if (err) {
        console.error('DB query error:', err.message);
        return db.close();
    }

    const total = row.total || 0;
    const totalProfit = row.totalProfit || 0;
    const successes = row.successes || 0;
    const errors = row.errors || 0;
    const successRate = total ? ((successes / total) * 100).toFixed(2) : '0.00';

    const date = new Date().toISOString().slice(0, 10);
    const report =
        `\uD83D\uDCC8 Daily Report (${date})\n` +
        `Total Trades: ${total}\n` +
        `Successful: ${successes}\n` +
        `Failures: ${errors}\n` +
        `Success Rate: ${successRate}%\n` +
        `Profit: $${totalProfit.toFixed(2)}`;

    console.log(report);
    sendReport(report);
});
