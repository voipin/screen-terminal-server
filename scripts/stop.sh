#!/bin/bash

echo "🛑 Stopping Screen Terminal Server and Ngrok"

# Stop using saved PIDs if available
if [ -f /tmp/screen-terminal-server.pid ]; then
    PID=$(cat /tmp/screen-terminal-server.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Stopped screen terminal server (PID: $PID)"
    fi
    rm -f /tmp/screen-terminal-server.pid
fi

if [ -f /tmp/ngrok-http.pid ]; then
    PID=$(cat /tmp/ngrok-http.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Stopped ngrok HTTP tunnel (PID: $PID)"
    fi
    rm -f /tmp/ngrok-http.pid
fi

if [ -f /tmp/ngrok-ws.pid ]; then
    PID=$(cat /tmp/ngrok-ws.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Stopped ngrok WebSocket tunnel (PID: $PID)"
    fi
    rm -f /tmp/ngrok-ws.pid
fi

# Also kill by process name as backup
pkill -f "node screen-terminal-server.js" 2>/dev/null || true
pkill -f "ngrok.*3000" 2>/dev/null || true
pkill -f "ngrok.*3001" 2>/dev/null || true

echo "✅ All services stopped"