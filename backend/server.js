const express = require('express');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config/config');
const socketService = require('./services/socket.service');

const app = express();
app.use(cors());
// app.use(helmet());
app.use(express.json());

// Custom CSP for Flutter Web Compatibility
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://www.gstatic.com https://www.google.com; " +
    "connect-src 'self' https://fonts.gstatic.com https://www.gstatic.com http://localhost:3000 ws://localhost:3000 http://192.168.1.4:3000 ws://192.168.1.4:3000; " +
    "img-src 'self' data: https://www.gstatic.com; " +
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
    "font-src 'self' https://fonts.gstatic.com; " +
    "worker-src 'self' blob:;"
  );
  next();
});
const buildPath = path.join(__dirname, '../build/web');
app.use(express.static(buildPath));

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

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Initialize Socket Service
socketService.init(io);

// Basic Auth / Status Route
app.get('/status', (req, res) => {
  res.json({ status: 'active', version: '1.0.0-enterprise' });
});

server.listen(config.port, () => {
  console.log(`🚀 Enterprise AI Pipeline running on port ${config.port}`);
});
