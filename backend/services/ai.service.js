const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/config');
const pythonService = require('./python.service');
const Groq = require('groq-sdk');
const { search } = require('ddg-scraper');

class AIService {
  constructor() {
    this.genAI = new GoogleGenerativeAI(config.geminiApiKey);
    this.model = this.genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    this.groq = config.groqApiKey ? new Groq({ apiKey: config.groqApiKey }) : null;
  }

  async performWebSearch(query) {
    try {
      console.log(`🌐 Searching web for: ${query}`);
      const results = await search(query);
      return results.slice(0, 5).map(r => `Source: ${r.url}\nTitle: ${r.title}\nSnippet: ${r.description}`).join('\n\n');
    } catch (err) {
      console.error('Search Error:', err);
      return "Unable to retrieve live data at this moment.";
    }
  }

  async getStreamingResponse(text, history, onChunk, modelType = 'gemini') {
    try {
      // 1. Detect if live data is needed
      const isLiveQuery = this.detectLiveIntent(text);
      let searchContext = "";

      if (isLiveQuery) {
        onChunk({ type: 'chunk', content: "🔍 *Searching live data...*\n\n" });
        searchContext = await this.performWebSearch(text);
      }

      if (modelType === 'groq') {
        return await this.getGroqResponse(text, history, onChunk, searchContext);
      }

      const systemInstruction = this.getSystemPrompt(searchContext);
      
      const dynamicModel = this.genAI.getGenerativeModel({ 
        model: "gemini-1.5-flash",
        systemInstruction: { parts: [{ text: systemInstruction }] }
      });

      const chat = dynamicModel.startChat({
        history: history || [],
        generationConfig: {
          maxOutputTokens: 4096,
          temperature: 0.3,
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

  detectLiveIntent(text) {
    const query = text.toLowerCase();
    const liveKeywords = ['today', 'now', 'news', 'live', 'price', 'score', 'weather', 'current', 'latest'];
    return liveKeywords.some(keyword => query.includes(keyword));
  }

  getSystemPrompt(searchContext = "") {
    let prompt = `
# AURA ADVANCED RESEARCH & REASONING PIPELINE

You are AURA (Artificial Unified Reasoning Assistant).
Your objective: Deeply understand intent, research intelligently, and reason step-by-step using the AURA Pipeline.

## 1. REASONING PIPELINE
- Detect hidden goals and technical levels.
- Break complex requests into subtasks.
- Use chain-of-thought and logical validation.

## 3. SITUATIONAL AWARENESS
- IF the user says a simple greeting (e.g., Hi, Hello, Hey) or casual chat (e.g., How are you?): Skip the full pipeline. Give a warm, elite, and professional greeting. Be concise.
- IF the user asks a question, technical task, or research query: TRIGGER THE FULL AURA PIPELINE below.

## 4. RESPONSE FORMAT (Only for Research/Tasks)
[Understanding] - User intent summary.
[Research Summary] - Core findings and insights.
[Reasoning] - Logical interpretation and tradeoffs.
[Final Answer] - Direct and actionable response.
[Recommendations] - Next steps.
`;

    if (searchContext) {
      prompt += `
## 3. LIVE RESEARCH CONTEXT
The following real-time data was retrieved from the internet. Use it to provide an up-to-date answer:
${searchContext}
`;
    }

    return prompt;
  }

  async getGroqResponse(text, history, onChunk, searchContext = "") {
    if (!this.groq) {
      onChunk({ type: 'chunk', content: "Error: Groq API Key missing." });
      return "Error: Groq API Key missing.";
    }

    try {
      const messages = [
        { role: 'system', content: this.getSystemPrompt(searchContext) }
      ];

      history.forEach(h => {
        messages.push({
          role: h.role === 'model' ? 'assistant' : 'user',
          content: h.parts[0].text
        });
      });

      messages.push({ role: 'user', content: text });

      const stream = await this.groq.chat.completions.create({
        messages: messages,
        model: "llama-3.3-70b-versatile",
        stream: true,
        temperature: 0.2,
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
