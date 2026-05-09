const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/config');
const pythonService = require('./python.service');
const Groq = require('groq-sdk');

class AIService {
  constructor() {
    this.genAI = new GoogleGenerativeAI(config.geminiApiKey);
    this.model = this.genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    this.groq = config.groqApiKey ? new Groq({ apiKey: config.groqApiKey }) : null;
  }

  async getStreamingResponse(text, history, onChunk, modelType = 'gemini') {
    console.log('Model Routing:', modelType);
    try {
      if (modelType === 'local') {
        return await pythonService.getStreamingResponse(text, history, onChunk);
      }

      if (modelType === 'groq') {
        return await this.getGroqResponse(text, history, onChunk);
      }

      // 1. Intent Detection
      const intent = this.detectIntent(text);
      console.log(`Routing to ${intent} agent...`);

      // 2. Persona Adaptation (System Instruction)
      const systemInstruction = this.getSystemPrompt(intent);
      
      const dynamicModel = this.genAI.getGenerativeModel({ 
        model: "gemini-1.5-flash",
        systemInstruction: { parts: [{ text: systemInstruction }] }
      });

      const chat = dynamicModel.startChat({
        history: history || [],
        generationConfig: {
          maxOutputTokens: 2048,
          temperature: 0.7,
        },
      });

      const result = await chat.sendMessageStream(text);
      
      let fullResponse = "";
      for await (const chunk of result.stream) {
        const chunkText = chunk.text();
        fullResponse += chunkText;
        onChunk({ type: 'chunk', content: chunkText });
      }
      
      return fullResponse;
    } catch (error) {
      console.error('AIService Error:', error);
      throw error;
    }
  }

  detectIntent(text) {
    const query = text.toLowerCase();
    if (query.includes('code') || query.includes('function') || query.includes('flutter')) return 'coding';
    if (query.includes('search') || query.includes('find') || query.includes('who is')) return 'research';
    if (query.includes('sad') || query.includes('happy') || query.includes('feel')) return 'empathy';
    return 'general';
  }

  getSystemPrompt(intent) {
    const base = "You are an advanced, emotionally intelligent AI assistant. ";
    switch (intent) {
      case 'coding':
        return base + "You are a Senior Software Architect. Provide clean, production-ready code with explanations.";
      case 'research':
        return base + "You are a Professional Researcher. Provide factual, cited information and synthesize complex topics.";
      case 'empathy':
        return base + "You are a Supportive Companion. Prioritize emotional intelligence, empathy, and listening.";
      default:
        return base + "Be helpful, concise, and engaging.";
    }
  }

  async getGroqResponse(text, history, onChunk) {
    if (!this.groq) {
      onChunk({ type: 'chunk', content: "Error: Groq API Key missing. Please add it to your .env file." });
      return "Error: Groq API Key missing.";
    }

    try {
      // Format history for Groq (OpenAI style)
      const messages = history.map(h => ({
        role: h.role === 'model' ? 'assistant' : 'user',
        content: h.parts[0].text
      }));
      messages.push({ role: 'user', content: text });

      const stream = await this.groq.chat.completions.create({
        messages: messages,
        model: "llama-3.3-70b-versatile",
        stream: true,
      });

      let fullResponse = "";
      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content || "";
        if (content) {
          fullResponse += content;
          onChunk({ type: 'chunk', content: content });
        }
      }
      return fullResponse;
    } catch (error) {
      console.error('Groq Error:', error);
      throw error;
    }
  }
}

module.exports = new AIService();
