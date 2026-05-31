# AURA Enterprise LLM Architecture

If AURA is expected to support **multiple concurrent users**, moving away from a tiny SLM-only architecture is reasonable. A stronger architecture is a **multi-tier LLM platform** with intelligent routing, caching, and fallbacks.

## Why the Current SLM Architecture Fails

If multiple users are causing failures, the bottleneck is usually:
* Single inference instance
* No request queue
* No load balancing
* Context windows becoming too large
* Memory leaks
* Blocking WebSocket requests
* Running inference on limited CPU resources

The problem is often infrastructure, not just model size.

---

## 10-Layer Architecture

```text
                Users
                   │
        ┌──────────┴──────────┐
        │   API Gateway       │
        └──────────┬──────────┘
                   │
          Request Router
                   │
 ┌─────────┬─────────┬─────────┬─────────┐
 │ Overlay │ Chat AI │ Research│ CRM AI │
 └────┬────┴────┬────┴────┬────┴────┬────┘
      │         │         │         │
      └─────────┴─────────┴─────────┘
                   │
           LLM Orchestrator
                   │
 ┌─────────────────┼─────────────────┐
 │                 │                 │
 NVIDIA NIM      Groq         Gemini/OpenAI
 Primary        Fallback        Fallback
                   │
             Vector Memory
                   │
         Tool & Agent Layer
```

---

### Layer 1: API Gateway
**Use:** FastAPI, Bun, Nginx
**Responsibilities:**
* Rate limiting
* User authentication
* Session management
* Request routing
* Streaming responses

---

### Layer 2: LLM Orchestrator
This becomes the "brain" of AURA.
**Responsibilities:**
* Determine task type
* Select best model
* Manage cost
* Handle failover
* Monitor latency

---

### Layer 3: Multi-Provider LLM Cluster
Instead of one model:
* **Primary:** NVIDIA NIM (Llama 3.3 70B, Llama Vision)
* **Secondary:** Groq (Llama 3.3 70B, DeepSeek, Mixtral)
* **Tertiary:** Gemini (Gemini 2.5 Flash, Gemini Pro)

Routing: `NVIDIA NIM → Groq → Gemini` (Automatic fallback).

---

### Layer 4: Context Pipeline
Instead of sending raw prompts:
```text
User Request → Memory Retrieval → File Context → Research Context → Current Chat → Prompt Builder → LLM
```

---

### Layer 5: Vector Memory
**Use:** ChromaDB, Qdrant, Weaviate
**Store:**
* Conversations
* Projects
* CRM records
* Research results
* Uploaded documents

---

### Layer 6: Specialized AI Services

#### Overlay AI
Fast contextual assistant.
`Overlay → OCR → Context Engine → LLM → Response`

#### Research AI
`Query → Web Search → Content Extraction → AI Synthesis → Report`

#### CRM AI
`Lead → Scoring → Insights → Recommendations`

---

### Layer 7: Streaming Engine
ChatGPT-style streaming.
`LLM → Token Stream → WebSocket → Frontend`
**Features:** Auto-scroll, Typing indicator, Partial rendering, Reconnect support.

---

### Layer 8: Background Workers
**Use:** Celery, Redis Queue, BullMQ
**Tasks:** OCR, PDF processing, Embeddings, Research crawling, CRM analytics.
Never run these on the main thread.

---

### Layer 9: File Intelligence Pipeline
`Upload → Parser → Chunking → Embeddings → Vector DB → LLM Analysis`
**Supported:** PDF, DOCX, XLSX, PPTX, Images, Code, ZIP projects.

---

### Layer 10: Overlay Intelligence
Instead of SLM:
`Screenshot → OCR → Context Extraction → Prompt Compression → NVIDIA Vision Model → Answer`
This gives better contextual help than a tiny local model.

---

## Scalability Goal

* **Concurrent Users:** 50–100+
* **Response Time:** 1–3 seconds
* **Streaming:** <300 ms first token
* **Availability:** 99.9%
* **Automatic Failover:** Yes

---

## Recommended Stack for AURA
* **Backend:** FastAPI, Bun, WebSocket
* **AI:** NVIDIA NIM (Primary), Groq (Secondary), Gemini (Fallback)
* **Memory:** ChromaDB or Qdrant
* **Queue:** Redis, Celery
* **Database:** PostgreSQL, SQLite (development)
* **Frontend:** Flutter, Next.js Web Portal
* **Overlay:** Android Accessibility + MediaProjection, Windows OCR + Active Window Detection
