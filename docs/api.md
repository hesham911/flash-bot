# API Documentation

## Endpoints

### Health Check
```
GET /api/health
```

### Bot Control

#### `POST /api/bot/start`

Starts the arbitrage bot.

Request
```http
POST /api/bot/start
Authorization: Bearer <jwt_token>
```

Response
```json
{ "running": true }
```

#### `POST /api/bot/stop`

Stops the bot.

Request
```http
POST /api/bot/stop
Authorization: Bearer <jwt_token>
```

Response
```json
{ "running": false }
```

#### `GET /api/bot/status`

Returns current running state.

Request
```http
GET /api/bot/status
Authorization: Bearer <jwt_token>
```

Response
```json
{ "running": true }
```

### Analytics

#### `GET /api/trades`

Returns recent trades from `data/arbitrage.db`.

Request
```http
GET /api/trades
Authorization: Bearer <jwt_token>
```

Response
```json
{
  "trades": [
    {
      "id": 1,
      "timestamp": "2023-01-01T00:00:00Z",
      "token_pair": "USDC/USDT",
      "amount_usd": 5000,
      "profit_usd": 12.34,
      "status": "completed"
    }
  ]
}
```

All endpoints require authentication header:
```
Authorization: Bearer <jwt_token>
```
