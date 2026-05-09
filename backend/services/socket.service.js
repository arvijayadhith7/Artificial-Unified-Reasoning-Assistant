const aiService = require('./ai.service');
const memoryService = require('./memory.service');

class SocketService {
  init(io) {
    io.on('connection', (socket) => {
      console.log('User connected:', socket.id);
      const sessionId = socket.id;

      socket.on('message', async (data) => {
        const { text, modelType = 'gemini' } = data;
        
        try {
          // 1. Get History
          const history = await memoryService.getHistory(sessionId);
          
          // 2. Stream Response
          let fullResponse = "";
          await aiService.getStreamingResponse(text, history, (data) => {
            // data is now { type: 'chunk'|'thought'|'tool'|'output', content: '...' }
            socket.emit('chunk', data);
            if (data.type === 'chunk') {
              fullResponse += data.content;
            }
          }, modelType);

          // 3. Update Memory
          await memoryService.addMessage(sessionId, 'user', text);
          await memoryService.addMessage(sessionId, 'model', fullResponse);

          socket.emit('done', { text: fullResponse });
        } catch (error) {
          socket.emit('error', 'AI processing failed.');
        }
      });

      socket.on('disconnect', () => {
        console.log('User disconnected');
        // Optional: clear memory after disconnect or keep for a while
      });
    });
  }
}

module.exports = new SocketService();
