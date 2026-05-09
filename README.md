# AURA (Artificial Unified Reasoning Assistant)

<div align="center">
  <img src="docs/images/logo.png" width="200" alt="AURA Logo">
  <h3>The Next Generation of Autonomous, High-Speed Intelligence</h3>
  <p><b>Unified Reasoning. Agentic Power. Lightning Speed.</b></p>
  <br />
</div>

---

## 🌟 Overview

**AURA** is a high-performance, enterprise-grade AI assistant platform built to bridge the gap between local intelligence and cloud power. Designed with a **Glassmorphism-inspired UI**, AURA leverages the extreme throughput of **Groq Cloud GPUs** to deliver near-instant reasoning while maintaining an autonomous local agentic framework.

Whether you are a developer seeking a Senior Architect's advice or a researcher synthesizing complex data, AURA adapts its reasoning engine to match your intent.

---

## 🔥 Key Features

- **⚡ Instant Reasoning:** Powered by **Groq Llama-3.3-70B**, delivering 200+ tokens/sec.
- **🧠 Intent-Aware Agents:** Automatic routing between specialized agents (Coding, Research, Empathy, General).
- **🛠️ Agentic Tools:** Built-in capabilities to read local files, execute Python scripts, and search the web.
- **📂 Contextual Memory:** SQLite-based vector memory system for long-term user context retention.
- **✨ Premium UI/UX:** A state-of-the-art Flutter interface featuring dark mode, glassmorphism, and smooth animations.

---

## 🛠️ Technical Stack

- **Frontend:** Flutter (Mobile - Android/iOS)
- **Engine:** Groq Versatile (Llama 3.3 70B) & Intel OpenVINO (Local)
- **Backend:** Node.js / Express Enterprise Pipeline
- **Inference Server:** Python / FastAPI / Transformers / Optimum Intel
- **Memory:** SQLite (Persistent) & ChromaDB (Vector)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Node.js v18+
- Python 3.10+ (for local inference)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/arvijayadhith7/Artificial-unified-reasoning-assistant--Aura-.git
   cd AURA
   ```

2. **Setup Backend:**
   ```bash
   cd backend
   npm install
   # Create a .env file and add your GROQ_API_KEY
   node server.js
   ```

3. **Run Mobile App:**
   ```bash
   # From project root
   flutter pub get
   flutter run
   ```

---

## 📐 Architecture

AURA operates on a **Unified Gateway Pattern**:
1. **The Client (Flutter)** sends real-time socket events.
2. **The Gateway (Node.js)** detects intent and routes the request.
3. **The Brain (Groq)** processes reasoning with extreme speed.
4. **The Agent (Python/Local)** executes physical tools and reads memory.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p>Built with ❤️ by the AURA Development Team</p>
</div>
