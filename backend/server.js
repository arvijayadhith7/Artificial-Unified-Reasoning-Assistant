const express = require('express');
const http    = require('http');
const path    = require('path');
const cors    = require('cors');
const config  = require('./config/config');
const socketService = require('./services/socket.service'); // Socket.IO (for Flutter app)
const wsService     = require('./services/ws.service');     // Native WS (for web portal)
const memoryService = require('./services/memory.service');

const app = express();
app.use(cors());
app.use(express.json());

// Custom CSP for Flutter Web Compatibility
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://www.gstatic.com https://www.google.com; " +
    "connect-src 'self' https://fonts.gstatic.com https://www.gstatic.com http://localhost:3000 ws://localhost:3000 http://192.168.1.4:3000 ws://192.168.1.4:3000 ws://localhost:7860 wss://localhost:7860; " +
    "img-src 'self' data: https://www.gstatic.com; " +
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
    "font-src 'self' https://fonts.gstatic.com; " +
    "worker-src 'self' blob:;"
  );
  next();
});

// Serve Flutter web build
const buildPath = path.join(__dirname, '../build/web');
app.use(express.static(buildPath));

// Serve AURA web portal (standalone HTML/CSS/JS)
const webPortalPath = path.join(__dirname, '../aura_web_portal');
app.use('/portal', express.static(webPortalPath));

// --- REST ROUTES ---

app.get('/', (req, res) => {
  const indexPath = path.join(buildPath, 'index.html');
  if (require('fs').existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.json({
      status: 'AURA Enterprise Backend Active',
      message: 'Web interface not found. Connect via Flutter Mobile App.',
      timestamp: new Date().toISOString()
    });
  }
});

app.get('/status', (req, res) => {
  res.json({ status: 'active', version: '1.0.0-enterprise' });
});

// Chat history routes (used by web portal sidebar)
app.get('/chats', async (req, res) => {
  try {
    const { data, error } = await memoryService.supabase
      .from('messages')
      .select('sessionid, content, timestamp')
      .order('timestamp', { ascending: false });

    if (error) throw error;

    const sessionsMap = {};
    (data || []).forEach(row => {
      if (!sessionsMap[row.sessionid]) {
        sessionsMap[row.sessionid] = {
          id: row.sessionid,
          title: row.content ? row.content.slice(0, 50) : 'New Conversation',
          updated_at: Math.floor(new Date(row.timestamp).getTime() / 1000)
        };
      }
    });

    res.json(Object.values(sessionsMap));
  } catch (err) {
    console.error('❌ /chats error:', err.message);
    res.json([]);
  }
});

app.get('/chats/:convId', async (req, res) => {
  try {
    const { convId } = req.params;
    const history = await memoryService.getHistory(convId);
    const messages = (history || []).map(h => ({
      role: h.role === 'model' ? 'assistant' : h.role,
      content: h.parts ? h.parts[0].text : (h.content || '')
    }));
    res.json(messages);
  } catch (err) {
    console.error('❌ /chats/:id error:', err.message);
    res.json([]);
  }
});

// Overlay context routes (used by overlay-client.js)
app.get('/overlay/context', (req, res) => {
  // Returns active app context \u2014 native detection not available in web mode, return safe defaults
  res.json({
    active_app: '',
    window_title: '',
    selected_text: '',
    accessibility_text: '',
    platform: req.query.platform || 'web'
  });
});

app.get('/system/active-window', (req, res) => {
  res.json({ process: '', title: '' });
});

// --- SERVER ---
const server = http.createServer(app);

// Socket.IO — for Flutter mobile app
const { Server } = require('socket.io');
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});
socketService.init(io);

// Native WebSocket — for AURA web portal (/chat path)
wsService.init(server);

server.listen(config.port, () => {
  console.log(`🚀 AURA Enterprise Backend running on port ${config.port}`);
  console.log(`🌐 Web Portal: http://localhost:${config.port}/portal`);
  console.log(`🔌 WebSocket:  ws://localhost:${config.port}/chat`);
});
