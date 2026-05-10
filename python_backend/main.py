import os
import sys

# Force UTF-8 mode for Windows compatibility
os.environ['PYTHONUTF8'] = '1'
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Global Model Path Configuration (D: Drive)
os.environ['HF_HOME'] = r'D:\ANTIGRAVITY\llm APP\models\huggingface'
os.environ['TRANSFORMERS_CACHE'] = r'D:\ANTIGRAVITY\llm APP\models\huggingface'
os.environ['TORCH_HOME'] = r'D:\ANTIGRAVITY\llm APP\models\torch'

import torch
from transformers import AutoTokenizer, TextIteratorStreamer
from optimum.intel.openvino import OVModelForCausalLM
from sentence_transformers import SentenceTransformer
import chromadb
from chromadb.config import Settings
from fastapi import FastAPI, WebSocket
from threading import Thread, Lock as ThreadingLock
import uvicorn
import json
import requests
from bs4 import BeautifulSoup
import subprocess
import glob
import re

from fastapi.middleware.cors import CORSMiddleware
from peft import PeftModel

app = FastAPI()

# Enable CORS for WebUI access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Intel OpenVINO Optimized Loading (Turbo Mode)
model_name = "Qwen/Qwen2.5-0.5B-Instruct"
try:
    print("🚀 Loading Intel OpenVINO Turbo Engine...")
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    # OVModel automatically handles CPU/iGPU optimization
    model = OVModelForCausalLM.from_pretrained(
        model_name,
        export=True, # Convert to OpenVINO format on first load
        device="AUTO",
        trust_remote_code=True
    )
    model_loaded = True
except Exception as e:
    print(f"Turbo Load Error: {e}")
    model_loaded = False
    model = None
    tokenizer = None

# Ensure model stays loaded from the first block
pass

# 2. RAG System Initialization
class KnowledgeBase:
    def __init__(self, path):
        self.client = chromadb.PersistentClient(path=path)
        self.collection = self.client.get_or_create_collection(name="app_context")
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2', device='cuda' if torch.cuda.is_available() else 'cpu')

    def add_document(self, text, metadata=None):
        embedding = self.embedder.encode(text).tolist()
        self.collection.add(
            documents=[text],
            embeddings=[embedding],
            metadatas=[metadata] if metadata else [{"source": "manual"}],
            ids=[str(hash(text))]
        )

    def search(self, query, top_k=3):
        query_embedding = self.embedder.encode(query).tolist()
        results = self.collection.query(query_embeddings=[query_embedding], n_results=top_k)
        return results['documents'][0] if results['documents'] else []

kb_path = r'D:\ANTIGRAVITY\llm APP\memory\vector_db'
kb = KnowledgeBase(kb_path)

# 3. Enhanced Agentic Toolbox
class Toolbox:
    @staticmethod
    def search_files(query, directory=r'D:\ANTIGRAVITY'):
        """Tool: search_files(query=\"...\")"""
        print(f"🔍 Agent: Searching for '{query}'...")
        try:
            results = glob.glob(f"{directory}/**/*{query}*", recursive=True)
            return str(results[:10])
        except Exception as e:
            return f"Error: {str(e)}"

    @staticmethod
    def read_file(path):
        """Tool: read_file(path=\"...\")"""
        print(f"📖 Agent: Reading file '{path}'...")
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read(5000) # Limit to 5000 chars for context safety
                return content
        except Exception as e:
            return f"Error reading file: {str(e)}"

    @staticmethod
    def run_python(code):
        """Tool: run_python(code=\"...\")"""
        print(f"🐍 Agent: Running Python code...")
        try:
            # Note: In a production app, use a more secure sandbox like 'RestrictedPython'
            result = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True, timeout=10)
            return f"Output: {result.stdout}\nErrors: {result.stderr}"
        except Exception as e:
            return f"Execution failed: {str(e)}"

    @staticmethod
    def scrape_web(url):
        """Tool: scrape_web(url=\"...\")"""
        print(f"🌐 Agent: Scraping {url}...")
        try:
            response = requests.get(url, timeout=10)
            soup = BeautifulSoup(response.text, 'html.parser')
            # Extract clean text from paragraphs
            text = " ".join([p.text for p in soup.find_all('p')])
            return text[:4000] # Limit for context safety
        except Exception as e:
            return f"Web access failed: {str(e)}"

    @staticmethod
    def execute_tool(call_str):
        """Dispatcher for all tool calls."""
        if "search_files" in call_str:
            q = re.search(r'query="([^"]+)"', call_str)
            return Toolbox.search_files(q.group(1)) if q else "Error: missing query"
        
        if "read_file" in call_str:
            p = re.search(r'path="([^"]+)"', call_str)
            return Toolbox.read_file(p.group(1)) if p else "Error: missing path"
        
        if "run_python" in call_str:
            c = re.search(r'code="(.+)"', call_str, re.DOTALL)
            return Toolbox.run_python(c.group(1)) if c else "Error: missing code"
        
        if "scrape_web" in call_str:
            u = re.search(r'url="([^"]+)"', call_str)
            return Toolbox.scrape_web(u.group(1)) if u else "Error: missing url"
            
        return "Error: Tool not found."

class InferenceEngine:
    def __init__(self, model, tokenizer, is_mock=False):
        self.model = model
        self.tokenizer = tokenizer
        self.is_mock = is_mock
        self.toolbox = Toolbox()
        self.lock = ThreadingLock() # Ensure one inference at a time

    def generate_stream(self, prompt, history):
        if self.is_mock:
            yield f"🤖 [MOCK MODE] Simulation Active. Tools available: search_files, read_file, run_python, scrape_web."
            return

        with self.lock:
            context_docs = kb.search(prompt)
            full_prompt = self.build_prompt(prompt, history, "\n".join(context_docs))
            inputs = self.tokenizer(full_prompt, return_tensors="pt")
            
            streamer = TextIteratorStreamer(self.tokenizer, skip_prompt=True, skip_special_tokens=True)
            # Use the tokenizer's specific end tokens to prevent "leaking" internal tags
            stop_token_ids = [self.tokenizer.eos_token_id, self.tokenizer.convert_tokens_to_ids("<|end|>")]
            # SAFETY: Filter out any None values to prevent crashes
            stop_token_ids = [tid for tid in stop_token_ids if tid is not None]
            
            generate_kwargs = dict(
                **inputs,
                streamer=streamer,
                max_new_tokens=512,
                do_sample=True,
                temperature=0.7,
                eos_token_id=stop_token_ids,
                pad_token_id=self.tokenizer.pad_token_id
            )
            thread = Thread(target=self.model.generate, kwargs=generate_kwargs)
            thread.start()
            
            full_response = ""
            for chunk in streamer:
                # Final safety check: if a tag leaks, stop the stream immediately
                if any(tag in chunk for tag in ["<|user|>", "<|assistant|>", "<|system|>", "<|end|>"]):
                    break
                full_response += chunk
                yield chunk
                
                if "<tool_call>" in full_response and "</tool_call>" in full_response:
                    match = re.search(r'<tool_call>(.*?)</tool_call>', full_response)
                    if match:
                        tool_result = self.toolbox.execute_tool(match.group(1))
                        agent_prompt = f"{full_prompt}{full_response}\n<tool_response>{tool_result}</tool_response>\n"
                        for chunk in self.generate_after_tool(agent_prompt):
                            yield chunk
                        return

    def generate_after_tool(self, prompt):
        inputs = self.tokenizer(prompt, return_tensors="pt")
        streamer = TextIteratorStreamer(self.tokenizer, skip_prompt=True, skip_special_tokens=True)
        # Use OpenVINO optimized generation
        generate_kwargs = dict(
            **inputs,
            streamer=streamer,
            max_new_tokens=512,
            do_sample=True,
            temperature=0.7,
            eos_token_id=[self.tokenizer.eos_token_id, self.tokenizer.convert_tokens_to_ids("<|end|>")],
            pad_token_id=self.tokenizer.pad_token_id
        )
        # Filter out None from eos_token_id
        generate_kwargs['eos_token_id'] = [tid for tid in generate_kwargs['eos_token_id'] if tid is not None]
        
        thread = Thread(target=self.model.generate, kwargs=generate_kwargs)
        thread.start()
        for text in streamer:
            if any(tag in text for tag in ["<|user|>", "<|assistant|>", "<|system|>", "<|end|>"]):
                break
            yield text

    def build_prompt(self, prompt, history, context=""):
        system_prompt = """You are AURA, an advanced AI assistant. Your personality is intelligent, calm, helpful, conversational, emotionally aware, and highly articulate. You operate naturally as a premium companion — not a robotic chatbot.

CORE BEHAVIOR:
- Respond naturally and fluidly. Avoid repetitive or mechanical language.
- Give direct answers first, followed by clear reasoning if needed.
- Be supportive, confident, and emotionally aware.
- For technical tasks, provide clean, optimized, and modern solutions.

RESPONSE STRUCTURE:
Use this structure internally to maintain peak intelligence:
1. [Intent]: Identify user goal and sub-intent.
2. [Context]: Summarize relevant context and constraints.
3. [Plan]: Outline a step-by-step logic path.
4. [Final Answer]: Provide the primary, conversational response.
5. [Follow-up]: Suggest natural next steps.

STRICT RULES:
1. NEVER say "As an AI language model" or "I do not possess emotions."
2. Keep formatting clean and readable (bullets, short paragraphs).
3. Do not leak internal tags."""

        if context: system_prompt += f"\n\nContext:\n{context}"
        formatted_history = "".join([f"<|{m['role']}|>\n{m['content']}<|end|>\n" for m in history])
        return f"<|system|>\n{system_prompt}<|end|>\n{formatted_history}<|user|>\n{prompt}<|end|>\n<|assistant|>\n"

engine = InferenceEngine(model, tokenizer, is_mock=not model_loaded)

@app.websocket("/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        try:
            data = await websocket.receive_text()
            req = json.loads(data)
            for chunk in engine.generate_stream(req.get("text"), req.get("history", [])):
                await websocket.send_text(json.dumps({"chunk": chunk}))
            await websocket.send_text(json.dumps({"done": True}))
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"Socket Error: {e}")
            break

@app.get("/ai_updates")
async def get_ai_updates():
    try:
        url = "https://www.aixploria.com/"
        response = requests.get(url, timeout=10)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        updates = []
        # Finding the main tool/article blocks on Aixploria
        items = soup.find_all('article', limit=10)
        
        for item in items:
            title_tag = item.find('h2') or item.find('h3')
            link_tag = item.find('a')
            desc_tag = item.find('p') or item.find('div', class_='entry-content')
            
            if title_tag:
                updates.append({
                    "title": title_tag.get_text(strip=True),
                    "url": link_tag['href'] if link_tag else url,
                    "description": desc_tag.get_text(strip=True)[:100] + "..." if desc_tag else "No description available."
                })
        
        return {"status": "success", "data": updates}
    except Exception as e:
        print(f"Scrape Error: {e}")
        return {"status": "error", "message": str(e)}

@app.post("/add_document")
async def add_document(request: dict):
    kb.add_document(request.get("text"), request.get("metadata"))
    return {"status": "success"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
