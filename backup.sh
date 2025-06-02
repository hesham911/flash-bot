#!/bin/bash
# Backup important data

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "💾 Creating backup..."

# Backup database
if [ -f "data/arbitrage.db" ]; then
    cp data/arbitrage.db $BACKUP_DIR/arbitrage_$DATE.db
    echo "✅ Database backed up"
fi

# Backup config
if [ -f ".env" ]; then
    cp .env $BACKUP_DIR/env_$DATE.backup
    echo "✅ Config backed up"
fi

# Backup logs
if [ -d "logs" ]; then
    tar -czf $BACKUP_DIR/logs_$DATE.tar.gz logs/
    echo "✅ Logs backed up"
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.backup" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "🎉 Backup completed: $DATE"
