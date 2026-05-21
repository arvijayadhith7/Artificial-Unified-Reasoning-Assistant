/**
 * AURA Windows Overlay Runtime — input → context → /overlay/chat → stream UI
 */
(function () {
  const ClientClass =
    (window.AuraOverlay && window.AuraOverlay.AuraOverlayClient) ||
    (window.AuraOverlayClient && window.AuraOverlayClient.AuraOverlayClient);

  if (!ClientClass) {
    console.error('[AURA Overlay] overlay-client.js failed to load');
    return;
  }

  let client = null;
  let isSending = false;
  let assistantMode = 'copilot';
  let lastSendAt = 0;
  let pendingContext = null;

  // Inject beautiful context styling
  const style = document.createElement('style');
  style.textContent = `
    .overlay-context-bar {
      padding: 10px 14px;
      background: rgba(10, 25, 40, 0.85);
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

  const bubble = document.getElementById('aura-overlay-bubble');
  const panel = document.getElementById('aura-overlay-panel');
  const input = document.getElementById('overlay-user-input');
  const container = document.getElementById('overlay-chat-messages');
  const sendBtn = document.getElementById('overlay-send-btn');
  const closeBtn = document.getElementById('overlay-close-btn');
  const scanBtn = document.getElementById('overlay-scan-btn');
  const ctxLabel = document.getElementById('overlay-context-label');
  const modeSelect = document.getElementById('overlay-assistant-mode');

  function scrollBottom() {
    container.scrollTop = container.scrollHeight;
  }

  function appendUser(text) {
    const el = document.createElement('div');
    el.className = 'overlay-user-msg';
    el.textContent = text;
    container.appendChild(el);
    scrollBottom();
    return el;
  }

  function appendAssistant(placeholder) {
    const el = document.createElement('div');
    el.className = 'overlay-aura-msg';
    el.innerHTML = `<strong>AURA</strong><span class="overlay-txt-body">${placeholder}</span>`;
    container.appendChild(el);
    scrollBottom();
    return el.querySelector('.overlay-txt-body');
  }

  function setContextLabel(text) {
    if (ctxLabel) ctxLabel.textContent = text;
  }

  async function refreshContextLabel() {
    if (!window.electronAPI) return;
    try {
      const ctx = await window.electronAPI.getActiveContext();
      const app = ctx.active_app || 'Unknown';
      const title = (ctx.window_title || '').slice(0, 40);
      setContextLabel(title ? `${app} · ${title}` : app);
    } catch (_) {
      setContextLabel('Context unavailable');
    }
  }

  function openPanel() {
    panel.classList.add('open');
    bubble.style.display = 'none';
    if (window.electronAPI?.focusOverlay) {
      window.electronAPI.focusOverlay();
    }
    setTimeout(() => {
      input.focus();
      input.select();
    }, 80);
    refreshContextLabel();
  }

  function closePanel() {
    panel.classList.remove('open');
    bubble.style.display = 'flex';
  }

  function getOrCreateContextBar() {
    let bar = document.getElementById('overlay-context-bar');
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'overlay-context-bar';
      bar.className = 'overlay-context-bar';
      bar.style.display = 'none';
      bar.innerHTML = `
        <div class="context-detected-tags" id="context-detected-tags"></div>
        <div class="context-suggestion-chips" id="context-suggestion-chips"></div>
      `;
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
            if (input) {
              input.value = prompt;
              sendMessage(false);
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

  function getClient() {
    if (!client) {
      client = new ClientClass({
        onStatus: (s) => {
          const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
          if (body) body.textContent = s;
        },
        onChunk: (_delta, full) => {
          const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
          if (body) {
            body.innerHTML = full.replace(/\n/g, '<br>');
            scrollBottom();
          }
        },
        onDone: () => {
          isSending = false;
          sendBtn.disabled = false;
          sendBtn.classList.remove('sending');
        },
        onError: (msg) => {
          const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
          if (body) body.textContent = msg;
          isSending = false;
          sendBtn.disabled = false;
          sendBtn.classList.remove('sending');
        },
        onContextDetected: handleContextDetected
      });
    } else {
      client.onStatus = (s) => {
        const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
        if (body) body.textContent = s;
      };
      client.onChunk = (_delta, full) => {
        const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
        if (body) {
          body.innerHTML = full.replace(/\n/g, '<br>');
          scrollBottom();
        }
      };
      client.onError = (msg) => {
        const body = container.querySelector('.overlay-aura-msg:last-child .overlay-txt-body');
        if (body) body.textContent = msg;
        isSending = false;
        sendBtn.disabled = false;
        sendBtn.classList.remove('sending');
      };
      client.onDone = () => {
        isSending = false;
        sendBtn.disabled = false;
        sendBtn.classList.remove('sending');
      };
      client.onContextDetected = handleContextDetected;
    }
    return client;
  }

  async function buildSandbox(prompt, forceScreen) {
    const base = {
      platform: 'windows',
      assistantMode: modeSelect ? modeSelect.value : assistantMode,
      ocr: true,
      searchStrategy: modeSelect?.value === 'research' ? 'multi-tier' : 'local-only',
      screenshot: null,
    };

    if (pendingContext) {
      const ctx = pendingContext;
      pendingContext = null;
      return Object.assign(base, {
        activeApp: ctx.activeApp || '',
        windowTitle: ctx.windowTitle || '',
        accessibilityText: ctx.accessibilityText || '',
        selectedText: ctx.selectedText || '',
        screenshot: ctx.screenshot || null,
      });
    }

    if (window.electronAPI?.buildMessageContext) {
      const ctx = await window.electronAPI.buildMessageContext(prompt, forceScreen);
      return Object.assign(base, {
        activeApp: ctx.activeApp || '',
        windowTitle: ctx.windowTitle || '',
        accessibilityText: ctx.accessibilityText || '',
        selectedText: ctx.selectedText || '',
        screenshot: ctx.screenshot || null,
      });
    }

    base.screenshot = forceScreen ? 'local' : null;
    return base;
  }

  async function sendMessage(forceScreen) {
    const now = Date.now();
    if (now - lastSendAt < 350) return;
    lastSendAt = now;

    if (isSending) return;
    const text = input.value.trim();
    if (!text) return;

    isSending = true;
    sendBtn.disabled = true;
    sendBtn.classList.add('sending');
    input.value = '';

    // Clear previous dynamic suggestions bar
    const bar = document.getElementById('overlay-context-bar');
    if (bar) bar.style.display = 'none';

    appendUser(text);
    const body = appendAssistant('…');

    try {
      const sandboxOpts = await buildSandbox(text, forceScreen);
      setContextLabel(
        sandboxOpts.windowTitle
          ? `${sandboxOpts.activeApp || 'App'} · ${sandboxOpts.windowTitle.slice(0, 36)}`
          : sandboxOpts.activeApp || 'Ready'
      );

      const overlayClient = getClient();
      await overlayClient.connect();
      const reply = await overlayClient.send(text, sandboxOpts);
      if (reply && body.textContent === '…') {
        body.innerHTML = reply.replace(/\n/g, '<br>');
      }
    } catch (err) {
      console.error('[AURA Overlay] send failed:', err);
      body.textContent =
        err.message ||
        'AURA overlay lost connection. Start backend: py python_backend/main.py';
    } finally {
      isSending = false;
      sendBtn.disabled = false;
      sendBtn.classList.remove('sending');
      scrollBottom();
    }
  }

  bubble.addEventListener('click', () => openPanel());
  closeBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    closePanel();
  });

  sendBtn.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    sendMessage(false);
  });

  if (scanBtn) {
    scanBtn.addEventListener('click', async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const sys = document.createElement('div');
      sys.className = 'overlay-system-msg';
      sys.textContent = '📸 Scanning active screen layout...';
      container.appendChild(sys);
      scrollBottom();
      
      const overlayClient = getClient();
      overlayClient.onStatus = (s) => { sys.textContent = s; };
      overlayClient.onError = (msg) => { sys.textContent = 'Scan error: ' + msg; scrollBottom(); };
      overlayClient.onDone = () => {
        if (sys.textContent.startsWith('📸') || sys.textContent.startsWith('Scanning')) {
          sys.remove();
        }
      };
      overlayClient.onContextDetected = handleContextDetected;

      try {
        let activeApp = '';
        let windowTitle = '';
        let screenshot = null;
        let accessibilityText = '';

        if (window.electronAPI?.buildMessageContext) {
          const ctx = await window.electronAPI.buildMessageContext('', true);
          activeApp = ctx.activeApp || '';
          windowTitle = ctx.windowTitle || '';
          screenshot = ctx.screenshot || null;
          accessibilityText = ctx.accessibilityText || '';
        } else {
          screenshot = 'local';
        }

        await overlayClient.analyze({
          active_app: activeApp,
          window_title: windowTitle,
          accessibility_text: accessibilityText,
          screenshot: screenshot
        });
      } catch (err) {
        console.error('[AURA Overlay] Desktop analyze failed:', err);
        sys.textContent = 'Scan failed: ' + (err.message || err);
      }
      scrollBottom();
    });
  }

  input.addEventListener('keydown', async (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      e.stopPropagation();
      await sendMessage(false);
    }
  });

  input.addEventListener('focus', () => {
    if (window.electronAPI?.focusOverlay) window.electronAPI.focusOverlay();
  });

  panel.addEventListener('mousedown', () => {
    if (window.electronAPI?.focusOverlay) window.electronAPI.focusOverlay();
  });

  refreshContextLabel();
  setInterval(refreshContextLabel, 15000);

  openPanel();
  console.log('[AURA Overlay] Windows runtime ready');
})();
