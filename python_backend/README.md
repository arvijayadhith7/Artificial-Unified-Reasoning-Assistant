---
title: AURA Neural Core
emoji: 🌌
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# AURA Neural Core Backend

Production-ready backend for the AURA Enterprise Assistant.

## Features
- **Neural Inference**: Powered by Groq (Llama 3.3).
- **Real-time Research**: High-fidelity search via Tavily AI with DDG fallback.
- **WebSocket Streaming**: Low-latency communication for mobile clients.
- **Hybrid Auth**: Google OAuth and Password-based security.

## Deployment Info
This space runs a FastAPI application inside a Docker container.

### Environment Variables Required
Configure these in the Space Settings:
- `GROQ_API_KEY`
- `TAVILY_API_KEY`
- `AURA_SECRET_KEY`
