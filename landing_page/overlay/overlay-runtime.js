/* AURA Overlay Runtime v2 — uses AuraOverlayClient with correct WS payload */
(function (global) {
  let client = null;
  let isSending = false;
  let assistantMode = 'copilot';

  // Inject beautiful context styling
  const style = document.createElement('style');
  style.textContent = `
    .overlay-context-bar {
      padding: 10px 14px;
      background: rgba(10, 25, 40, 0.75);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-top: 1px solid rgba(0, 240, 255, 0.25);
      border-bottom: 1px solid rgba(0, 240, 255, 0.25);
      display: flex;
      flex-direction: column;
      gap: 10px;
      box-shadow: 0 -4px 20px rgba(0, 240, 255, 0.08);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    .context-detected-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .context-tag {
      background: rgba(0, 240, 255, 0.12);
      color: #00f0ff;
      border: 1px solid rgba(0, 240, 255, 0.35);
      border-radius: 4px;
      padding: 3px 8px;
      font-size: 11px;
      font-weight: 600;
      text-shadow: 0 0 5px rgba(0, 240, 255, 0.4);
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }
    .context-suggestion-chips {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .suggestion-chip {
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.08);
      color: #e0e0e0;
      border-radius: 14px;
      padding: 6px 12px;
      font-size: 11px;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      display: inline-flex;
      align-items: center;
    }
    .suggestion-chip:hover {
      background: rgba(0, 240, 255, 0.12);
      border-color: rgba(0, 240, 255, 0.5);
      color: #ffffff;
      box-shadow: 0 0 10px rgba(0, 240, 255, 0.25);
      transform: translateY(-1px);
    }
    .suggestion-chip:active {
      transform: translateY(0);
    }
  `;
  document.head.appendChild(style);

  function getClientClass() {
    if (global.AuraOverlay && global.AuraOverlay.AuraOverlayClient) {
      return global.AuraOverlay.AuraOverlayClient;
    }
    if (global.AuraOverlayClient && global.AuraOverlayClient.AuraOverlayClient) {
      return global.AuraOverlayClient.AuraOverlayClient;
    }
    return null;
  }

  function getEl(id) {
    if (typeof global.getOverlayElement === 'function') {
      return global.getOverlayElement(id);
    }
    return document.getElementById(id);
  }

  function getPanel() {
    if (typeof global.getOverlayPanel === 'function') {
      return global.getOverlayPanel();
    }
    return document.getElementById('aura-overlay-panel');
  }

  function ensurePanelOpen() {
    const panel = getPanel();
    if (!panel) return;
    const visible = panel.classList.contains('active') ||
      panel.style.opacity === '1' ||
      panel.style.display === 'flex';
    if (!visible) {
      if (typeof global.openOverlayPanel === 'function') {
        global.openOverlayPanel();
      } else {
        panel.classList.add('active');
      }
    }
  }

  function getOrCreateContextBar() {
    let bar = document.getElementById('overlay-context-bar');
    if (!bar) {
      const panel = getPanel();
      if (!panel) return null;
      bar = document.createElement('div');
      bar.id = 'overlay-context-bar';
      bar.className = 'overlay-context-bar';
      bar.style.display = 'none';
      bar.innerHTML = `
        <div class="context-detected-tags" id="context-detected-tags"></div>
        <div class="context-suggestion-chips" id="context-suggestion-chips"></div>
      `;
      // Insert before overlay-panel-input
      const inputArea = panel.querySelector('.overlay-panel-input');
      if (inputArea) {
        panel.insertBefore(bar, inputArea);
      } else {
        panel.appendChild(bar);
      }
    }
    return bar;
  }

  function handleContextDetected(detectedItems, suggestions) {
    console.log('[AURA Overlay] Context detected:', detectedItems, suggestions);
    const bar = getOrCreateContextBar();
    if (!bar) return;
    
    const tagsDiv = bar.querySelector('.context-detected-tags');
    const chipsDiv = bar.querySelector('.context-suggestion-chips');
    
    if (tagsDiv) {
      tagsDiv.innerHTML = '';
      if (detectedItems && detectedItems.length > 0) {
        detectedItems.forEach(item => {
          const span = document.createElement('span');
          span.className = 'context-tag';
          span.innerHTML = `<i class="fa-solid fa-cube"></i> ${escapeHtml(item)}`;
          tagsDiv.appendChild(span);
        });
      }
    }
    
    if (chipsDiv) {
      chipsDiv.innerHTML = '';
      if (suggestions && suggestions.length > 0) {
        suggestions.forEach(sug => {
          let label = sug;
          let prompt = sug;
          if (sug && typeof sug === 'object') {
            label = sug.label || '';
            prompt = sug.prompt || '';
          }
          const button = document.createElement('button');
          button.className = 'suggestion-chip';
          button.type = 'button';
          button.textContent = label;
          button.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            const inputEl = getEl('overlay-user-input');
            if (inputEl) {
              inputEl.value = prompt;
              submitOverlayQuery();
            }
            bar.style.display = 'none';
          });
          chipsDiv.appendChild(button);
        });
      }
    }
    
    if ((detectedItems && detectedItems.length > 0) || (suggestions && suggestions.length > 0)) {
      bar.style.display = 'flex';
    } else {
      bar.style.display = 'none';
    }
  }

  function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  async function buildWebSandboxOpts() {
    const p = document.getElementById('sb-persona');
    const d = document.getElementById('sb-search-depth');
    const w = document.getElementById('sb-workspace-path');
    const modeEl = getEl('overlay-assistant-mode');
    if (modeEl && modeEl.value) assistantMode = modeEl.value;

    let screenshot = null;
    const stream = window.screenCaptureStream || global.screenCaptureStream;
    if (stream) {
      try {
        const video = document.createElement('video');
        video.srcObject = stream;
        video.muted = true;
        video.playsInline = true;
        await new Promise((resolve) => {
          video.onloadedmetadata = () => {
            video.play().then(resolve);
          };
        });
        const canvas = document.createElement('canvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        screenshot = canvas.toDataURL('image/jpeg', 0.8);
        video.pause();
        video.srcObject = null;
      } catch (e) {
        console.warn('[AURA Overlay] Screen capture error:', e);
      }
    }

    let activeApp = '';
    let windowTitle = '';
    try {
      const response = await fetch('/system/active-window');
      if (response.ok) {
        const systemDetails = await response.json();
        if (systemDetails && systemDetails.status === "success") {
          activeApp = systemDetails.process || '';
          windowTitle = systemDetails.title || '';
        }
      }
    } catch (err) {
      console.warn("Could not retrieve active window:", err);
    }

    return {
      platform: global.electronAPI ? 'windows' : 'web',
      assistantMode: assistantMode,
      persona: (p && p.value) || 'warm-narrative',
      searchStrategy: (d && d.value) || 'multi-tier',
      workspacePath: (w && w.value) || '',
      screenshot: screenshot,
      active_app: activeApp,
      window_title: windowTitle,
      ocr: true
    };
  }

  function appendUserMsg(container, text) {
    const div = document.createElement('div');
    div.className = 'overlay-user-msg';
    div.textContent = text;
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
    return div;
  }

  function appendAssistantMsg(container) {
    const div = document.createElement('div');
    div.className = 'overlay-aura-msg';
    div.innerHTML = '<strong>AURA Overlay</strong><span class="overlay-txt-body">Connecting…</span>';
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
    return div.querySelector('.overlay-txt-body');
  }

  async function submitOverlayQuery() {
    if (isSending) return;

    const ClientClass = getClientClass();
    if (!ClientClass) {
      alert('Overlay client failed to load. Hard-refresh (Ctrl+Shift+R).');
      return;
    }

    ensurePanelOpen();

    const input = getEl('overlay-user-input');
    const container = getEl('overlay-chat-messages');
    if (!input || !container) {
      alert('Overlay UI not found. Hard-refresh the page (Ctrl+Shift+R).');
      return;
    }

    const text = input.value.trim();
    if (!text) return;

    input.value = '';
    isSending = true;

    // Clear previous dynamic suggestions bar
    const bar = document.getElementById('overlay-context-bar');
    if (bar) bar.style.display = 'none';

    appendUserMsg(container, text);
    const body = appendAssistantMsg(container);
    let firstChunk = true;
    let full = '';

    if (!client) {
      client = new ClientClass({
        onStatus: function (s) { body.textContent = s; },
        onChunk: function (chunk, accumulated) {
          if (firstChunk) {
            body.innerHTML = '';
            firstChunk = false;
          }
          full = accumulated;
          body.innerHTML = accumulated.replace(/\n/g, '<br>');
          container.scrollTop = container.scrollHeight;
        },
        onError: function (msg) { body.textContent = msg; },
        onDone: function () { isSending = false; },
        onContextDetected: handleContextDetected
      });
    } else {
      client.onStatus = function (s) { body.textContent = s; };
      client.onChunk = function (chunk, accumulated) {
        if (firstChunk) {
          body.innerHTML = '';
          firstChunk = false;
        }
        full = accumulated;
        body.innerHTML = accumulated.replace(/\n/g, '<br>');
        container.scrollTop = container.scrollHeight;
      };
      client.onError = function (msg) { body.textContent = msg; };
      client.onDone = function () { isSending = false; };
      client.onContextDetected = handleContextDetected;
    }

    try {
      const opts = await buildWebSandboxOpts();
      const reply = await client.send(text, opts);
      if (firstChunk && reply) {
        body.innerHTML = reply.replace(/\n/g, '<br>');
      }
    } catch (err) {
      console.error('[AURA Overlay]', err);
      body.textContent = err.message || 'Something went wrong.';
    } finally {
      isSending = false;
    }
  }

  async function triggerScreenScan() {
    const ClientClass = getClientClass();
    if (!ClientClass) return;

    ensurePanelOpen();
    const container = getEl('overlay-chat-messages');
    if (!container) return;

    const sysMsg = document.createElement('div');
    sysMsg.className = 'overlay-system-msg';
    sysMsg.textContent = '📸 Scanning active screen layout...';
    container.appendChild(sysMsg);
    container.scrollTop = container.scrollHeight;

    if (!client) {
      client = new ClientClass({
        onStatus: function (s) { sysMsg.textContent = s; },
        onChunk: function () {},
        onError: function (msg) { sysMsg.textContent = 'Scan error: ' + msg; },
        onDone: function () {
          if (sysMsg.textContent.startsWith('📸') || sysMsg.textContent.startsWith('Scanning')) {
            sysMsg.remove();
          }
        },
        onContextDetected: handleContextDetected
      });
    } else {
      client.onStatus = function (s) { sysMsg.textContent = s; };
      client.onError = function (msg) { sysMsg.textContent = 'Scan error: ' + msg; };
      client.onDone = function () {
        if (sysMsg.textContent.startsWith('📸') || sysMsg.textContent.startsWith('Scanning')) {
          sysMsg.remove();
        }
      };
      client.onContextDetected = handleContextDetected;
    }

    try {
      const opts = await buildWebSandboxOpts();
      await client.analyze({
        active_app: opts.active_app,
        window_title: opts.window_title,
        screenshot: opts.screenshot
      });
    } catch (err) {
      console.error('[AURA Overlay] analyze failed:', err);
      sysMsg.textContent = 'Scan failed: ' + (err.message || err);
    }
  }

  async function triggerOverlayAction(action) {
    if (action === 'screenshot') {
      await triggerScreenScan();
      return;
    }
    const input = getEl('overlay-user-input');
    if (!input) return;
    
    if (action === 'summarize') {
      input.value = "Summarize what I'm working on right now.";
    } else if (action === 'explain') {
      input.value = "Can you explain the code/contents on my screen?";
    } else if (action === 'debug') {
      input.value = "Look for any issues or errors in my current environment.";
    } else if (action === 'reply') {
      input.value = "Draft a context-aware email reply based on what is active on my desktop.";
    } else if (action === 'voice') {
      const container = getEl('overlay-chat-messages');
      if (container) {
        const sysMsg = document.createElement('div');
        sysMsg.className = 'overlay-system-msg';
        sysMsg.innerText = "🎙 Voice Input Activated: Listening...";
        container.appendChild(sysMsg);
        container.scrollTop = container.scrollHeight;
        setTimeout(() => {
          input.value = "How does this code look to you?";
          input.focus();
          sysMsg.remove();
        }, 1500);
      }
      return;
    }
    
    await submitOverlayQuery();
  }

  global.AuraOverlayRuntime = {
    submitOverlayQuery: submitOverlayQuery,
    triggerScreenScan: triggerScreenScan,
    triggerOverlayAction: triggerOverlayAction,
    setAssistantMode: function (m) { assistantMode = m; }
  };
  global.submitOverlayQuery = submitOverlayQuery;
  global.triggerOverlayAction = triggerOverlayAction;

  function bindControls() {
    document.querySelectorAll('.overlay-send-btn').forEach(function (btn) {
      if (btn.dataset.auraBound) return;
      btn.dataset.auraBound = '1';
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        submitOverlayQuery();
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindControls);
  } else {
    bindControls();
  }
})(typeof window !== 'undefined' ? window : this);
