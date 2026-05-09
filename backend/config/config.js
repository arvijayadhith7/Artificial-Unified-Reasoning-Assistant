require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  geminiApiKey: process.env.GEMINI_API_KEY || 'AIzaSyA...',
  mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/ai_chatbot',
  jwtSecret: process.env.JWT_SECRET || 'super-secret-key',
  redisConfig: {
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT || 6379,
  },
  localInferenceUrl: process.env.LOCAL_INFERENCE_URL || 'ws://127.0.0.1:8000/chat',
  groqApiKey: process.env.GROQ_API_KEY || '',
  modelsPath: 'D:\\ANTIGRAVITY\\llm APP\\models'
};
