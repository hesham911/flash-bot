const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const ArbitrageBot = require('../bot/arbitrageBot');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const bot = new ArbitrageBot();
const dbPath = process.env.DATABASE_PATH || path.join(__dirname, '../data/arbitrage.db');

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));

const allowedOrigins = [
    'https://devacodes.com',
    'https://www.devacodes.com'
];

app.use(cors({
    origin: function (origin, callback) {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});
app.use('/api/', limiter);

// Login route
app.post('/login', async (req, res) => {
    try {
        const { password } = req.body;
        const hash = process.env.ADMIN_PASSWORD_HASH;
        if (!password || !hash) {
            return res.status(400).json({ error: 'Invalid request' });
        }
        const match = await bcrypt.compare(password, hash);
        if (!match) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const token = jwt.sign({ user: 'admin' }, process.env.JWT_SECRET, { expiresIn: '1h' });
        res.json({ token });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// JWT authentication
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) {
        return res.status(401).json({ error: 'Missing token' });
    }
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
}
app.use('/api', authenticateToken);

// Routes
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Bot control routes
app.post('/api/bot/start', async (req, res) => {
    await bot.start();
    res.json({ running: bot.isRunning });
});

app.post('/api/bot/stop', async (req, res) => {
    await bot.stop();
    res.json({ running: bot.isRunning });
});

app.get('/api/bot/status', (req, res) => {
    res.json({ running: bot.isRunning });
});

// Recent trades
app.get('/api/trades', (req, res) => {
    const limit = parseInt(req.query.limit, 10) || 20;
    const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
        if (err) {
            console.error('DB open error:', err);
        }
    });
    db.all('SELECT * FROM arbitrage_logs ORDER BY timestamp DESC LIMIT ?', [limit], (err, rows) => {
        if (err) {
            console.error('DB query error:', err);
            res.status(500).json({ error: 'Database error' });
        } else {
            res.json({ trades: rows });
        }
        db.close();
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error('Express error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
    console.log(`🚀 Backend server running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
});
