# Screen Terminal Server

A web-based terminal interface for accessing screen sessions with OAuth authentication and external access via ngrok.

## Features

- 🖥️ **Web Terminal Interface**: Full terminal emulation using xterm.js
- 🔐 **OAuth Authentication**: Google OAuth protection for web access
- 🌐 **External Access**: Ngrok tunnels for remote access
- 📱 **Responsive Design**: Terminal resizing on window resize
- 🔄 **Real-time Communication**: WebSocket for terminal input/output
- 📋 **Session Management**: List, create, and connect to screen sessions

## Quick Start

### 1. Install Dependencies
```bash
cd screen-terminal-server
npm install
```

### 2. Configure Settings
Edit `config.sh`:
```bash
# Your custom domain configured in ngrok
CUSTOM_DOMAIN="wondrous-radically-bluebird.ngrok-free.app"

# OAuth Configuration
OAUTH_PROVIDER="google"
OAUTH_ALLOW_EMAIL="doug.ruby@cloudwarriors.ai"
```

### 3. Start the Server
```bash
./scripts/start-custom.sh
```

### 4. Access the Interface
Open your browser and navigate to the displayed URL (requires OAuth authentication).

## Directory Structure

```
screen-terminal-server/
├── README.md                 # This file
├── package.json              # Node.js dependencies
├── package-lock.json         # Dependency lock file
├── config.sh                 # Configuration settings
├── screen-terminal-server.js # Main server application
├── public/
│   └── index.html           # Web interface frontend
└── scripts/
    ├── start-custom.sh      # Main launch script
    ├── launch-with-ngrok.sh # Alternative launcher
    ├── stop.sh              # Stop script
    └── test-setup.sh        # Diagnostic test script
```

## Configuration

### OAuth Authentication
- **Provider**: Google OAuth
- **Authorized Email**: Configured in `config.sh`
- **Protected**: HTTP tunnel only (WebSocket remains open for functionality)

### Ngrok Tunnels
- **HTTP Tunnel**: OAuth protected, serves web interface
- **WebSocket Tunnel**: Open, handles terminal communication

## Usage

### Web Interface
1. Navigate to the ngrok URL (OAuth authentication required)
2. View available screen sessions
3. Connect to existing session or create new one
4. Use terminal with full resizing support

### Management Commands
```bash
# Start server
./scripts/start-custom.sh

# Alternative launcher with monitoring
./scripts/launch-with-ngrok.sh

# Stop server
./scripts/stop.sh

# Test setup
./scripts/test-setup.sh
```

## Dependencies

### Runtime
- **Node.js**: JavaScript runtime
- **ngrok**: External tunnel service

### Node.js Packages
- **express**: Web server framework
- **ws**: WebSocket library
- **node-pty**: Process handling
- **@modelcontextprotocol/sdk**: MCP integration
- **@opencode-ai/sdk**: OpenCode integration
- **eventsource**: Event streaming

### Frontend
- **xterm.js**: Terminal emulation (CDN)
- **xterm-addon-fit**: Terminal resizing (CDN)
- **xterm-addon-web-links**: Link handling (CDN)

## Security

### OAuth Protection
- Web interface protected by Google OAuth
- Only configured email address can access
- Session-based authentication

### Network Security
- Separate tunnels for HTTP and WebSocket
- OAuth on HTTP tunnel only (WebSocket needs direct access)
- Ngrok provides HTTPS encryption

## Troubleshooting

### Common Issues
1. **OAuth not working**: Verify email configuration in `config.sh`
2. **WebSocket connection failed**: Check that WebSocket tunnel is running without OAuth
3. **Terminal not resizing**: Verify browser JavaScript is enabled
4. **Ngrok tunnels failing**: Check ngrok installation and authentication

### Log Files
- Server logs: `screen-terminal.log`
- Process IDs: `/tmp/screen-terminal-server.pid`, `/tmp/ngrok-http.pid`, `/tmp/ngrok-ws.pid`

## Development

### Local Development
```bash
# Install dependencies
npm install

# Start server locally (no ngrok)
node screen-terminal-server.js

# Access at: http://localhost:3000
```

### Testing
```bash
# Run diagnostic tests
./scripts/test-setup.sh
```

## License

ISC License