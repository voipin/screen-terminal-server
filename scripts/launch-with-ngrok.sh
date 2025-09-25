#!/bin/bash

# Check for custom domain
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <your-custom-domain>"
    echo "   Example: $0 terminal.yourdomain.com"
    exit 1
fi

CUSTOM_DOMAIN=$1

echo "🚀 Launching Screen Terminal Server with Ngrok"
echo "================================================"
echo "🌐 Using custom domain: $CUSTOM_DOMAIN"
echo ""

# Check if required tools are installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install it first."
    exit 1
fi

if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed. Please install it first."
    echo "   Download from: https://ngrok.com/download"
    exit 1
fi

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f "node screen-terminal-server.js" 2>/dev/null || true
pkill -f "ngrok.*3000" 2>/dev/null || true
pkill -f "ngrok.*3001" 2>/dev/null || true

# Wait a moment for processes to stop
sleep 2

# Start the screen terminal server
echo "🖥️  Starting screen terminal server..."
node ../screen-terminal-server.js &
SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 3

# Check if server is running
if ! curl -s http://localhost:3000/api/sessions > /dev/null 2>&1; then
    echo "❌ Failed to start screen terminal server"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

echo "✅ Screen terminal server started successfully"

# Start ngrok for HTTP server (port 3000) with custom domain and OAuth
echo "🌐 Starting ngrok tunnel for HTTP server (port 3000) with OAuth..."
ngrok http --oauth=google --oauth-allow-email=doug.ruby@cloudwarriors.ai --domain=$CUSTOM_DOMAIN 3000 &
NGROK_HTTP_PID=$!

# Start ngrok for WebSocket server (port 3001) with OAuth
echo "🔌 Starting ngrok tunnel for WebSocket server (port 3001) with OAuth..."
ngrok http --oauth=google --oauth-allow-email=doug.ruby@cloudwarriors.ai 3001 &
NGROK_WS_PID=$!

# Wait for ngrok tunnels to be established
echo "⏳ Waiting for ngrok tunnels to establish..."
sleep 5

# Get ngrok URLs
echo "🔍 Retrieving ngrok URLs..."

# Function to get ngrok URL
get_ngrok_url() {
    local port=$1
    local attempts=0
    local max_attempts=10
    
    while [ $attempts -lt $max_attempts ]; do
        local url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | \
                   jq -r ".tunnels[] | select(.config.addr == \"http://localhost:$port\") | .public_url" 2>/dev/null)
        
        if [ ! -z "$url" ] && [ "$url" != "null" ]; then
            echo "$url"
            return 0
        fi
        
        attempts=$((attempts + 1))
        sleep 1
    done
    
    # Try port 4041 for the second ngrok instance
    if [ $port -eq 3001 ]; then
        local url=$(curl -s http://localhost:4041/api/tunnels 2>/dev/null | \
                   jq -r ".tunnels[] | select(.config.addr == \"http://localhost:$port\") | .public_url" 2>/dev/null)
        
        if [ ! -z "$url" ] && [ "$url" != "null" ]; then
            echo "$url"
            return 0
        fi
    fi
    
    echo ""
}

HTTP_URL=$(get_ngrok_url 3000)
WS_URL=$(get_ngrok_url 3001)

if [ -z "$HTTP_URL" ]; then
    echo "❌ Failed to get HTTP ngrok URL"
    kill $SERVER_PID $NGROK_HTTP_PID $NGROK_WS_PID 2>/dev/null
    exit 1
fi

if [ -z "$WS_URL" ]; then
    echo "❌ Failed to get WebSocket ngrok URL"
    kill $SERVER_PID $NGROK_HTTP_PID $NGROK_WS_PID 2>/dev/null
    exit 1
fi

# Convert WebSocket URL
WS_URL=$(echo "$WS_URL" | sed 's/https:/wss:/')

echo ""
echo "🎉 SUCCESS! Screen Terminal Server is running with Ngrok"
echo "================================================"
echo ""
echo "🌐 EXTERNAL ACCESS URLs:"
echo "   Web Interface: $HTTP_URL"
echo "   WebSocket:     $WS_URL"
echo ""
echo "📊 PROCESS INFORMATION:"
echo "   Server PID:    $SERVER_PID"
echo "   Ngrok HTTP PID: $NGROK_HTTP_PID"
echo "   Ngrok WS PID:   $NGROK_WS_PID"
echo ""
echo "📝 USAGE:"
echo "   1. Open the web interface in your browser:"
echo "      $HTTP_URL"
echo "   2. Connect to any available screen session"
echo "   3. Terminal will automatically resize to fit your browser window"
echo ""
echo "🛑 TO STOP:"
echo "   Run: ./stop-with-ngrok.sh"
echo "   Or press Ctrl+C to stop this script (will leave processes running)"
echo ""

# Create stop script
cat > stop-with-ngrok.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping Screen Terminal Server and Ngrok..."
pkill -f "node screen-terminal-server.js"
pkill -f "ngrok.*3000"
pkill -f "ngrok.*3001"
echo "✅ All processes stopped"
EOF

chmod +x stop-with-ngrok.sh

# Keep the script running to show status
echo "📈 Monitoring services... (Press Ctrl+C to exit monitor)"
echo ""

# Monitor function
monitor_services() {
    while true; do
        sleep 5
        
        # Check server
        if curl -s http://localhost:3000/api/sessions > /dev/null 2>&1; then
            echo "✅ Server: Running"
        else
            echo "❌ Server: Stopped"
        fi
        
        # Check ngrok HTTP
        if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
            echo "✅ Ngrok HTTP: Running"
        else
            echo "❌ Ngrok HTTP: Stopped"
        fi
        
        # Check ngrok WS
        if curl -s http://localhost:4041/api/tunnels > /dev/null 2>&1; then
            echo "✅ Ngrok WebSocket: Running"
        else
            echo "❌ Ngrok WebSocket: Stopped"
        fi
        
        echo "----------------------------------------"
    done
}

# Start monitoring in background
monitor_services &

# Wait for user interrupt
trap 'echo ""; echo "👋 Monitor stopped. Services are still running."; exit 0' INT

# Keep script running
while true; do
    sleep 1
done