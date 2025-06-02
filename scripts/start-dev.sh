#!/bin/bash
# Start development servers

echo "🚀 Starting FlashLoan Bot development servers..."

# Function to cleanup on exit
cleanup() {
    echo "🛑 Shutting down services..."
    jobs -p | xargs -r kill
    exit
}

trap cleanup SIGINT SIGTERM

# Start backend
echo "📡 Starting backend API..."
cd ../backend && npm run dev &

# Wait for backend
sleep 3

# Start frontend
echo "🌐 Starting frontend..."
cd ../frontend && npm run dev &

echo ""
echo "✅ Services started!"
echo "📊 Dashboard: http://localhost:5173"
echo "🔗 API: http://localhost:3001/api/health"
echo ""

# If --with-bot flag, start bot
if [ "$1" = "--with-bot" ]; then
    echo "🤖 Starting bot in training mode..."
    cd ../bot && TRAINING_MODE=true npm start &
    echo "🧠 Bot running in safe training mode"
fi

echo "Press Ctrl+C to stop all services"
wait
