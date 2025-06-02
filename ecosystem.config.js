module.exports = {
  apps: [
    {
      name: 'flashloan-backend',
      script: './backend/server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true,
      max_restarts: 10,
      min_uptime: '10s'
    },
    {
      name: 'flashloan-bot',
      script: './bot/arbitrageBot.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/bot-error.log',
      out_file: './logs/bot-out.log',
      log_file: './logs/bot-combined.log',
      time: true,
      max_restarts: 5,
      min_uptime: '30s'
    }
  ]
};
