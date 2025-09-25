#!/bin/bash

echo "🧪 Testing Screen Terminal Server Setup"
echo "=========================================="

# Test 1: Check if server is running
echo "1. Testing server health..."
if curl -s http://localhost:3000/api/sessions > /dev/null 2>&1; then
    echo "✅ Server is running and responding"
else
    echo "❌ Server is not responding"
    exit 1
fi

# Test 2: Check ngrok HTTP tunnel
echo "2. Testing ngrok HTTP tunnel..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://wondrous-radically-bluebird.ngrok-free.app)
if [ "$HTTP_RESPONSE" = "302" ]; then
    echo "✅ HTTP tunnel is working (Status: $HTTP_RESPONSE - OAuth Redirect)"
elif [ "$HTTP_RESPONSE" = "200" ]; then
    echo "✅ HTTP tunnel is working (Status: $HTTP_RESPONSE)"
else
    echo "❌ HTTP tunnel failed (Status: $HTTP_RESPONSE)"
fi

# Test 3: Check ngrok WebSocket tunnel
echo "3. Testing ngrok WebSocket tunnel..."
WS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://bb780517535f.ngrok.app)
if [ "$WS_RESPONSE" = "426" ]; then
    echo "✅ WebSocket tunnel is working (Status: $WS_RESPONSE - Upgrade Required)"
else
    echo "❌ WebSocket tunnel failed (Status: $WS_RESPONSE)"
fi

# Test 4: Check available screen sessions
echo "4. Checking available screen sessions..."
SESSIONS=$(curl -s http://localhost:3000/api/sessions | jq length)
echo "✅ Found $SESSIONS screen sessions available"

# Test 5: Display process information
echo "5. Checking process status..."
if [ -f /tmp/screen-terminal-server.pid ]; then
    SERVER_PID=$(cat /tmp/screen-terminal-server.pid)
    if ps -p $SERVER_PID > /dev/null; then
        echo "✅ Server process is running (PID: $SERVER_PID)"
    else
        echo "❌ Server process is not running"
    fi
fi

if [ -f /tmp/ngrok-http.pid ]; then
    NGROK_HTTP_PID=$(cat /tmp/ngrok-http.pid)
    if ps -p $NGROK_HTTP_PID > /dev/null; then
        echo "✅ Ngrok HTTP process is running (PID: $NGROK_HTTP_PID)"
    else
        echo "❌ Ngrok HTTP process is not running"
    fi
fi

if [ -f /tmp/ngrok-ws.pid ]; then
    NGROK_WS_PID=$(cat /tmp/ngrok-ws.pid)
    if ps -p $NGROK_WS_PID > /dev/null; then
        echo "✅ Ngrok WebSocket process is running (PID: $NGROK_WS_PID)"
    else
        echo "❌ Ngrok WebSocket process is not running"
    fi
fi

echo ""
echo "🎉 Setup Test Complete!"
echo "========================"
echo "🌐 Web Interface: https://wondrous-radically-bluebird.ngrok-free.app"
echo "🔌 WebSocket: wss://bb780517535f.ngrok.app"
echo ""
echo "📋 Next Steps:"
echo "   1. Open the web interface in your browser"
echo "   2. Connect to an existing screen session or create a new one"
echo "   3. Test terminal resizing by resizing your browser window"
echo "   4. Verify that terminal input/output works correctly"