# Configuration Guide

## Environment Variables

### Required Settings
- `PRIVATE_KEY`: Your wallet private key
- `ONEINCH_API_KEY`: 1inch API key for price quotes
- `RPC_URL`: Polygon RPC endpoint

### Bot Settings
- `FLASHLOAN_AMOUNT`: Amount in USD (default: 5000)
- `MIN_PROFIT_PERCENT`: Minimum profit threshold (default: 0.5)
- `TRAINING_MODE`: Enable safe testing (default: true)
- `STOP_LOSS_COUNT`: Consecutive failures before stopping (default: 3)
- `UNISWAP_FEE`: Uniswap V3 fee tier in basis points (default: 3000)

### Security
- `JWT_SECRET`: Secret for API authentication
- `ADMIN_PASSWORD_HASH`: Bcrypt hashed dashboard password

See `.env.example` for complete configuration.
