# AURA Universal Overlay Assistant — Architecture

## Vision

AURA Overlay is a **realtime workflow copilot** — not a chatbot widget. It floats above every app and delivers contextual help without tab switching.

## Platform Matrix

| Platform | Runtime | UI | Context Sources |
|----------|---------|-----|-----------------|
| **Web** | `aura_web_portal/overlay/` | Bubble + Mini + Expanded | Browser selection, optional screen capture, `/system/active-window` |
| **Windows** | `desktop_overlay/` (Electron) | Dedicated always-on-top window | Win32 foreground window, local screenshot (PIL), clipboard |
| **Android** | `AuraForegroundService.kt` | `TYPE_APPLICATION_OVERLAY` | Accessibility tree, MediaProjection (optional) |

## Transport

| Endpoint | Purpose |
|----------|---------|
| `WS /overlay/chat` | Dedicated overlay SLM stream (primary for all overlays) |
| `POST /overlay/chat` | REST overlay fallback |
| `WS /chat` | Main AURA app chat only |
| `WS /assist/stream` | Proactive field guidance (short tips) |
| `GET /overlay/context` | Poll active context snapshot |
| `POST /overlay/context` | Push context from clients |

## Unified Sandbox Envelope

All clients send this inside `/chat` payloads:

```json
{
  "platform": "windows|android|web",
  "overlay_mode": true,
  "assistant_mode": "quick|tutor|copilot|research|focus",
  "active_app": "VS Code",
  "window_title": "main.py - AURA",
  "accessibility_text": "...",
  "screenshot": "local|data:image/jpeg;base64,...",
  "selected_text": "",
  "incognito": false,
  "persona": "warm-narrative",
  "search_strategy": "multi-tier"
}
```

**Conversation ID:** `aura_overlay` (unified across platforms)

## Context Pipeline

```
1. Detect active application (Win32 / Accessibility / Browser)
2. Capture visible context (OCR / accessibility text / screenshot)
3. Classify workflow (coding, editing, office, gaming, browsing)
4. Route model (SLM quick / LLM complex / Vision if screenshot)
5. Stream concise, actionable response (no chain-of-thought in overlay_mode)
```

## Assistant Modes

- **quick** — Instant short answers
- **tutor** — Step-by-step software guidance
- **copilot** — Workflow-aware task help
- **research** — Web search + synthesis
- **focus** — Minimal UI, no extras

## Privacy

- `incognito: true` — No message persistence
- App blacklist (settings)
- User-controlled screen/mic permissions
- Never store banking/password fields

## File Map

```
overlay_core/schema.json          — Message schema
overlay_core/overlay_client.js    — Shared JS client
python_backend/overlay_engine.py  — Context + routing engine
aura_web_portal/overlay/          — Web runtime
desktop_overlay/                  — Windows Electron shell
android/.../AuraForegroundService.kt — Android overlay
```
