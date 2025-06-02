#!/bin/bash
# System status check

echo "📊 FlashLoan Bot Status"
echo "======================="

# Check processes
echo "🔍 Processes:"
ps aux | grep -E "(node|npm)" | grep -v grep | head -5

# Check ports
echo ""
echo "🌐 Ports:"
netstat -tlnp 2>/dev/null | grep -E ":300[1-9]|:517[0-9]" || echo "No active ports"

# Check database
echo ""
echo "🗄️  Database:"
if [ -f "data/arbitrage.db" ]; then
    echo "Database exists ($(du -h data/arbitrage.db | cut -f1))"
else
    echo "Database not found"
fi

# Check logs
echo ""
echo "📝 Recent logs:"
if [ -d "logs" ] && [ "$(ls -A logs 2>/dev/null)" ]; then
    ls -la logs/ | tail -3
else
    echo "No logs found"
fi
