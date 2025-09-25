import express from 'express';
import { WebSocketServer } from 'ws';
import pty from 'node-pty';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const app = express();
const PORT = 3000;
const WS_PORT = 3001;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Store active terminal connections
const activeTerminals = new Map();

// Get list of screen sessions
app.get('/api/sessions', async (req, res) => {
  try {
    const { stdout } = await execAsync('screen -ls');
    const sessions = parseScreenList(stdout);
    res.json(sessions);
  } catch (error) {
    // If no sessions exist, screen returns exit code 1
    if (error.code === 1) {
      res.json([]);
    } else {
      res.status(500).json({ error: error.message });
    }
  }
});

// Create new screen session
app.post('/api/sessions', async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Session name is required' });
    }
    
    await execAsync(`screen -dmS ${name}`);
    res.json({ success: true, message: `Session '${name}' created` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Parse screen -ls output
function parseScreenList(output) {
  const sessions = [];
  const lines = output.split('\n');
  
  for (const line of lines) {
    const match = line.match(/^\s*(\d+)\.(\S+)\s+\(([^)]+)\)/);
    if (match) {
      sessions.push({
        pid: match[1],
        name: match[2],
        status: match[3]
      });
    }
  }
  
  return sessions;
}

// WebSocket server for terminal communication
const wss = new WebSocketServer({ port: WS_PORT });

wss.on('connection', (ws, request) => {
  const url = new URL(request.url, `http://${request.headers.host}`);
  const sessionName = url.searchParams.get('session');
  
  if (!sessionName) {
    ws.close(1008, 'Session name required');
    return;
  }

  let ptyProcess;
  let terminalSize = { cols: 80, rows: 24 };
  
  try {
    // Use node-pty to create a proper pseudo-terminal for screen
    // Use -x instead of -r to allow multiple connections to attached sessions
    ptyProcess = pty.spawn('screen', [`-x`, sessionName], {
      name: 'xterm-256color',
      cols: terminalSize.cols,
      rows: terminalSize.rows,
      env: { ...process.env, TERM: 'xterm-256color' }
    });

    // Store the process and size for cleanup and resizing
    activeTerminals.set(ws, { process: ptyProcess, size: terminalSize });

    // Send terminal output to WebSocket
    ptyProcess.on('data', (data) => {
      try {
        ws.send(JSON.stringify({ type: 'output', data: data.toString() }));
      } catch (error) {
        console.error('Error sending WebSocket data:', error);
      }
    });

    // Handle WebSocket messages (user input and resize)
    ws.on('message', (message) => {
      try {
        const parsed = JSON.parse(message);
        
        if (parsed.type === 'input' && parsed.data) {
          ptyProcess.write(parsed.data);
        } else if (parsed.type === 'detach') {
          // Handle explicit detach request using screen's built-in detach
          // Use screen's detach command directly on the session
          execAsync(`screen -S ${sessionName} -X detach`).then(() => {
            // After detach command succeeds, close the connection
            setTimeout(() => {
              if (ptyProcess) {
                ptyProcess.kill();
              }
              ws.close();
            }, 100);
          }).catch(err => {
            console.error('Detach command failed:', err);
            // Fallback: try sending detach sequence through pty
            ptyProcess.write('\x01'); // Ctrl+A
            setTimeout(() => {
              ptyProcess.write('d'); // D
              setTimeout(() => {
                if (ptyProcess) {
                  ptyProcess.kill();
                }
                ws.close();
              }, 200);
            }, 100);
          });
        } else if (parsed.type === 'resize' && parsed.cols && parsed.rows) {
          // Handle terminal resize
          terminalSize.cols = parsed.cols;
          terminalSize.rows = parsed.rows;
          try {
            ptyProcess.resize(parsed.cols, parsed.rows);

            // Note: Screen sessions maintain their original size when attached.
            // The ptyProcess.resize() ensures the terminal display matches the browser window,
            // but the underlying screen session content may not reflow to the new size.
            // This is a limitation of screen's design - sessions are sized when created.
          } catch (resizeError) {
            // Silently handle resize errors
          }
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    });

    // Handle WebSocket close
    ws.on('close', () => {
      if (ptyProcess) {
        // Try to detach using screen command first
        execAsync(`screen -S ${sessionName} -X detach`).then(() => {
          ptyProcess.kill();
        }).catch(err => {
          // Fallback: send detach sequence through pty
          ptyProcess.write('\x01'); // Ctrl+A
          setTimeout(() => {
            ptyProcess.write('d'); // D
            setTimeout(() => {
              ptyProcess.kill();
            }, 200);
          }, 200);
        });
      }
      activeTerminals.delete(ws);
    });

    // Handle process exit
    ptyProcess.on('exit', (code) => {
      ws.send(JSON.stringify({ type: 'exit', code }));
      ws.close();
      activeTerminals.delete(ws);
    });

    ws.send(JSON.stringify({ type: 'connected', session: sessionName }));

  } catch (error) {
    ws.send(JSON.stringify({ type: 'error', data: `Failed to connect to session: ${error.message}` }));
    ws.close();
  }
});

// Start servers
app.listen(PORT, () => {
  console.log(`HTTP server running on http://localhost:${PORT}`);
});

console.log(`WebSocket server running on ws://localhost:${WS_PORT}`);

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('Shutting down...');
  for (const [ws, terminalData] of activeTerminals) {
    terminalData.process.kill();
    ws.close();
  }
  wss.close();
  process.exit(0);
});