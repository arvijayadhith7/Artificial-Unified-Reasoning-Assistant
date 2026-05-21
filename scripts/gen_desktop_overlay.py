from pathlib import Path

base = Path(r"d:\ANTIGRAVITY\llm APP\desktop_overlay")
tag = "div"

html_lines = [
    "<!DOCTYPE html>",
    '<html lang="en">',
    "<head>",
    '  <meta charset="UTF-8">',
    "  <title>AURA Overlay</title>",
    '  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">',
    '  <link rel="stylesheet" href="overlay.css">',
    "</head>",
    "<body>",
    f'  <{tag} id="aura-overlay-bubble" class="aura-overlay-bubble" title="AURA Assistant">',
    f'    <{tag} class="overlay-bubble-core"></{tag}>',
    f"  </{tag}>",
    f'  <{tag} id="aura-overlay-panel" class="aura-overlay-panel open">',
    f'    <{tag} class="overlay-panel-header">',
    '      <span class="overlay-status-dot"></span>',
    "      <span>AURA Overlay</span>",
    '      <button id="overlay-close-btn" type="button">&times;</button>',
    f"    </{tag}>",
    f'    <{tag} id="overlay-chat-messages" class="overlay-panel-body">',
    f'      <{tag} class="overlay-system-msg">AURA is ready. Ask about your current app or screen.</{tag}>',
    f"    </{tag}>",
    f'    <{tag} class="overlay-panel-input">',
    '      <textarea id="overlay-user-input" placeholder="Ask AURA..." rows="1"></textarea>',
    '      <button id="overlay-send-btn" type="button"><i class="fa-solid fa-paper-plane"></i></button>',
    f"    </{tag}>",
    f"  </{tag}>",
    '  <script src="../overlay_core/overlay_client.js"></script>',
    '  <script src="overlay.js"></script>',
    "</body>",
    "</html>",
]
(base / "overlay.html").write_text("\n".join(html_lines), encoding="utf-8")

css = """
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: Segoe UI, sans-serif; background: transparent; overflow: hidden; }
.aura-overlay-bubble {
  position: fixed; bottom: 20px; right: 20px; width: 52px; height: 52px;
  border-radius: 50%; background: rgba(20,20,20,0.85); border: 1px solid rgba(255,255,255,0.15);
  cursor: pointer; z-index: 9999; display: flex; align-items: center; justify-content: center;
}
.overlay-bubble-core { width: 14px; height: 14px; border-radius: 50%; background: #00f2ff; box-shadow: 0 0 12px #00f2ff; }
.aura-overlay-panel {
  position: fixed; bottom: 84px; right: 20px; width: 360px; height: 480px;
  background: rgba(28,28,28,0.92); border: 1px solid rgba(255,255,255,0.12); border-radius: 14px;
  display: none; flex-direction: column; z-index: 9998; color: #ececec;
}
.aura-overlay-panel.open { display: flex; }
.overlay-panel-header { padding: 12px 14px; display: flex; align-items: center; gap: 8px; border-bottom: 1px solid rgba(255,255,255,0.08); }
.overlay-status-dot { width: 8px; height: 8px; border-radius: 50%; background: #22c55e; }
.overlay-panel-body { flex: 1; overflow-y: auto; padding: 12px; font-size: 13px; }
.overlay-user-msg { background: rgba(0,242,255,0.12); padding: 8px 10px; border-radius: 10px; margin-bottom: 8px; }
.overlay-aura-msg { padding: 8px 10px; margin-bottom: 8px; line-height: 1.45; }
.overlay-system-msg { opacity: 0.7; font-size: 12px; margin-bottom: 8px; }
.overlay-panel-input { display: flex; gap: 8px; padding: 10px; border-top: 1px solid rgba(255,255,255,0.08); }
.overlay-panel-input textarea { flex: 1; background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.1); border-radius: 8px; color: #fff; padding: 8px; resize: none; font-size: 13px; }
#overlay-send-btn { width: 40px; border: none; border-radius: 8px; background: #06b6d4; color: #000; cursor: pointer; }
#overlay-close-btn { margin-left: auto; background: none; border: none; color: #aaa; font-size: 18px; cursor: pointer; }
"""
(base / "overlay.css").write_text(css.strip(), encoding="utf-8")

js_lines = [
    "(function () {",
    "  const Core = window.AuraOverlayClient;",
    "  if (!Core) return;",
    "  let client = null, isSending = false;",
    "  const bubble = document.getElementById('aura-overlay-bubble');",
    "  const panel = document.getElementById('aura-overlay-panel');",
    "  const input = document.getElementById('overlay-user-input');",
    "  const container = document.getElementById('overlay-chat-messages');",
    "  document.getElementById('overlay-send-btn').onclick = submit;",
    "  document.getElementById('overlay-close-btn').onclick = () => panel.classList.remove('open');",
    "  bubble.onclick = () => panel.classList.toggle('open');",
    "  async function submit() {",
    "    if (isSending || !input.value.trim()) return;",
    "    const text = input.value.trim(); input.value = ''; isSending = true;",
    "    const u = document.createElement('div'); u.className = 'overlay-user-msg'; u.textContent = text;",
    "    container.appendChild(u);",
    "    const a = document.createElement('div'); a.className = 'overlay-aura-msg';",
    "    a.innerHTML = '<strong>AURA</strong><span class=\"overlay-txt-body\">Thinking...</span>';",
    "    container.appendChild(a); const body = a.querySelector('.overlay-txt-body');",
    "    try {",
    "      if (!client) client = new Core.AuraOverlayClient({",
    "        onStatus: s => { body.textContent = s; },",
    "        onChunk: (_, full) => { body.innerHTML = full.replace(/\\\\n/g, '<br>'); },",
    "        onError: e => { body.textContent = e; }",
    "      });",
    "      client.disconnect(); await client.connect();",
    "      await client.send(text, { platform: 'windows', assistantMode: 'copilot', screenshot: 'local' });",
    "    } catch (e) { body.textContent = e.message || 'Backend offline (port 7860)'; }",
    "    finally { isSending = false; }",
    "  }",
    "  input.onkeydown = e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit(); } };",
    "})();",
]
(base / "overlay.js").write_text("\n".join(js_lines), encoding="utf-8")
print("OK")
