# API Documentation

## Endpoints

### Health Check
```
GET /api/health
```

### Bot Control
```
POST /api/bot/start
POST /api/bot/stop
GET /api/bot/status
```

### Analytics
```
GET /api/analytics/dashboard
GET /api/trades
```

All endpoints require authentication header:
```
Authorization: Bearer <jwt_token>
```
