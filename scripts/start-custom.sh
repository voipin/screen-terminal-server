#!/bin/bash

# Load configuration
source config.sh

if [ -z "$CUSTOM_DOMAIN" ] || [ "$CUSTOM_DOMAIN" = "your-terminal-domain.ngrok.io" ]; then
    echo "❌ Please edit config.sh and set your CUSTOM_DOMAIN"
    echo "   Example: CUSTOM_DOMAIN=\"terminal.yourdomain.com\""
    exit 1
fi

echo "🚀 Starting Screen Terminal Server with Custom Domain and OAuth"
echo "🌐 Domain: $CUSTOM_DOMAIN"
echo "🔐 OAuth: $OAUTH_PROVIDER ($OAUTH_ALLOW_EMAIL)"
echo ""

# Kill existing processes
pkill -f "node screen-terminal-server.js" 2>/dev/null || true
pkill -f "ngrok.*3000" 2>/dev/null || true
pkill -f "ngrok.*3001" 2>/dev/null || true
sleep 2

# Set up ngrok auth token if provided
if [ ! -z "$NGROK_AUTH_TOKEN" ]; then
    echo "🔑 Setting up ngrok authentication..."
    ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
fi

# Start server
echo "🖥️  Starting screen terminal server..."
if [ "$LOG_ENABLED" = true ]; then
    nohup node screen-terminal-server.js > "$LOG_FILE" 2>&1 &
else
    node screen-terminal-server.js &
fi
SERVER_PID=$!

sleep 3

# Check if server is running
if ! curl -s http://localhost:3000/api/sessions > /dev/null 2>&1; then
    echo "❌ Failed to start screen terminal server"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

echo "✅ Screen terminal server started successfully"

# Start ngrok tunnels
echo "🌐 Starting ngrok tunnel for HTTP server with custom domain and OAuth..."
ngrok http --oauth=$OAUTH_PROVIDER --oauth-allow-email=$OAUTH_ALLOW_EMAIL --domain=$CUSTOM_DOMAIN 3000 &
NGROK_HTTP_PID=$!

echo "🔌 Starting ngrok tunnel for WebSocket server..."
ngrok http 3001 &
NGROK_WS_PID=$!

sleep 8

# Get URLs
HTTP_URL="https://$CUSTOM_DOMAIN"
WS_URL=$(curl -s http://localhost:4041/api/tunnels | jq -r '.tunnels[0].public_url')
WS_URL=$(echo "$WS_URL" | sed 's/https:/wss:/')

echo ""
echo "🎉 READY!"
echo "=============================================="
echo "🌐 Web Interface: $HTTP_URL"
echo "🔌 WebSocket: $WS_URL"
echo ""
echo "📊 Process Information:"
echo "   Server PID: $SERVER_PID"
echo "   Ngrok HTTP PID: $NGROK_HTTP_PID"
echo "   Ngrok WS PID: $NGROK_WS_PID"
echo ""
echo "🛑 To stop: ./stop.sh"
echo "📋 View logs: [ $LOG_ENABLED = $LOG_ENABLED ]"
if [ "$LOG_ENABLED" = true ]; then
    echo "   Log file: $LOG_FILE"
fi
echo ""

# Save PIDs for later use
echo "$SERVER_PID" > /tmp/screen-terminal-server.pid
echo "$NGROK_HTTP_PID" > /tmp/ngrok-http.pid
echo "$NGROK_WS_PID" > /tmp/ngrok-ws.pid

echo "✅ Process IDs saved to /tmp/"
echo ""
echo "🌐 Open your browser and navigate to:"
echo "   $HTTP_URL"