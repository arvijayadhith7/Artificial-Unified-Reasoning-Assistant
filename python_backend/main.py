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
import asyncio
import logging
from typing import List, Dict, Any
from bs4 import BeautifulSoup
from groq import Groq as GroqClient, AsyncGroq
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

# 2. Realtime Data Ingestion Cluster (Embedded)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("IngestionCluster")

class RealtimeIngestionCluster:
    def __init__(self):
        self.intelligence_cache: Dict[str, Any] = {}
        self.is_running = False
        self.topics = ["IPL 2026 Live Scores", "AI Technology News", "Global Market Trends"]
        
    async def start(self):
        """Starts the realtime ingestion loop."""
        if self.is_running: return
        self.is_running = True
        logger.info("Neural Ingestion Cluster Activated.")
        asyncio.create_task(self._ingestion_loop())

    async def _ingestion_loop(self):
        while self.is_running:
            try:
                from agent_plugins.search_agent import ResearchAgent
                agent = ResearchAgent()
                for topic in self.topics:
                    logger.info(f"Ingesting live intelligence for: {topic}")
                    results = await agent.search_live_async(topic)
                    self.intelligence_cache[topic] = {
                        "data": results,
                        "timestamp": time.time(),
                        "summary": results[:500] + "..." if len(results) > 500 else results
                    }
                    await asyncio.sleep(5) # Throttling
                await asyncio.sleep(300) # Global sync every 5m
            except Exception as e:
                logger.error(f"Ingestion Error: {e}")
                await asyncio.sleep(60)

    def query(self, query: str) -> List[Dict[str, Any]]:
        """Returns relevant intelligence from the cluster."""
        relevant_data = []
        query_lower = query.lower()
        for topic, info in self.intelligence_cache.items():
            if any(word in topic.lower() for word in query_lower.split()):
                relevant_data.append({
                    "topic": topic, "intelligence": info["data"],
                    "freshness": f"{int(time.time() - info['timestamp'])}s ago"
                })
        return relevant_data

ingestion_cluster = RealtimeIngestionCluster()

@app.on_event("startup")
async def startup_event():
    def boot_sequence():
        print("NEURAL BOOT: Initializing Memory and Databases...")
        try:
            Base.metadata.create_all(bind=engine)
            print("NEURAL BOOT: Systems Synchronized.")
        except Exception as e:
            print(f"BOOT ERROR: {e}")
            
    Thread(target=boot_sequence).start()
    await ingestion_cluster.start()

# 3. Database Setup
groq_key = os.environ.get("GROQ_API_KEY")
groq_client = GroqClient(api_key=groq_key) if groq_key else None
async_groq_client = AsyncGroq(api_key=groq_key) if groq_key else None

class NeuralMemory:
    def __init__(self, path):
        self.path = path
        self._client = None
        self._collection = None
        self._rag = None

    @property
    def client(self):
        if self._client is None:
            print("NEURAL BOOT: Initializing ChromaDB Memory Vault...")
            self._client = chromadb.PersistentClient(path=self.path)
            self._collection = self._client.get_or_create_collection(name="aura_memory_vault")
            from agent_plugins.rag_advanced import AdvancedRAG
            self._rag = AdvancedRAG(self._collection)
        return self._client

    def retrieve_context(self, query, project_id=None, top_k=3):
        try:
            _ = self.client # Ensure init
            results = self._rag.hybrid_search(query, top_k=top_k)
            return "\nRELEVANT NEURAL MEMORY:\n" + "\n".join(results) if results else ""
        except Exception as e:
            print(f"Memory Retrieval Error: {e}")
            return ""

    def store_fragment(self, text, project_id="global"):
        try:
            _ = self.client # Ensure init
            self._rag.add_intelligence(text)
        except Exception as e:
            print(f"Memory Storage Error: {e}")

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
        pass

    def _sanitize_history(self, history):
        sanitized = []
        last_role = None
        
        # 1. First sanitize and clean roles, iterating from oldest to newest
        for msg in history:
            role = "assistant" if msg.get("role") in ["model", "assistant"] else "user"
            content = msg.get("content", "")
            if role == last_role: continue
            sanitized.append({"role": role, "content": content})
            last_role = role
            
        # 2. Implement sliding window: keep only the most recent 10 messages to save context/tokens
        if len(sanitized) > 10:
            sanitized = sanitized[-10:]
            
        # 3. Double-check character budget (8000 chars limit = ~2000 tokens)
        # We build backwards to ensure the newest messages are preserved if budget is exceeded
        final_history = []
        char_count = 0
        for msg in reversed(sanitized):
            msg_len = len(msg.get("content", ""))
            if char_count + msg_len > 8000:
                break # Stop adding older messages once budget is exhausted
            final_history.insert(0, msg)
            char_count += msg_len
            
        return final_history

    async def generate_stream(self, prompt, history):
        if not async_groq_client:
            yield "AURA Error: Neural Link Offline. Please check your GROQ_API_KEY."
            return

        # Instant Casual Greeting Bypass (Zero-latency, 100% human response)
        clean_p = prompt.strip().lower().rstrip("?").rstrip("!").rstrip(".")
        if clean_p in ["hi", "hello", "hey", "yo", "hola", "greetings", "good morning", "good afternoon", "good evening"]:
            yield "Hey! 👋 What can I help you with today?"
            return

        print(f"NEURAL INFERENCE: Processing prompt asynchronously...")
        
        # 1. NEURAL RESEARCH GATEWAY (Smart Intent Detection & Conversational Query Expansion)
        research_context = ""
        is_research_needed = any(k in prompt.lower() for k in [
            "score", "ipl", "news", "today", "weather", "match", "latest", "cricket", 
            "who is", "what is", "how is", "price", "stock", "search", "update",
            "current", "now", "live", "results", "scheduled", "vs", "who won",
            "standing", "points", "ranking", "winner", "tomorrow", "tonight", "happening"
        ])
        
        search_query = prompt
        if history and not is_research_needed:
            is_followup_search = any(k in prompt.lower() for k in [
                "which", "who", "what", "where", "how", "why", "best", "compare", "latest", "details"
            ]) or len(prompt.split()) > 3
            
            if is_followup_search:
                try:
                    chat_history_str = "\n".join([f"{m.get('role', 'user').upper()}: {m.get('content', '')}" for m in history[-3:]])
                    intent_prompt = f"""Given the following chat history and a follow-up query, determine if the user's query requires current web, real-time, or temporal information.
If yes, generate an optimized Google/DuckDuckGo search query.
If no, respond with 'NO_SEARCH'.

CHAT HISTORY:
{chat_history_str}

FOLLOW-UP QUERY:
{prompt}

RESPONSE FORMAT: Output ONLY the optimized search query or NO_SEARCH, nothing else."""
                    
                    intent_res = await async_groq_client.chat.completions.create(
                        model="llama-3.1-8b-instant",
                        messages=[{"role": "user", "content": intent_prompt}],
                        max_tokens=30,
                        temperature=0.0
                    )
                    expanded = intent_res.choices[0].message.content.strip()
                    if "NO_SEARCH" not in expanded:
                        is_research_needed = True
                        search_query = expanded.replace('"', '')
                        print(f"NEURAL INTENT: Query expanded to '{search_query}'")
                except Exception as ex:
                    print(f"Intent expansion failed: {ex}")

        if is_research_needed:
            try:
                from agent_plugins.search_agent import ResearchAgent
                if not hasattr(self, '_researcher'):
                    self._researcher = ResearchAgent()
                
                raw_research = await self._researcher.search_live_async(search_query, max_results=4)
                research_context = "\nLIVE NEURAL DATA GATHERED:\n" + raw_research
            except Exception as e:
                print(f"Research Gateway Async Error: {e}")

        # 2. Memory Context (Project-Specific)
        project_id = history[-1].get("project_id", "global") if history else "global"
        memory_context = memory.retrieve_context(prompt, project_id=project_id)
        
        # 3. Workspace Blueprint (Fetch Title/Description/Blueprint)
        workspace_title = "AURA GLOBAL"
        workspace_instructions = "General Intelligence Mode"
        workspace_blueprint = ""
        try:
            user_workspaces = workspace_manager.get_projects("guest_user_aura")
            active_ws = next((w for w in user_workspaces if w['id'] == project_id), None)
            if active_ws:
                workspace_title = active_ws.get('title', workspace_title)
                workspace_instructions = active_ws.get('description', workspace_instructions)
                if active_ws.get('blueprint'):
                    workspace_blueprint = f"\nPROJECT BLUEPRINT & ROADMAP:\n{json.dumps(active_ws['blueprint'])}"
        except: pass

        # 4. Master System Prompt — Core Conversation Behavior Controller
        common_instructions = """
        CORE BEHAVIOR RULES (STRICTLY ENFORCED):
        1. Speak naturally like a warm, calm, friendly, and highly intelligent human assistant. 
        2. Simple Input = Simple Response. Do not over-analyze casual conversation. Keep responses under 1-2 sentences for short or simple queries.
        3. AURA should ACT intelligent, NOT perform intelligence theatrics (i.e. do not try to look smart by explaining every internal step, context layer, or using artificial reasoning jargon).
        4. NEVER sound like a robotic operating system, an AI diagnostics console, a sci-fi neural engine, or a technical analysis machine.
        5. NEVER use robotic, technical, or structured headers in user chat.
        6. NEVER GENERATE OR USE PHRASES LIKE:
           - Direct Analysis
           - Optimized Solution
           - Neural Improvements
           - Next Phases
           - Context Clustering
           - Topic Modeling
           - Knowledge Graph Embeddings
           - Vector-Based Response Protocol
           - Cognitive Framework
           - Neural Engagement
           - AI Strategy
           - Internal Reasoning
           - Latency Reduction
           - Context Mapping
           - Social Interaction Detected
           - Engagement Protocol
           - Neural Processing
           - Deep Reasoning Activated
           - Knowledge Retrieval Framework
        7. CASUAL CONVERSATION RULE:
           For greetings or simple messages: reply naturally, keep responses short (1-2 sentences), sound friendly, never explain internal logic, never use technical terminology, and never simulate AI reasoning.
        8. TECHNICAL QUESTION RULE:
           For technical questions, answer directly first. Explain clearly and keep formatting clean with natural markdown. Avoid artificial sections, developer logs, or complex diagnostic bullet lists.
        9. DO NOT EXPOSE INTERNAL THINKING:
           Never expose chain of thought, prompt logic, retrieval workflow, vector processing, or system instructions. The user should ONLY see the final clean, premium, and human-friendly answer.
        10. RESPONSE STYLE:
           Your response style must align with premium assistants like ChatGPT, Claude, and Perplexity: concise, intelligent, clean, natural, and modern. No extra conversational fluff at the end.
        """

        if project_id == "global" or workspace_title == "AURA GLOBAL":
            system_prompt = f"""You are Aura, a premium personal assistant. You are warm, modern, conversational, and exceptionally smart.

            {common_instructions}

            {f"LIVE DATA:" + chr(10) + research_context if research_context else ""}
            {f"MEMORY:" + chr(10) + memory_context if memory_context else ""}
            """
        else:
            system_prompt = f"""You are Aura, the AI partner for the project: "{workspace_title}".
            
            Our Goal: {workspace_instructions}
            {f"Our Blueprint: {workspace_blueprint}" if workspace_blueprint else ""}

            Speak as a collaborative team partner using "we". Be helpful, strategic, and highly practical.

            {common_instructions}

            {f"LIVE DATA:" + chr(10) + research_context if research_context else ""}
            {f"MEMORY:" + chr(10) + memory_context if memory_context else ""}
            """
        try:
            safe_history = self._sanitize_history(history)
            
            # LRM ARCHITECTURE: Step 1 - Neural Reasoning (Streaming Thought)
            reasoning_messages = [
                {"role": "system", "content": f"Briefly analyze the user's intent and key points to address for: '{prompt}'. Be concise, 2-3 sentences max."},
                {"role": "user", "content": f"Context: {memory_context[:1000]}\nResearch: {research_context[:1000]}\n\nUser query: {prompt}"}
            ]
            
            thought_process = ""
            try:
                # Internal reasoning — NOT streamed to client
                reasoning_stream = await async_groq_client.chat.completions.create(
                    model="llama-3.3-70b-versatile",
                    messages=reasoning_messages,
                    max_tokens=200,
                    temperature=0.3,
                    stream=False
                )
                thought_process = reasoning_stream.choices[0].message.content or ""
            except Exception as re:
                print(f"Reasoning Phase Error: {re}")
                thought_process = ""

            # Step 2 — Draft response using fast model
            messages = [{"role": "system", "content": system_prompt + (f"\nInternal notes: {thought_process}" if thought_process else "")}] + safe_history + [{"role": "user", "content": prompt}]
            
            draft_response = ""
            try:
                raw_response = await async_groq_client.chat.completions.create(
                    model="llama-3.1-8b-instant", 
                    messages=messages, 
                    stream=False, 
                    temperature=0.7,
                    max_tokens=2048
                )
                draft_response = raw_response.choices[0].message.content
            except Exception as de:
                print(f"Draft Synthesis Error: {de}")
                draft_response = "Sorry, I ran into an issue generating a response. Could you try again?"

            # Step 3 — Polish and stream to client
            try:
                from agent_plugins.refiner_agent import RefinerAgent
                if not hasattr(self, '_refiner'):
                    self._refiner = RefinerAgent(async_groq_client)
                
                async for polish_chunk in self._refiner.refine_stream_async(draft_response, context=f"Project: {workspace_title}. Context: {memory_context[:500]}"):
                    yield polish_chunk
            except Exception as pe:
                print(f"Refinement Phase Error: {pe}")
                yield draft_response
        except Exception as e:
            print(f"Inference Error: {e}")
            yield f"Sorry, something went wrong. Please try again."

inference_core = InferenceEngine()

# 6. Chat History Manager
class ChatHistoryManager:
    def __init__(self):
        self.db_dir = './memory/chats'
        os.makedirs(self.db_dir, exist_ok=True)

    def _get_user_conv_file(self, user_id):
        return os.path.join(self.db_dir, f'convs_{user_id}.json')

    def save_message(self, user_id, conv_id, project_id, role, content, thought=None):
        msg_file = os.path.join(self.db_dir, f'{conv_id}.json')
        messages = []
        if os.path.exists(msg_file):
            with open(msg_file, 'r', encoding='utf-8') as f: messages = json.load(f)
        
        msg_entry = {"role": role, "content": content, "timestamp": str(time.time())}
        if thought:
            msg_entry["thought"] = thought
        messages.append(msg_entry)
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

    def generate_onboarding_questions(self, title, category="General"):
        """Generate 10 dynamic, category-specific questions for project architecture."""
        if not self.groq: return []
        prompt = f"""Generate 10 highly specific architectural and product questions for a new project titled '{title}' in category '{category}'.
        The questions should cover: Purpose, User Persona, Monetization, Tech Complexity, Scalability, and AI Opportunities.
        Return ONLY a JSON list of objects: [{{"id": 1, "question": "...", "options": ["...", "..."]}}]"""
        try:
            response = self.groq.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"}
            )
            data = json.loads(response.choices[0].message.content)
            return data.get("questions", [])[:10]
        except: return []

    def perform_project_analysis(self, title, answers):
        """Analyze project onboarding data to generate a roadmap and tech blueprint."""
        if not self.groq: return {}
        prompt = f"""Act as an AI Product Manager and Technical Architect. Analyze this project: '{title}' based on these user answers: {json.dumps(answers)}.
        Generate a comprehensive project blueprint including:
        1. Summary
        2. MVP Roadmap (Phase 1, 2, 3)
        3. Tech Stack Recommendations
        4. Architecture Strategy
        5. Monetization Ideas
        6. Feature Backlog
        Return ONLY a JSON object."""
        try:
            response = self.groq.chat.completions.create(
                model="llama-3.1-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"}
            )
            return json.loads(response.choices[0].message.content)
        except: return {"error": "Analysis engine timed out."}

    def create_project(self, user_id, title, description, blueprint=None, tag="AI PROJECT"):
        file_path = self._get_user_file(user_id)
        projects = []
        if os.path.exists(file_path):
            with open(file_path, 'r') as f: projects = json.load(f)
        
        project = {
            "id": f"proj_{int(time.time())}_{hash(title) % 10000}", 
            "title": title, 
            "description": description, 
            "blueprint": blueprint or {},
            "tag": tag, 
            "progress": 0.1, 
            "last_active": "Just now",
            "status": "Architecting" if blueprint else "Initialized",
            "priority": "MEDIUM",
            "ai_summary": "Neural initialization complete. Ready for architectural mapping.",
            "suggestions": ["Define core features", "Select tech stack", "Map user journeys"]
        }
        projects.insert(0, project)
        with open(file_path, 'w') as f: json.dump(projects, f)
        return project

    def get_projects(self, user_id):
        file_path = self._get_user_file(user_id)
        if os.path.exists(file_path):
            with open(file_path, 'r') as f: return json.load(f)
        return []

    def delete_project(self, user_id, project_id):
        file_path = self._get_user_file(user_id)
        if not os.path.exists(file_path): return False
        try:
            with open(file_path, 'r') as f: projects = json.load(f)
            updated_projects = [p for p in projects if p['id'] != project_id]
            if len(projects) == len(updated_projects): return False
            with open(file_path, 'w') as f: json.dump(updated_projects, f)
            return True
        except: return False

    def get_suggestion(self, project_id, title, description):
        if not self.groq: return "Neural connection offline. Define core feature sets next."
        prompt = f"""Act as an AI Strategist and Chief Architect. For the project '{title}' with description '{description}', generate a single, highly impact-oriented strategic suggestion (1-2 sentences max) to accelerate MVP development or optimize architecture. Return ONLY the suggestion text, no conversational intro or filler."""
        try:
            response = self.groq.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=100
            )
            return response.choices[0].message.content.strip()
        except:
            return "Map out the schema layers, setup local DB caching, and configure environment boundaries first."

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
    # BYPASS AUTH FOR TEST MODE
    user_id = "guest_user_aura"
    projects = workspace_manager.get_projects(user_id)
    return projects

@app.get("/workspaces/onboarding")
async def get_onboarding(title: str, category: str = "General", token: str = Header(None)):
    questions = workspace_manager.generate_onboarding_questions(title, category)
    return {"questions": questions}

@app.post("/workspaces/analyze")
async def analyze_project(data: dict, token: str = Header(None)):
    analysis = workspace_manager.perform_project_analysis(data['title'], data['answers'])
    return analysis

@app.post("/workspaces")
async def create_workspace(data: dict, token: str = Header(None)):
    user_id = "guest_user_aura"
    project = workspace_manager.create_project(
        user_id, 
        data.get('title', 'New Project'), 
        data.get('description', ''),
        blueprint=data.get('blueprint'),
        tag=data.get('tag', 'AI PROJECT')
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
            # Store fragment in Neural Memory for long-term recall
            memory.store_fragment(f"User Question in {project_id}: {prompt}")
            
            full_reply = ""
            accumulated_thought = ""
            buffer = ""
            is_thinking = False
            async for chunk in inference_core.generate_stream(prompt, msg.get("history", [])):
                if "<thought>" in chunk:
                    is_thinking = True
                    continue
                if "</thought>" in chunk:
                    is_thinking = False
                    continue
                if "<refining>" in chunk:
                    await websocket.send_text(json.dumps({"type": "status", "content": "NEURAL REFINEMENT IN PROGRESS..."}))
                    continue
                if "</refining>" in chunk:
                    await websocket.send_text(json.dumps({"type": "status", "content": "REFINEMENT COMPLETE."}))
                    continue
                
                if is_thinking:
                    accumulated_thought += chunk
                    await websocket.send_text(json.dumps({"type": "thought", "content": chunk}))
                    continue
                
                full_reply += chunk
                buffer += chunk
                if len(buffer) > 10 or "\n" in buffer:
                    await websocket.send_text(json.dumps({"type": "chunk", "content": buffer}))
                    buffer = ""
            
            if buffer:
                await websocket.send_text(json.dumps({"type": "chunk", "content": buffer}))
            
            chat_manager.save_message(user_id, conv_id, project_id, "assistant", full_reply, thought=accumulated_thought)
            # Store AI response fragments for continuity
            if len(full_reply) > 50:
                memory.store_fragment(f"Aura Strategic Advice: {full_reply[:500]}...")
                
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

@app.post("/neural/refine")
async def refine_response(data: dict, token: str = Header(None)):
    """Apply a high-fidelity 'Neural Polish' to a draft response."""
    original_text = data.get("text", "")
    context = data.get("context", "General strategic advice.")
    
    refine_prompt = f"""Act as a World-Class AI Strategist and Editor. Fine-tune the following draft response to make it more professional, strategic, and high-fidelity.
    
    CONTEXT: {context}
    DRAFT: {original_text}
    
    RULES:
    1. Maintain the original meaning but upgrade the vocabulary.
    2. Use a "Neural OS" tone (crisp, authoritative, futuristic).
    3. Ensure it is scannable (use bolding and structured bullets).
    4. Add a proactive "Strategic Insight" at the end.
    
    REFINED RESPONSE:"""
    
    try:
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": refine_prompt}],
            temperature=0.3,
            max_tokens=1024
        )
        return {"status": "success", "refined": response.choices[0].message.content}
    except Exception as e:
        raise HTTPException(500, f"Refinement Engine Error: {str(e)}")

@app.websocket("/research")
async def research_socket(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            prompt = msg.get("prompt", "")
            category = msg.get("category", "Web")
            
            # 1. SEARCH PHASE
            await websocket.send_text(json.dumps({"type": "status", "content": "Scanning Neural Web & Verifying Sources..."}))
            from agent_plugins.search_agent import ResearchAgent
            researcher = ResearchAgent()
            
            search_query = prompt
            if category == "GitHub": search_query += " site:github.com"
            elif category == "Academic": search_query += " research papers journals"
            
            research_data = researcher.search_live(search_query, max_results=6)
            
            if "NO_DATA" in research_data:
                await websocket.send_text(json.dumps({
                    "type": "status", 
                    "content": "Live Neural Data currently restricted by web gateways. Utilizing internal knowledge base..."
                }))
                research_data = "No live research data available. Use your internal knowledge."
            else:
                await websocket.send_text(json.dumps({"type": "status", "content": "Neural Sources Integrated. Initializing Synthesis..."}))

            await websocket.send_text(json.dumps({"type": "sources", "content": ["Search Results Synchronized"]}))
            
            # 2. AI REASONING & STRUCTURED SYNTHESIS PHASE
            await websocket.send_text(json.dumps({"type": "status", "content": "AURA is synthesizing structured intelligence..."}))
            
            # Truncate research data to prevent context overflow
            safe_research_data = research_data[:10000] if research_data else "No data available."
            
            reasoning_prompt = f"""You are the AURA Research Engine. Synthesize the following data into a HIGH-FIDELITY STRUCTURED JSON response.
            
QUERY: {prompt}
CATEGORY: {category}
DATA CLUSTERS:
{safe_research_data}

RULES:
- Return ONLY a JSON object.
- Provide deep technical analysis.
- Key findings must be actionable.
- References must be strictly from the provided data.
- Detect future trends and community insights.

JSON SCHEMA:
{{
  "query": "{prompt}",
  "title": "Title of Research",
  "summary": "Concise high-level summary",
  "key_findings": ["Finding 1", "Finding 2"],
  "technical_analysis": "Deep dive into the tech/mechanics",
  "statistics": ["Data point 1", "Data point 2"],
  "community_insights": ["Reddit/GitHub sentiment/trends"],
  "comparisons": ["A vs B analysis"],
  "future_scope": "Predicted trajectory",
  "references": [{{ "title": "", "url": "", "source": "", "published_date": "" }}]
}}"""
            
            if groq_client:
                try:
                    response = groq_client.chat.completions.create(
                        model="llama-3.1-8b-instant",
                        messages=[{"role": "user", "content": reasoning_prompt}],
                        response_format={"type": "json_object"}
                    )
                    structured_data = json.loads(response.choices[0].message.content)
                    await websocket.send_text(json.dumps({"type": "synthesis", "content": structured_data}))
                except Exception as je:
                    print(f"Research Synthesis Error: {je}")
                    await websocket.send_text(json.dumps({"type": "status", "content": "Synthesis Gateways overloaded. Generating raw summary..."}))
                    # Fallback to simple completion if JSON fails
                    raw_fallback = groq_client.chat.completions.create(
                        model="llama-3.1-8b-instant",
                        messages=[{"role": "user", "content": f"Summarize this research data for: {prompt}\n\nData: {safe_research_data[:2000]}"}]
                    )
                    await websocket.send_text(json.dumps({"type": "synthesis", "content": raw_fallback.choices[0].message.content}))
            else:
                await websocket.send_text(json.dumps({"type": "status", "content": "Neural Link Offline."}))

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
    """Fetch live IPL scores and synthesize into premium AI intelligence using Ingestion Cluster."""
    try:
        # Check ingestion cluster first for live data
        cached_intel = ingestion_cluster.query("IPL 2026 Live Scores")
        
        if cached_intel:
            raw_data = cached_intel[0]["intelligence"]
        else:
            from agent_plugins.search_agent import ResearchAgent
            researcher = ResearchAgent()
            raw_data = researcher.get_cricket_scores()
        
        if not groq_client:
            return {"status": "success", "data": {"error": "Neural Link Offline. Basic data only.", "raw": raw_data}}

        intel_prompt = f"""Act as a World-Class Cricket AI Analyst. 
        Synthesize the following live search data into a HIGH-FIDELITY STRUCTURED JSON for a premium AI OS dashboard.
        
        SEARCH DATA:
        {raw_data}
        
        REQUIRED JSON SCHEMA:
        {{
          "match_hero": {{
            "teams": ["Team A", "Team B"],
            "score": "Team A 180/5 (20) vs Team B 150/2 (15.2)",
            "status": "Team B needs 31 runs in 28 balls",
            "run_rate": "9.2",
            "required_rr": "6.6",
            "momentum_animation": "pulse_blue"
          }},
          "win_probability": {{ "team_a": 45, "team_b": 55 }},
          "ai_insights": [
            "Momentum shift detected in middle overs.",
            "Pressure mounting on bowlers due to dew factor.",
            "Predictive analysis: Team B has 80% chance if they keep wickets."
          ],
          "smart_timeline": [
            {{ "time": "15.2", "event": "Boundary", "desc": "Beautiful cover drive by Kohli", "type": "FOUR" }},
            {{ "time": "14.5", "event": "Wicket", "desc": "Big blow for Team B", "type": "WICKET" }}
          ],
          "player_impact": [
            {{ "name": "Player X", "score": 92, "analysis": "Dominating the spin cluster." }},
            {{ "name": "Player Y", "score": 85, "analysis": "High economy but effective pressure." }}
          ],
          "momentum_graph": [10, 25, 40, 35, 50, 65, 60, 80]
        }}
        
        Return ONLY valid JSON. If no live match is found, provide a summary of the latest IPL news/points table in the same JSON format with status 'No Live Match'."""

        response = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": intel_prompt}],
            response_format={"type": "json_object"}
        )
        
        structured_intel = json.loads(response.choices[0].message.content)
        return {"status": "success", "data": structured_intel}

    except Exception as e:
        print(f"Cricket Intel Error: {e}")
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

from fastapi.responses import HTMLResponse

@app.get("/", response_class=HTMLResponse)
async def health(): 
    status_color = "#00f2ff" if groq_client else "#ff0055"
    return f"""
    <html>
        <head>
            <title>AURA NEURAL HUB</title>
            <style>
                body {{ background: #050505; color: white; font-family: 'Inter', sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; overflow: hidden; }}
                .hub {{ text-align: center; border: 1px solid #1a1a1a; padding: 40px; border-radius: 30px; background: rgba(255,255,255,0.02); backdrop-filter: blur(10px); box-shadow: 0 0 50px rgba(0,242,255,0.05); }}
                .pulse {{ width: 20px; height: 20px; background: {status_color}; border-radius: 50%; display: inline-block; box-shadow: 0 0 20px {status_color}; animation: pulse 2s infinite; }}
                h1 {{ letter-spacing: 5px; font-weight: 900; margin: 20px 0; }}
                .meta {{ color: #666; font-size: 12px; letter-spacing: 2px; }}
                @keyframes pulse {{ 0% {{ transform: scale(0.9); opacity: 0.7; }} 50% {{ transform: scale(1.1); opacity: 1; }} 100% {{ transform: scale(0.9); opacity: 0.7; }} }}
            </style>
        </head>
        <body>
            <div class="hub">
                <div class="pulse"></div>
                <h1>AURA NEURAL CORE</h1>
                <p class="meta">VERSION 2.7.5-PROD | STATUS: ONLINE</p>
                <p style="color: #444; font-size: 10px; margin-top: 20px;">Hugging Face Cloud Inference Active</p>
            </div>
        </body>
    </html>
    """

@app.get("/intelligence/search")
async def intelligence_search(query: str):
    """Real-time data ingestion search endpoint."""
    results = ingestion_cluster.query(query)
    if not results:
        from agent_plugins.search_agent import ResearchAgent
        agent = ResearchAgent()
        data = await agent.search_live_async(query)
        return [{"topic": query, "intelligence": data, "freshness": "live"}]
    return results

# ========================
# AURA ASSIST OVERLAY CORE
# ========================
@app.websocket("/assist/stream")
async def aura_assist_socket(websocket: WebSocket):
    await websocket.accept()
    print("AURA ASSIST: Overlay client context stream connected.")
    try:
        while True:
            raw_data = await websocket.receive_text()
            payload = json.loads(raw_data)
            
            if payload.get("event") == "screen_update" or payload.get("event") == "analyze":
                ui_metadata = payload.get("metadata", {})
                active_field = ui_metadata.get("active_field", {})
                field_val = active_field.get("value", "")
                field_type = active_field.get("type", "")
                lang = ui_metadata.get("language", "English")
                
                # 1. Proactive Validation Predictor (Bypasses LLM for 10ms speed)
                prediction = None
                if field_type == "email" and field_val and "@" not in field_val:
                    prediction = {
                        "English": "Ensure your email contains the '@' symbol.",
                        "Tamil": "மின்னஞ்சல் முகவரியில் '@' குறியீடு இருக்க வேண்டும்.",
                        "Hindi": "सुनिश्चित करें कि आपके ईमेल में '@' शामिल है।",
                        "Telugu": "మీ ఇమెయిల్ ఐడి లో '@' ఉండేలా చూసుకోండి.",
                        "Kannada": "ನಿಮ್ಮ ಇಮೇಲ್‌ನಲ್ಲಿ '@' ಸಂಕೇತವಿರುವುದನ್ನು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ."
                    }.get(lang, "Ensure your email contains the '@' symbol.")
                
                elif field_type == "password" and field_val and len(field_val) < 8:
                    prediction = {
                        "English": "Choose a password with 8 or more characters.",
                        "Tamil": "கடவுச்சொல் குறைந்தது 8 எழுத்துக்கள் இருக்க வேண்டும்.",
                        "Hindi": "कम से कम 8 वर्णों का पासवर्ड चुनें।",
                        "Telugu": "కనీసం 8 అక్షరాల పాస్‌వర్డ్ ఎంచుకోండి.",
                        "Kannada": "ಕನಿಷ್ಠ 8 ಅಕ್ಷರಗಳ ಪಾಸ್‌ವರ್ಡ್ ಆಯ್ಕೆಮಾಡಿ."
                    }.get(lang, "Choose a password with 8 or more characters.")
                
                # 2. Dynamic Llama Contextual Guidance Engine
                if not prediction:
                    app_name = ui_metadata.get("app_name", "Workspace")
                    field_label = active_field.get("label", "current field")
                    
                    assist_prompt = f"""You are Aura Assist, a premium real-time AI guidance overlay.
                    The user is filling out a form inside "{app_name}".
                    Active Field Label: "{field_label}"
                    Active Field Value: "{field_val}"
                    Target User Language: {lang}

                    Provide exactly ONE brief instruction (under 12 words) in {lang} telling the user exactly what to enter or do.
                    Be exceptionally warm, conversational, and direct. Avoid any robotic AI jargon.

                    INSTRUCTION:"""
                    
                    try:
                        resp = await async_groq_client.chat.completions.create(
                            model="llama-3.3-70b-versatile",
                            messages=[{"role": "user", "content": assist_prompt}],
                            temperature=0.3,
                            max_tokens=60
                        )
                        prediction = resp.choices[0].message.content.strip().strip('"')
                    except Exception as e:
                        print(f"Assist LLM Error: {e}")
                        prediction = f"Fill in the active field: {field_label}"

                await websocket.send_text(json.dumps({
                    "type": "guidance",
                    "instruction": prediction,
                    "active_field_id": active_field.get("id", "")
                }))
                
    except Exception as ws_err:
        print(f"AURA ASSIST: Connection closed ({ws_err})")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)
