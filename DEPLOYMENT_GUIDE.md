# 🌌 AURA Cloud Deployment Guide

Follow these steps to move AURA from your local machine to the cloud.

---

## 1. Backend: Render (Node.js)
**URL**: [https://dashboard.render.com](https://dashboard.render.com)

1. **Create Web Service**: Connect your GitHub repository.
2. **Root Directory**: `llm APP/backend` (or your backend folder).
3. **Environment**: `Node`
4. **Build Command**: `npm install`
5. **Start Command**: `npm start`
6. **Environment Variables**:
   - `PORT`: `3000`
   - `GROQ_API_KEY`: `your_actual_key_here`
   - `SUPABASE_URL`: (Optional) If using memory.
   - `SUPABASE_KEY`: (Optional)

> **Note**: Once deployed, Render will give you a URL like `https://aura-backend.onrender.com`. **Copy this URL.**

---

## 2. Frontend: Vercel (Flutter Web)
**URL**: [https://vercel.com](https://vercel.com)

### A. Update Flutter Code
Open `lib/chat_service.dart` and update the connection URL to your **Render URL**:

```dart
// lib/chat_service.dart
void connect() {
  // Use your new Render URL here (Use wss:// for secure production)
  socket = io.io('https://aura-backend.onrender.com', io.OptionBuilder()
    .setTransports(['websocket'])
    .build());
}
```

### B. Build and Deploy
1. Run: `flutter build web --release`
2. Install Vercel CLI: `npm install -g vercel`
3. Run: `vercel deploy` inside the `build/web` folder, OR upload the `build/web` folder to a new Vercel project.

---

## 3. Important: CORS Update
In your `backend/server.js`, make sure your CORS settings allow the Vercel URL:

```javascript
// backend/server.js
const io = new Server(server, {
  cors: {
    origin: ["https://your-aura-app.vercel.app", "http://localhost:3000"],
    methods: ["GET", "POST"]
  }
});
```

---

## Summary of URLs
- **Live Frontend**: `https://aura-ai.vercel.app`
- **Live Backend**: `https://aura-backend.onrender.com`

Your app is now global! 🚀
