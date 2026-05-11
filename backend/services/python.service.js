const WebSocket = require('ws');
const config = require('../config/config');

class PythonService {
  async getStreamingResponse(text, history, onChunk, searchContext = "") {
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(config.localInferenceUrl);
      let fullResponse = "";

      ws.on('open', () => {
        // Transform Gemini-style history to Python backend style
        // Gemini: { role, parts: [{ text }] }
        // Python: { role, content }
        const formattedHistory = history.map(h => ({
          role: h.role === 'model' ? 'assistant' : 'user',
          content: h.parts[0].text
        }));

        ws.send(JSON.stringify({
          text: text,
          history: formattedHistory,
          searchContext: searchContext
        }));
      });

      ws.on('message', (data) => {
        const response = JSON.parse(data);
        
        // Handle standard chunks
        if (response.chunk) {
          fullResponse += response.chunk;
          onChunk({ type: 'chunk', content: response.chunk });
        }
        
        // Handle agentic thoughts
        if (response.thought) {
          onChunk({ type: 'thought', content: response.thought });
        }

        // Handle tool logs (e.g., "Running Python code...")
        if (response.tool) {
          onChunk({ type: 'tool', content: response.tool });
        }

        // Handle tool outputs
        if (response.output) {
          onChunk({ type: 'output', content: response.output });
        }

        if (response.done) {
          ws.close();
          resolve(fullResponse);
        }
      });

      ws.on('error', (error) => {
        console.error('Python Inference Error:', error);
        reject(error);
      });

      ws.on('close', () => {
        console.log('Python Inference connection closed');
      });
    });
  }
}

module.exports = new PythonService();
