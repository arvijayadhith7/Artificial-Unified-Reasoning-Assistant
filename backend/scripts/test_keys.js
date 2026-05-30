const config = require('../config/config');
const Groq = require('groq-sdk');

async function testGroq() {
  if (!config.groqApiKey) {
    console.log('❌ Groq: Key missing in .env');
    return;
  }
  try {
    const groq = new Groq({ apiKey: config.groqApiKey });
    console.log('📡 Testing Groq Streaming...');
    const stream = await groq.chat.completions.create({
      messages: [
        { role: 'system', content: 'You are AURA, an advanced AI assistant.' },
        { role: 'user', content: 'hi' }
      ],
      model: 'llama-3.3-70b-versatile',
      stream: true,
    });
    
    let fullText = "";
    for await (const chunk of stream) {
      fullText += chunk.choices[0]?.delta?.content || "";
    }
    console.log('✅ Groq: Streaming Working! Response:', fullText.substring(0, 50));
  } catch (err) {
    console.log('❌ Groq: Streaming Failed! Error:', err.message);
  }
}

async function testOpenRouter() {
  if (!config.openRouterApiKey) {
    console.log('❌ OpenRouter: Key missing in .env');
    return;
  }
  try {
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${config.openRouterApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        "model": "nousresearch/hermes-3-llama-3.1-70b",
        "messages": [{ role: "user", content: "hi" }]
      })
    });
    const data = await response.json();
    if (data.error) {
      console.log('❌ OpenRouter: Failed! API Error:', data.error.message || data.error);
    } else {
      console.log('✅ OpenRouter: Working! Response:', data.choices[0].message.content.substring(0, 50));
    }
  } catch (err) {
    console.log('❌ OpenRouter: Failed! Error:', err.message);
  }
}

console.log('🔍 Testing AURA API Keys...\n');
(async () => {
  await testGroq();
  await testOpenRouter();
})();
