const WebSocket = require('ws');
const aiService = require('./ai.service');
const memoryService = require('./memory.service');

class WsService {
  /**
   * Attaches a native WebSocket server to the existing HTTP server
   * on the path `/chat` — compatible with the web portal's raw WebSocket client.
   */
  init(httpServer) {
    const wss = new WebSocket.Server({ server: httpServer, path: '/chat' });

    wss.on('connection', (ws) => {
      console.log('🔗 [WS] Web portal client connected');

      ws.on('message', async (raw) => {
        let payload;
        try {
          payload = JSON.parse(raw);
        } catch (e) {
          ws.send(JSON.stringify({ type: 'chunk', content: '⚠️ Invalid message format.' }));
          return;
        }

        // Web portal sends: { prompt, conversationId, history, sandbox }
        const text         = payload.prompt || payload.text || '';
        const sessionId    = payload.conversationId || 'default_web';
        const clientHistory = payload.history || [];

        if (!text) return;

        console.log(`📩 [WS] Message from session "${sessionId}": ${text.slice(0, 80)}`);

        // Notify connection OK
        ws.send(JSON.stringify({ type: 'status', content: 'Handshake complete. Initializing cognitive pathway...' }));

        try {
          // Get persisted history from Supabase; fall back to client-sent history
          let history = [];
          try {
            history = await memoryService.getHistory(sessionId);
          } catch (_) {}
          if (!history || history.length === 0) history = clientHistory;

          let fullResponse = '';

          await aiService.getStreamingResponse(text, history, (data) => {
            // Normalize chunk shape to what the web portal expects:
            //   { type: 'chunk', content }          → live text
            //   { type: 'thought_step', title, body } → thought panel
            //   { type: 'status', content }           → progress label
            if (!ws || ws.readyState !== WebSocket.OPEN) return;

            if (data.type === 'chunk') {
              fullResponse += data.content;
              ws.send(JSON.stringify({ type: 'chunk', content: data.content }));

            } else if (data.type === 'thought') {
              // ai.service sends { type:'thought', content:'...' }
              // map to thought_step with title+body for the UI
              ws.send(JSON.stringify({
                type: 'thought_step',
                title: 'Cognitive Processing',
                body: data.content
              }));

            } else if (data.type === 'tool') {
              ws.send(JSON.stringify({
                type: 'thought_step',
                title: 'Research Complete',
                body: data.content
              }));

            } else {
              // forward anything else as a status update
              ws.send(JSON.stringify({ type: 'status', content: data.content || '' }));
            }
          });

          // Save to memory
          try {
            await memoryService.addMessage(sessionId, 'user', text);
            await memoryService.addMessage(sessionId, 'model', fullResponse);
          } catch (_) {}

          // Signal done
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ done: true, text: fullResponse }));
          }

        } catch (err) {
          console.error('💥 [WS] Pipeline error:', err);
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: 'chunk',
              content: '⚠️ AURA is experiencing a connection issue. Please ensure the backend is running and GROQ_API_KEY is valid.'
            }));
            ws.send(JSON.stringify({ done: true }));
          }
        }
      });

      ws.on('close', () => console.log('🔌 [WS] Web portal client disconnected'));
      ws.on('error', (err) => console.error('💥 [WS] Client error:', err.message));
    });

    console.log('✅ Native WebSocket server mounted on path /chat');
  }
}

module.exports = new WsService();
