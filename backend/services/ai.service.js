const config = require('../config/config');
const pythonService = require('./python.service');
const Groq = require('groq-sdk');

class AIService {
  constructor() {
    this.groq = config.groqApiKey ? new Groq({ apiKey: config.groqApiKey }) : null;
    
    if (!config.groqApiKey) {
      console.warn('⚠️ WARNING: No GROQ_API_KEY found in .env file. AURA will be unresponsive.');
    }
  }

  async performWebSearch(query) {
    try {
      console.log(`🌐 Searching web (Mojeek) for: ${query}`);
      const encodedQuery = encodeURIComponent(query);
      const url = `https://www.mojeek.com/search?q=${encodedQuery}`;
      
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      });
      const html = await response.text();
      
      const titleRegex = /<h2[^>]*>\s*<a[^>]*>([\s\S]*?)<\/a>\s*<\/h2>/gi;
      const snippetRegex = /<p class="s">([\s\S]*?)<\/p>/gi;
      
      const results = [];
      let match;
      while ((match = titleRegex.exec(html)) && results.length < 5) {
        const title = match[1].replace(/<[^>]*>/g, '').replace(/&#039;/g, "'").replace(/&quot;/g, '"').trim();
        const sMatch = snippetRegex.exec(html);
        const snippet = sMatch ? sMatch[1].replace(/<[^>]*>/g, '').replace(/&#039;/g, "'").replace(/&quot;/g, '"').trim() : '';
        if (title) {
          results.push(`Source: Mojeek\nTitle: ${title}\nSnippet: ${snippet}`);
        }
      }
      
      if (results.length === 0) {
        console.warn('⚠️ No results found on Mojeek.');
        return "No real-time results found. Answer based on your internal knowledge but mention you couldn't find live data.";
      }
      
      console.log(`✅ Found ${results.length} results.`);
      return results.join('\n\n');
    } catch (err) {
      console.error('Search Error:', err);
      return "Unable to retrieve live data. Answer based on your existing knowledge.";
    }
  }

  // --- THE AURA INTELLIGENCE PIPELINE ---
  async getStreamingResponse(text, history, onChunk, modelType = 'groq') {
    console.log(`\n🚀 [PIPELINE START] Processing query: "${text.substring(0, 50)}..."`);
    
    try {
      // STAGE 1: ANALYSIS
      console.log('📝 Stage 1: Analysis - Detecting intent...');
      const isLiveQuery = this.detectLiveIntent(text);
      let searchContext = "";

      // STAGE 2: RESEARCH (Conditional)
      if (isLiveQuery) {
        console.log('📝 Stage 2: Research - Accessing real-time data...');
        onChunk({ type: 'thought', content: "Researching real-time information..." });
        searchContext = await this.performWebSearch(text);
        onChunk({ type: 'tool', content: "Search completed." });
      } else {
        console.log('📝 Stage 2: Research - Skipped (No live intent)');
      }

      // STAGE 3: CONTEXTUALIZATION
      console.log('📝 Stage 3: Contextualization - Formatting system prompt...');
      const systemPrompt = this.getSystemPrompt(searchContext);

      // STAGE 4: GENERATION
      console.log('📝 Stage 4: Generation - Calling LLM...');
      const result = await this.getGroqResponse(text, history, onChunk, searchContext);
      
      console.log('✅ [PIPELINE COMPLETE] Response generated.\n');
      return result;
    } catch (error) {
      console.error('💥 [PIPELINE CRASH]:', error);
      throw error;
    }
  }

  detectLiveIntent(text) {
    const query = text.toLowerCase();
    const liveKeywords = [
      'today', 'now', 'news', 'live', 'price', 'score', 'weather', 'current', 'latest',
      'who is', 'who was', 'tell me about', 'what is', 'happened', 'update', 'status',
      'vs', 'match', 'election', 'result', 'cricket', 'football', 'stock', 'market'
    ];
    // Also trigger if the query looks like a proper noun inquiry or is long enough
    return liveKeywords.some(keyword => query.includes(keyword)) || 
           (query.split(' ').length > 2 && (query.includes('?') || query.length > 30));
  }

  getSystemPrompt(searchContext = "") {
    let prompt = `
# AURA: THE ADVANCED INTELLIGENCE COMPANION

You are AURA, an advanced AI assistant. Your personality is intelligent, calm, helpful, conversational, and highly articulate.

## CORE BEHAVIOR
- **Natural & Human-like**: Speak clearly. Avoid robotic phrases like "As an AI language model".
- **Tone**: Friendly but professional.
- **Directness**: Give direct answers first, then explain.

## SEARCH CAPABILITY
When SEARCH CONTEXT is provided below, you MUST use it to answer the question as accurately as possible. If the user asks for "today", "now", or "latest", prioritize the search data over your training data.
`;

    if (searchContext) {
      prompt += `
## LIVE RESEARCH CONTEXT (CRITICAL)
The following information was retrieved from the web just now. Use it to provide an up-to-date answer:
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

      (history || []).forEach(h => {
        const content = h.parts && h.parts[0] ? h.parts[0].text : (h.text || "");
        if (content) {
          messages.push({
            role: h.role === 'model' || h.role === 'assistant' ? 'assistant' : 'user',
            content: content
          });
        }
      });

      messages.push({ role: 'user', content: text });
      
      console.log(`📡 Groq Messages: ${JSON.stringify(messages).substring(0, 100)}...`);

      const stream = await this.groq.chat.completions.create({
        messages: messages,
        model: "llama-3.3-70b-versatile",
        stream: true,
        temperature: 0.2,
      });

      let fullResponse = "";
      console.log('🌊 Starting Groq stream loop...');
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
