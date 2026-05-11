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

  async performWebSearch(query, onChunk) {
    try {
      console.log(`🌐 [RESEARCH] Searching web (DDG) for: ${query}`);
      onChunk({ type: 'thought', content: `Searching live web for "${query}"...` });
      
      const encodedQuery = encodeURIComponent(query);
      const url = `https://html.duckduckgo.com/html/?q=${encodedQuery}`;
      
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        }
      });
      
      const html = await response.text();
      const results = [];
      const resultBlocks = html.split('<div class="result__body">').slice(1, 6);
      
      for (const block of resultBlocks) {
        const titleMatch = block.match(/<a class="result__a"[^>]*>([\s\S]*?)<\/a>/i);
        const snippetMatch = block.match(/<a class="result__snippet"[^>]*>([\s\S]*?)<\/a>/i);
        if (titleMatch) {
          const title = titleMatch[1].replace(/<[^>]*>/g, '').trim();
          const snippet = snippetMatch ? snippetMatch[1].replace(/<[^>]*>/g, '').trim() : "";
          results.push(`Title: ${title}\nSnippet: ${snippet}`);
        }
      }
      
      if (results.length === 0) return null;

      // --- RESEARCH ANALYSIS STAGE ---
      onChunk({ type: 'thought', content: "Analyzing search results for relevance..." });
      const analysisPrompt = `Analyze these search results and extract key facts for: "${query}"\n\nResults:\n${results.join('\n\n')}\n\nProvide a concise bulleted summary of findings.`;
      
      const analysis = await this.groq.chat.completions.create({
        messages: [{ role: 'user', content: analysisPrompt }],
        model: "llama-3-8b-8192",
        temperature: 0.1,
      });

      const analyzedContent = analysis.choices[0].message.content;
      onChunk({ type: 'tool', content: "Research Analysis Complete." });
      
      return analyzedContent;
    } catch (err) {
      console.error('💥 [RESEARCH ERROR]:', err);
      return null;
    }
  }

  // --- REASONING THINKING STAGE ---
  async getReasoning(text, history, onChunk) {
    console.log('📝 Performing strategic thinking...');
    onChunk({ type: 'thought', content: "Thinking about how to address this request..." });
    
    const reasoningPrompt = `
You are the inner reasoning module of AURA. 
Task: Analyze the user's request and outline a strategy to answer it.
User: "${text}"
History context provided.

Think about:
1. What is the core intent?
2. Does it need real-time data?
3. What tone should be used?

Keep it brief. Use "Thought: ..." format.
`;

    try {
      const response = await this.groq.chat.completions.create({
        messages: [{ role: 'user', content: reasoningPrompt }],
        model: "llama-3-8b-8192",
        temperature: 0.5,
        max_tokens: 150,
      });

      const thought = response.choices[0].message.content;
      onChunk({ type: 'thought', content: thought });
      return thought;
    } catch (e) {
      return "Strategic thinking module offline. Proceeding with standard generation.";
    }
  }

  // --- THE AURA INTELLIGENCE PIPELINE ---
  async getStreamingResponse(text, history, onChunk, modelType = 'groq') {
    try {
      // 1. REASONING
      const strategicThought = await this.getReasoning(text, history, onChunk);

      // 2. LIVE INTENT DETECTION
      const needsSearch = this.detectLiveIntent(text);
      let researchData = "";

      // 3. RESEARCH & ANALYSIS
      if (needsSearch) {
        researchData = await this.performWebSearch(text, onChunk);
      }

      // 4. FINAL SYNTHESIS
      if (modelType === 'aura') {
        return await pythonService.getStreamingResponse(text, history, onChunk, researchData);
      } else {
        return await this.getGroqResponse(text, history, onChunk, researchData, strategicThought);
      }
    } catch (error) {
      console.error('💥 Pipeline Error:', error);
      throw error;
    }
  }

  detectLiveIntent(text) {
    const query = text.toLowerCase();
    const liveKeywords = ['today', 'now', 'news', 'live', 'price', 'score', 'weather', 'current', 'latest', 'match', 'vs'];
    return liveKeywords.some(k => query.includes(k)) || query.includes('?') || query.length > 30;
  }

  async getGroqResponse(text, history, onChunk, researchData = "", thought = "") {
    let systemPrompt = `
# AURA NEURAL CORE v2.0 (FINE-TUNED & BROWSER-ENABLED)
You are AURA, an elite artificial intelligence. You HAVE full access to real-time web research through your integrated search engine.

## CORE CAPABILITIES
- **Live Browsing**: You use the "LIVE RESEARCH" section below to see the world as it is TODAY.
- **Authority**: Never state "I do not have access to live data" or "As an AI...". You ARE a live agent.
- **Tone**: Professional, precise, and authoritative.

## BEHAVIORAL CONSTRAINTS
1. **Never refuse** to look for information. If search data is provided, treat it as your own real-time perception.
2. If the "LIVE RESEARCH" section is empty, explain that you are currently analyzing the situation based on available data, but NEVER say you lack internet access.
3. Synthesize research naturally into your response.
`;
    
    if (thought) systemPrompt += `\n\n## INTERNAL STRATEGY:\n${thought}`;
    if (researchData) {
        systemPrompt += `\n\n## LIVE RESEARCH (CURRENT WEB DATA):\n${researchData}`;
    } else {
        systemPrompt += `\n\n## NOTE:\nSearch was performed but no direct results were returned. Use your reasoning to provide the best possible estimation or general info without breaking character.`;
    }

    const messages = [{ role: 'system', content: systemPrompt }];
    (history || []).forEach(h => {
      const content = h.parts ? h.parts[0].text : (h.text || "");
      messages.push({ role: h.role === 'model' ? 'assistant' : 'user', content });
    });
    messages.push({ role: 'user', content: text });

    const stream = await this.groq.chat.completions.create({
      messages: messages,
      model: "llama-3.3-70b-versatile",
      stream: true,
      temperature: 0.3,
    });

    let fullText = "";
    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || "";
      if (content) {
        fullText += content;
        onChunk({ type: 'chunk', content });
      }
    }
    return fullText;
  }
}

module.exports = new AIService();
