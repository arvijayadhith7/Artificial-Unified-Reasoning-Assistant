from pathlib import Path

RUNTIME = r"""/* AURA Universal Overlay Runtime v1.1 */
(function (global) {
  const Core = global.AuraOverlay || global.AuraOverlayClient;
  const ClientClass = Core && (Core.AuraOverlayClient || Core);
  if (!ClientClass || typeof ClientClass !== 'function') {
    console.error('[AURA Overlay] overlay-client.js failed to load');
    global.submitOverlayQuery = function () { alert('Refresh page: Ctrl+Shift+R'); };
    return;
  }
  let client = null;
  let isSending = false;
  let assistantMode = 'copilot';
  function getEl(id) {
    if (typeof global.getOverlayElement === 'function') return global.getOverlayElement(id);
    return document.getElementById(id);
  }
  function sandboxFromPage() {
    const p = document.getElementById('sb-persona');
    const d = document.getElementById('sb-search-depth');
    const w = document.getElementById('sb-workspace-path');
    const modeEl = getEl('overlay-assistant-mode');
    if (modeEl && modeEl.value) assistantMode = modeEl.value;
    return {
      platform: global.electronAPI ? 'windows' : 'web',
      assistantMode: assistantMode,
      persona: p ? p.value : 'warm-narrative',
      searchStrategy: d ? d.value : 'multi-tier',
      workspacePath: w ? w.value : '',
      screenshot: 'local',
      ocr: true
    };
  }
  async function submitOverlayQuery() {
    if (isSending) return;
    const input = getEl('overlay-user-input');
    const container = getEl('overlay-chat-messages');
    if (!input || !container) return;
    const text = input.value.trim();
    if (!text) return;
    input.value = '';
    isSending = true;
    const userDiv = document.createElement('div');
    userDiv.className = 'overlay-user-msg';
    userDiv.textContent = text;
    container.appendChild(userDiv);
    const auraDiv = document.createElement('div');
    auraDiv.className = 'overlay-aura-msg';
    auraDiv.innerHTML = '<strong>AURA</strong><span class="overlay-txt-body">Thinking...</span>';
    container.appendChild(auraDiv);
    const body = auraDiv.querySelector('.overlay-txt-body');
    container.scrollTop = container.scrollHeight;
    try {
      if (!client) {
        client = new ClientClass({
          onStatus: function (s) { if (body) body.textContent = s; },
          onChunk: function (_, full) {
            if (body) body.innerHTML = full.replace(/\n/g, '<br>');
            container.scrollTop = container.scrollHeight;
          },
          onError: function (err) { if (body) body.textContent = err; }
        });
      }
      await client.send(text, sandboxFromPage());
    } catch (e) {
      if (body) body.textContent = e.message || 'Connection failed. Start backend on port 7860.';
    } finally {
      isSending = false;
    }
  }
  global.AuraOverlayRuntime = { submitOverlayQuery: submitOverlayQuery };
  global.submitOverlayQuery = submitOverlayQuery;
  document.addEventListener('DOMContentLoaded', function () {
    const btn = document.querySelector('.overlay-send-btn');
    const input = document.getElementById('overlay-user-input');
    if (btn) btn.addEventListener('click', function (e) { e.preventDefault(); submitOverlayQuery(); });
    if (input) input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submitOverlayQuery(); }
    });
  });
})();
"""

Path(r"d:\ANTIGRAVITY\llm APP\aura_web_portal\overlay\overlay-runtime.js").write_text(RUNTIME, encoding="utf-8")
print("written")
