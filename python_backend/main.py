import os
import sys
import json
import re
import requests
import subprocess
import uvicorn
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from threading import Thread, Lock as ThreadingLock
from bs4 import BeautifulSoup
from groq import Groq as GroqClient

# Agent Plugins
from agent_plugins.rag_advanced import AdvancedRAG
from agent_plugins.sql_agent import SQLAgent

# Vector Memory & Reasoning
import chromadb
from sentence_transformers import SentenceTransformer

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Initialize Neural Link (Groq)
groq_key = os.environ.get("GROQ_API_KEY")
groq_client = GroqClient(api_key=groq_key) if groq_key else None

# 2. Advanced Context & Memory Engine
class NeuralMemory:
    def __init__(self, path):
        self.client = chromadb.PersistentClient(path=path)
        self.collection = self.client.get_or_create_collection(name="aura_memory_vault")
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2', device='cpu')

    def retrieve_context(self, query, top_k=5):
        try:
            query_embedding = self.embedder.encode(query).tolist()
            results = self.collection.query(query_embeddings=[query_embedding], n_results=top_k)
            return "\n".join(results['documents'][0]) if results['documents'] else ""
        except: return ""

    def store_fragment(self, text):
        try:
            embedding = self.embedder.encode(text).tolist()
            self.collection.add(
                documents=[text],
                embeddings=[embedding],
                ids=[f"mem_{hash(text)}_{os.times().elapsed}"]
            )
        except: pass

memory = NeuralMemory(os.environ.get('KB_PATH', './memory/vector_db'))
advanced_rag = AdvancedRAG(memory.collection)
sql_agent = SQLAgent(os.environ.get('SUPABASE_DB_URL')) 

# 3. Conversational Reasoning Toolbox
class ReasoningToolbox:
    @staticmethod
    def scrape_web(url):
        try:
            response = requests.get(url, timeout=10)
            soup = BeautifulSoup(response.text, 'html.parser')
            text = " ".join([p.text for p in soup.find_all('p')])
            return text[:4000]
        except Exception as e: return f"Error: {str(e)}"

    @staticmethod
    def run_python(code):
        try:
            result = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True, timeout=10)
            return f"Output: {result.stdout}\nErrors: {result.stderr}"
        except Exception as e: return f"Execution failed: {str(e)}"

    def execute_tool(self, call_str):
        if "hybrid_search" in call_str:
            q = re.search(r'query="([^"]+)"', call_str)
            return str(advanced_rag.hybrid_search(q.group(1))) if q else "Error"
        if "scrape_web" in call_str:
            u = re.search(r'url="([^"]+)"', call_str)
            return self.scrape_web(u.group(1)) if u else "Error"
        if "query_db" in call_str:
            s = re.search(r'sql="([^"]+)"', call_str)
            return sql_agent.execute_query(s.group(1)) if s else "Error"
        if "run_python" in call_str:
            c = re.search(r'code="(.+)"', call_str, re.DOTALL)
            return self.run_python(c.group(1)) if c else "Error"
        return "Error: Tool not found."

# 4. Core Conversational Pipeline
class InferenceEngine:
    def __init__(self):
        self.toolbox = ReasoningToolbox()
        self.lock = ThreadingLock()

    def _sanitize_history(self, history):
        sanitized = []
        last_role = None
        for msg in history:
            # Handle both Gemini format (role, parts) and Groq format (role, content)
            raw_role = msg.get("role", "user")
            role = "assistant" if raw_role in ["model", "assistant"] else "user"
            
            content = msg.get("content", "")
            if not content and "parts" in msg and len(msg["parts"]) > 0:
                content = msg["parts"][0].get("text", "")
                
            if role == last_role: continue # Skip consecutive messages
            sanitized.append({"role": role, "content": content})
            last_role = role
            
        # Ensure the last message in history before user prompt is from assistant
        if sanitized and sanitized[-1].get("role") == "user":
            sanitized.pop()
        return sanitized

    def generate_stream(self, prompt, history):
        if not groq_client:
            yield "AURA Error: Neural Link Offline (GROQ_API_KEY required)."
            return

        with self.lock:
            context = memory.retrieve_context(prompt)
            
            # LIVE INTENT DETECTION
            live_keywords = ['today', 'now', 'news', 'live', 'price', 'score', 'weather', 'current', 'latest', 'match', 'vs']
            needs_search = any(k in prompt.lower() for k in live_keywords) or '?' in prompt or len(prompt) > 30

            research_data = ""
            if needs_search:
                yield {"type": "thought", "content": f"Searching live web for '{prompt}'..."}
                try:
                    import urllib.parse
                    import urllib.request
                    url = "https://lite.duckduckgo.com/lite/"
                    data = urllib.parse.urlencode({'q': prompt}).encode('utf-8')
                    req = urllib.request.Request(url, data=data, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req, timeout=5) as response:
                        html = response.read().decode('utf-8')
                        snippets = re.findall(r"<td class='result-snippet'[^>]*>([\s\S]*?)</td>", html, re.IGNORECASE)
                        clean_snippets = [re.sub(r'<[^>]*>', '', s).strip() for s in snippets[:3]]
                        if clean_snippets:
                            research_data = " ".join(clean_snippets)
                            yield {"type": "thought", "content": "Analyzing live search results..."}
                except Exception as e:
                    pass
            
            system_prompt = f"""You are AURA, a modern conversational AI assistant.

Your job is to reply naturally like ChatGPT.

---------------------------------------------------
IMPORTANT RULES
---------------------------------------------------

Never:
- expose internal functions
- show pipeline logic
- show search functions
- show reasoning steps
- say things like:
  - "hybrid_search()"
  - "retrieving context"
  - "processing query"
  - "executing pipeline"

Do NOT behave like a debugging assistant.

The user should only see a clean natural response.

---------------------------------------------------
CONVERSATION STYLE
---------------------------------------------------

Reply:
- naturally
- conversationally
- intelligently
- concisely

Avoid excessive formatting for normal conversations.

Only use headings or bullets when genuinely useful.

---------------------------------------------------
GOOD RESPONSE EXAMPLES
---------------------------------------------------

User:
"hi"

AURA:
"Hey! How can I help you today?"

---------------------------------------------------

User:
"tell me about today's IPL match"

AURA:
"Today's IPL match is between Chennai Super Kings and Mumbai Indians.

Match Time:
7:30 PM IST

Venue:
Wankhede Stadium, Mumbai

Would you also like:
- probable playing XI
- pitch report
- fantasy predictions
- live score updates?"

---------------------------------------------------

User:
"build me an AI chatbot"

AURA:
"Sure — a good starting stack would be:

- Flutter for frontend
- FastAPI for backend
- Transformers + PyTorch for the LLM
- ChromaDB for memory

Main Steps:
1. Create chat UI
2. Setup backend API
3. Load transformer model
4. Add streaming responses
5. Add memory system

I can also help you with:
- architecture
- prompts
- backend code
- UI design"

---------------------------------------------------
FORMATTING RULES
---------------------------------------------------

For casual conversations:
- keep replies short and natural

For technical topics:
- use concise structured formatting

For coding:
- use clean code blocks

For research:
- summarize clearly without over-formatting

---------------------------------------------------
MOBILE CHAT RULES
---------------------------------------------------

Responses must:
- feel smooth on mobile
- avoid giant paragraphs
- avoid excessive headings
- feel premium and modern

---------------------------------------------------
PERSONALITY
---------------------------------------------------

AURA should feel:
- intelligent
- calm
- modern
- human-like
- helpful

Tone:
- friendly
- professional
- conversational

---------------------------------------------------
FINAL RULE
---------------------------------------------------

Behave like a real AI assistant talking to a human.

Do NOT behave like an exposed AI pipeline or debugging console.

Memory Context:
{context}

Live Web Research Data:
{research_data if research_data else "No live data needed or found."}
"""

            try:
                safe_history = self._sanitize_history(history)
                messages = [{"role": "system", "content": system_prompt}] + safe_history + [{"role": "user", "content": prompt}]
                
                response = groq_client.chat.completions.create(
                    model="llama-3.3-70b-versatile",
                    messages=messages,
                    stream=True,
                    temperature=0.6
                )
                
                full_text = ""
                for chunk in response:
                    content = chunk.choices[0].delta.content
                    if content:
                        full_text += content
                        yield content
                
                if len(full_text) > 100:
                    Thread(target=memory.store_fragment, args=(f"Context: {prompt} | Memory: {full_text[:300]}",)).start()

                if "<tool_call>" in full_text and "</tool_call>" in full_text:
                    match = re.search(r'<tool_call>(.*?)</tool_call>', full_text)
                    if match:
                        tool_out = self.toolbox.execute_tool(match.group(1))
                        follow_up = groq_client.chat.completions.create(
                            model="llama-3.3-70b-versatile",
                            messages=[{"role": "system", "content": system_prompt}, 
                                      {"role": "user", "content": prompt}, 
                                      {"role": "assistant", "content": full_text},
                                      {"role": "user", "content": f"Neural Link Result: {tool_out}"}],
                            stream=True
                        )
                        for chunk in follow_up:
                            content = chunk.choices[0].delta.content
                            if content: yield content

            except Exception as e:
                print(f"Neural Engine Error: {str(e)}")
                yield f"\n[Neural Link Disruption: {str(e)}]\n"

engine = InferenceEngine()

@app.websocket("/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        try:
            data = await websocket.receive_text()
            msg = json.loads(data)
            prompt = msg.get("prompt", "")
            history = msg.get("history", [])
            for chunk in engine.generate_stream(prompt, history):
                if isinstance(chunk, dict):
                    await websocket.send_text(json.dumps(chunk))
                else:
                    await websocket.send_text(json.dumps({"type": "chunk", "content": chunk}))
            await websocket.send_text(json.dumps({"done": True}))
        except Exception as e:
            print(f"WebSocket Error: {e}")
            break

@app.get("/")
async def health():
    return {"status": "AURA Intelligence OS Online", "engine": "Groq-Llama-3.3-70B"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
