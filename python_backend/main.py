import os
import sys
import json
import re
import requests
import subprocess
import uvicorn
import urllib.parse
import urllib.request
import time
from datetime import datetime, timedelta
from typing import Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
from fastapi import FastAPI, WebSocket, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from threading import Thread, Lock as ThreadingLock
from bs4 import BeautifulSoup
from groq import Groq as GroqClient
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

# Auth & Database
from passlib.context import CryptContext
from jose import JWTError, jwt
from sqlalchemy import create_engine, Column, String, Integer, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

# Agent Plugins
# Agent Plugins (Loaded on demand)
# from agent_plugins.rag_advanced import AdvancedRAG
# from agent_plugins.sql_agent import SQLAgent

# Vector Memory & Reasoning
import chromadb
# from sentence_transformers import SentenceTransformer (Moved to lazy load)

# 1. Configuration & Constants
SECRET_KEY = os.environ.get("AURA_SECRET_KEY", "aura_neural_encryption_key_2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 1 week session

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. Database Setup
DB_URL = "sqlite:///./memory/aura_intelligence.db"
os.makedirs('./memory', exist_ok=True)
engine = create_engine(DB_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, nullable=True)
    password_hash = Column(String, nullable=True)
    profile_image = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# 3. Neural Link & Memory Initialization
groq_key = os.environ.get("GROQ_API_KEY")
groq_client = GroqClient(api_key=groq_key) if groq_key else None

class NeuralMemory:
    def __init__(self, path):
        self.client = chromadb.PersistentClient(path=path)
        self.collection = self.client.get_or_create_collection(name="aura_memory_vault")
        self._embedder = None

    @property
    def embedder(self):
        if self._embedder is None:
            print("NEURAL LINK: Initializing SentenceTransformer (Lazy Load)...")
            from sentence_transformers import SentenceTransformer
            self._embedder = SentenceTransformer('all-MiniLM-L6-v2', device='cpu')
        return self._embedder

    def retrieve_context(self, query, top_k=5):
        try:
            query_embedding = self.embedder.encode(query).tolist()
            results = self.collection.query(query_embeddings=[query_embedding], n_results=top_k)
            return "\n".join(results['documents'][0]) if results['documents'] else ""
        except Exception as e:
            print(f"Neural Memory Error: {e}")
            return ""

    def store_fragment(self, text):
        try:
            embedding = self.embedder.encode(text).tolist()
            self.collection.add(
                documents=[text],
                embeddings=[embedding],
                ids=[f"mem_{hash(text)}_{time.time()}"]
            )
        except Exception as e:
            print(f"Neural Storage Error: {e}")
            pass

memory = NeuralMemory('./memory/vector_db')
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 4. Authentication Core
class AuthManager:
    @staticmethod
    def verify_password(plain_password, hashed_password):
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password):
        return pwd_context.hash(password)

    @staticmethod
    def create_access_token(data: dict):
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

    @staticmethod
    def decode_token(token: str):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return payload.get("sub")
        except JWTError: return None

# 5. Reasoning Engine
class InferenceEngine:
    def __init__(self):
        self.lock = ThreadingLock()

    def _sanitize_history(self, history):
        sanitized = []
        last_role = None
        for msg in history:
            role = "assistant" if msg.get("role") in ["model", "assistant"] else "user"
            content = msg.get("content", "")
            if role == last_role: continue
            sanitized.append({"role": role, "content": content})
            last_role = role
        return sanitized

    def generate_stream(self, prompt, history):
        if not groq_client:
            yield "AURA Error: Neural Link Offline. Please check your GROQ_API_KEY."
            return

        print(f"NEURAL INFERENCE: Processing prompt...")
        with self.lock:
            # 1. Research Trigger (Optimized Speed)
            research_context = ""
            keywords = ["score", "ipl", "news", "today", "weather", "match", "latest", "cricket", "who is", "what is", "how is", "price", "stock", "search"]
            if any(k in prompt.lower() for k in keywords):
                try:
                    from agent_plugins.search_agent import ResearchAgent
                    # Reuse static instance for speed
                    if not hasattr(self, '_researcher'):
                        self._researcher = ResearchAgent()
                    research_context = "\nLIVE RESEARCH DATA:\n" + self._researcher.search_live(prompt, max_results=3)
                except Exception as e:
                    print(f"Search failed: {e}")

            # 2. Memory Context
            memory_context = memory.retrieve_context(prompt)
            
            system_prompt = f"You are AURA. Be natural. Context:\n{memory_context}\n{research_context}"
            
            try:
                safe_history = self._sanitize_history(history)
                messages = [{"role": "system", "content": system_prompt}] + safe_history + [{"role": "user", "content": prompt}]
                
                # Use lightning-fast 8B model for maximum responsiveness
                response = groq_client.chat.completions.create(
                    model="llama-3.1-8b-instant", 
                    messages=messages, 
                    stream=True, 
                    temperature=0.7,
                    max_tokens=2048
                )
                
                for chunk in response:
                    if chunk.choices and chunk.choices[0].delta.content:
                        yield chunk.choices[0].delta.content
            except Exception as e:
                print(f"Inference Error: {e}")
                yield f"[AURA Link Error: {str(e)}]"

engine = InferenceEngine()

# 6. Chat History Manager
class ChatHistoryManager:
    def __init__(self):
        self.db_dir = './memory/chats'
        os.makedirs(self.db_dir, exist_ok=True)

    def _get_user_conv_file(self, user_id):
        return os.path.join(self.db_dir, f'convs_{user_id}.json')

    def save_message(self, user_id, conv_id, project_id, role, content):
        msg_file = os.path.join(self.db_dir, f'{conv_id}.json')
        messages = []
        if os.path.exists(msg_file):
            with open(msg_file, 'r', encoding='utf-8') as f: messages = json.load(f)
        messages.append({"role": role, "content": content, "timestamp": str(time.time())})
        with open(msg_file, 'w', encoding='utf-8') as f: json.dump(messages, f)
        
        conv_file = self._get_user_conv_file(user_id)
        convs = []
        if os.path.exists(conv_file):
            with open(conv_file, 'r', encoding='utf-8') as f: convs = json.load(f)
        conv = next((c for c in convs if c['id'] == conv_id), None)
        if not conv:
            conv = {"id": conv_id, "project_id": project_id, "title": content[:40], "created_at": str(time.time())}
            convs.insert(0, conv)
        conv["last_message"] = content[:100]
        conv["updated_at"] = str(time.time())
        with open(conv_file, 'w', encoding='utf-8') as f: json.dump(convs, f)

    def get_messages(self, conv_id):
        msg_file = os.path.join(self.db_dir, f'{conv_id}.json')
        if os.path.exists(msg_file):
            with open(msg_file, 'r', encoding='utf-8') as f: return json.load(f)
        return []

    def get_user_chats(self, user_id, project_id=None):
        conv_file = self._get_user_conv_file(user_id)
        if not os.path.exists(conv_file): return []
        with open(conv_file, 'r', encoding='utf-8') as f: 
            convs = json.load(f)
            return [c for c in convs if not project_id or c['project_id'] == project_id]

chat_manager = ChatHistoryManager()

# 7. Workspace Manager
class WorkspaceManager:
    def __init__(self, groq_client):
        self.groq = groq_client
        self.db_dir = './memory/workspaces'
        os.makedirs(self.db_dir, exist_ok=True)

    def _get_user_file(self, user_id):
        return os.path.join(self.db_dir, f'ws_{user_id}.json')

    def create_project(self, user_id, title, description, tag="AI PROJECT"):
        file_path = self._get_user_file(user_id)
        projects = []
        if os.path.exists(file_path):
            with open(file_path, 'r') as f: projects = json.load(f)
        
        project = {
            "id": f"proj_{int(time.time())}_{hash(title) % 10000}", 
            "title": title, 
            "description": description, 
            "tag": tag, 
            "progress": 0.1, 
            "last_active": "Just now",
            "status": "Initialized"
        }
        projects.insert(0, project)
        with open(file_path, 'w') as f: json.dump(projects, f)
        return project

    def delete_project(self, user_id, project_id):
        file_path = self._get_user_file(user_id)
        if not os.path.exists(file_path): return False
        with open(file_path, 'r') as f: projects = json.load(f)
        
        updated = [p for p in projects if p['id'] != project_id]
        with open(file_path, 'w') as f: json.dump(updated, f)
        return True

    def get_projects(self, user_id):
        file_path = self._get_user_file(user_id)
        if os.path.exists(file_path):
            with open(file_path, 'r') as f: return json.load(f)
        return []

    def get_suggestion(self, project_id, title, description):
        if not self.groq:
            return "No active neural link. Please check your API key."
        
        prompt = f"Given the project '{title}' with description '{description}', provide a one-sentence proactive suggestion for the next step in research or development. Focus on futuristic AI-driven advice."
        try:
            response = self.groq.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=60
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"Strategic analysis paused: {str(e)}"

workspace_manager = WorkspaceManager(groq_client)

# 8. Hybrid Authentication Endpoints
@app.post("/auth/google")
async def auth_google(data: dict):
    id_token_str = data.get("idToken")
    email = data.get("email")
    google_id = data.get("googleId")
    
    # Verify Token if provided (Production Mode)
    if id_token_str:
        try:
            client_id = os.environ.get("GOOGLE_CLIENT_ID")
            idinfo = id_token.verify_oauth2_token(id_token_str, google_requests.Request(), client_id)
            email = idinfo['email']
            google_id = idinfo['sub']
        except Exception as e:
            raise HTTPException(401, f"Google Verification Failed: {str(e)}")

    if not email: raise HTTPException(400, "Identity required")
    
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    
    if not user:
        db.close()
        return {"status": "needs_password", "email": email, "googleId": google_id}
    
    token = AuthManager.create_access_token({"sub": str(user.id)})
    username = user.username
    db.close()
    return {"status": "success", "token": token, "username": username}

def validate_password(password: str):
    if len(password) < 8:
        raise HTTPException(400, "Password must be at least 8 characters")
    if not any(c.isupper() for c in password):
        raise HTTPException(400, "Password must contain an uppercase letter")
    if not any(c.islower() for c in password):
        raise HTTPException(400, "Password must contain a lowercase letter")
    if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
        raise HTTPException(400, "Password must contain a special character")

@app.post("/auth/setup-password")
async def setup_password(data: dict):
    validate_password(data['password'])
    db = SessionLocal()
    user = User(
        email=data['email'], 
        google_id=data.get('googleId'), 
        username=data.get('username'), 
        password_hash=AuthManager.get_password_hash(data['password'])
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Initialize AURA Workspace in foreground
    workspace_manager.create_project(
        user_id=user.id,
        title="AI COMMAND CENTER",
        description="Primary neural workspace for mission control.",
        tag="MISSION CONTROL"
    )
    
    # Offload neural memory initialization to background to prevent timeout
    def init_memory_bg(uname):
        try:
            memory.store_fragment(f"Neural profile created for {uname} at {datetime.utcnow()}")
        except: pass
        
    Thread(target=init_memory_bg, args=(user.username,)).start()
    
    token = AuthManager.create_access_token({"sub": str(user.id)})
    db.close()
    return {"status": "success", "token": token, "username": user.username}

@app.post("/auth/refresh")
async def refresh_token(token: str = Header(None)):
    user_id = AuthManager.decode_token(token)
    if not user_id: raise HTTPException(401, "Session Expired")
    new_token = AuthManager.create_access_token({"sub": user_id})
    return {"token": new_token}

@app.post("/auth/login")
async def aura_login(data: dict):
    db = SessionLocal()
    user = db.query(User).filter(User.email == data['email']).first()
    if not user or not AuthManager.verify_password(data['password'], user.password_hash):
        db.close()
        raise HTTPException(401, "Invalid access key")
    
    user.last_login = datetime.utcnow()
    db.commit()
    
    token = AuthManager.create_access_token({"sub": str(user.id)})
    db.close()
    return {"status": "success", "token": token, "username": user.username}

# 9. Neural Core Endpoints
@app.get("/workspaces")
async def list_workspaces(token: str = Header(None)):
    user_id = "guest_user_aura"
    projects = workspace_manager.get_projects(user_id)
    if not projects:
        workspace_manager.create_project(
            user_id=user_id,
            title="AURA NEURAL HUB",
            description="Guest mission control center.",
            tag="GUEST ACCESS"
        )
        projects = workspace_manager.get_projects(user_id)
    return projects

@app.post("/workspaces")
async def create_workspace(data: dict, token: str = Header(None)):
    user_id = "guest_user_aura"
    project = workspace_manager.create_project(
        user_id, 
        data.get('title', 'New Project'), 
        data.get('description', '')
    )
    return project

@app.delete("/workspaces/{project_id}")
async def delete_workspace(project_id: str, token: str = Header(None)):
    user_id = "guest_user_aura"
    success = workspace_manager.delete_project(user_id, project_id)
    if not success: raise HTTPException(404, "Project not found")
    return {"status": "success"}

@app.get("/workspaces/{project_id}/suggest")
async def get_workspace_suggestion(project_id: str, token: str = Header(None)):
    user_id = "guest_user_aura"
    projects = workspace_manager.get_projects(user_id)
    project = next((p for p in projects if p['id'] == project_id), None)
    if not project: raise HTTPException(404, "Project not found")
    
    suggestion = workspace_manager.get_suggestion(project_id, project['title'], project['description'])
    return {"suggestion": suggestion}

@app.get("/chats")
async def list_chats(token: str = Header(None), project_id: str = None):
    # BYPASS AUTH FOR TEST MODE
    user_id = "guest_user_aura"
    return chat_manager.get_user_chats(user_id, project_id)

@app.get("/chats/{conv_id}")
async def get_history(conv_id: str, token: str = Header(None)):
    return chat_manager.get_messages(conv_id)

@app.websocket("/chat")
async def secured_chat(websocket: WebSocket):
    await websocket.accept()
    try:
        user_id = "guest_user_aura" 
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            prompt = msg.get("prompt", "")
            conv_id = msg.get("conversationId", "default")
            project_id = msg.get("projectId", "global")
            
            chat_manager.save_message(user_id, conv_id, project_id, "user", prompt)
            
            full_reply = ""
            buffer = ""
            for chunk in engine.generate_stream(prompt, msg.get("history", [])):
                full_reply += chunk
                buffer += chunk
                if len(buffer) > 10 or "\n" in buffer:
                    await websocket.send_text(json.dumps({"type": "chunk", "content": buffer}))
                    buffer = ""
            
            if buffer:
                await websocket.send_text(json.dumps({"type": "chunk", "content": buffer}))
            
            chat_manager.save_message(user_id, conv_id, project_id, "assistant", full_reply)
            await websocket.send_text(json.dumps({"done": True}))

    except Exception as e:
        print(f"WS Chat Error: {e}")
        try:
            await websocket.send_text(json.dumps({
                "type": "chunk", 
                "content": f"\n[Neural Link Error: {str(e)}]"
            }))
            await websocket.send_text(json.dumps({"done": True}))
        except: pass

@app.websocket("/research")
async def research_socket(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            prompt = msg.get("prompt", "")
            category = msg.get("category", "Web")
            
            # 1. Search Phase
            await websocket.send_text(json.dumps({"type": "status", "content": "Scanning Neural Web..."}))
            from agent_plugins.search_agent import ResearchAgent
            researcher = ResearchAgent()
            
            search_query = prompt
            if category == "GitHub": search_query += " site:github.com"
            elif category == "Academic": search_query += " research papers journals"
            
            raw_results = researcher.ddgs.text(search_query, max_results=5)
            sources = [r['href'] for r in raw_results]
            snippets = [f"Source: {r['title']}\nSnippet: {r['body']}" for r in raw_results]
            
            await websocket.send_text(json.dumps({"type": "sources", "content": sources}))
            
            # 2. Synthesis Phase
            await websocket.send_text(json.dumps({"type": "status", "content": "Synthesizing Intelligence..."}))
            
            summary_prompt = f"Synthesize the following search results into a concise research report for the query: '{prompt}'. Use markdown. Results:\n\n" + "\n\n".join(snippets)
            
            if groq_client:
                response = groq_client.chat.completions.create(
                    model="llama-3.1-8b-instant",
                    messages=[{"role": "user", "content": summary_prompt}],
                    stream=True
                )
                for chunk in response:
                    if chunk.choices and chunk.choices[0].delta.content:
                        await websocket.send_text(json.dumps({"type": "synthesis", "content": chunk.choices[0].delta.content}))
            else:
                await websocket.send_text(json.dumps({"type": "synthesis", "content": "Neural Link Offline. Partial data displayed."}))

            # 3. Correlation Phase
            await websocket.send_text(json.dumps({"type": "status", "content": "Mapping Visual Correlations..."}))
            correlations = []
            for i, r in enumerate(raw_results[:4]):
                correlations.append({"topic": r['title'][:20], "strength": 0.5 + (i * 0.1)})
            
            await websocket.send_text(json.dumps({"type": "correlation", "content": correlations}))
            await websocket.send_text(json.dumps({"done": True}))
            
    except Exception as e:
        print(f"WS Research Error: {e}")
        try:
            await websocket.send_text(json.dumps({"type": "status", "content": f"Research Disrupted: {str(e)}"}))
            await websocket.send_text(json.dumps({"done": True}))
        except: pass

@app.get("/neural/reset")
async def reset_memory():
    """Wipe all neural memory and caches for a fresh restart."""
    import shutil
    try:
        if os.path.exists("./memory"):
            shutil.rmtree("./memory")
        os.makedirs("./memory", exist_ok=True)
        return {"status": "success", "message": "Neural Memory Wiped Successfully. Restarting core services."}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/cricket/ipl")
async def get_ipl_scores():
    """Fetch live IPL 2026 scores using neural research."""
    try:
        from agent_plugins.search_agent import ResearchAgent
        researcher = ResearchAgent()
        # Specific search for 2026 season
        score_data = researcher.search_live("IPL 2026 match live score today and schedule", max_results=3)
        return {"status": "success", "data": score_data}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/neural/test-groq")
async def test_groq():
    """Test the Groq connection and return results."""
    if not groq_client:
        return {"status": "error", "message": "GROQ_API_KEY is missing in environment variables."}
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": "hello"}],
            max_tokens=5
        )
        return {"status": "success", "message": "Neural Link Stable", "response": response.choices[0].message.content}
    except Exception as e:
        return {"status": "error", "message": f"Groq Connection Failed: {str(e)}"}

@app.get("/")
async def health(): 
    return {
        "status": "AURA OS Online", 
        "neural_link": "Stable" if groq_client else "Offline",
        "version": "2.2.0-PROD"
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
