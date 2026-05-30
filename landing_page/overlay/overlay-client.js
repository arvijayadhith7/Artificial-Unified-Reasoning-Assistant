/**
 * AURA Universal Overlay Client v1.1
 */
(function (root) {
  const CONVERSATION_ID = 'aura_overlay';
  const DEFAULT_BACKEND_PORT = 7860;
  const REQUEST_TIMEOUT_MS = 120000;

  function resolveBackendWsUrl(explicitHost) {
    if (explicitHost) {
      const proto = explicitHost.startsWith('https') || explicitHost.startsWith('wss') ? 'wss' : 'ws';
      const clean = explicitHost.replace(/^https?:\/\//, '').replace(/^wss?:\/\//, '');
      return `${proto}://${clean}/chat`;
    }
    const loc = typeof window !== 'undefined' ? window.location : null;
    if (loc && loc.hostname) {
      return `ws://${loc.hostname}:${DEFAULT_BACKEND_PORT}/chat`;
    }
    return `ws://127.0.0.1:${DEFAULT_BACKEND_PORT}/chat`;
  }

  function resolveBackendHttpUrl(path, explicitHost) {
    if (explicitHost) {
      return `${explicitHost.replace(/\/$/, '')}${path}`;
    }
    const loc = typeof window !== 'undefined' ? window.location : null;
    if (loc && loc.hostname) {
      return `http://${loc.hostname}:${DEFAULT_BACKEND_PORT}${path}`;
    }
    return `http://127.0.0.1:${DEFAULT_BACKEND_PORT}${path}`;
  }

  function buildSandbox(opts) {
    return {
      platform: opts.platform || 'web',
      overlay_mode: true,
      assistant_mode: opts.assistantMode || 'copilot',
      active_app: opts.activeApp || '',
      window_title: opts.windowTitle || '',
      accessibility_text: opts.accessibilityText || '',
      selected_text: opts.selectedText || '',
      screenshot: opts.screenshot || null,
      incognito: !!opts.incognito,
      persona: opts.persona || 'warm-narrative',
      search_strategy: opts.searchStrategy || 'multi-tier',
      ocr: opts.ocr !== false,
      cricket: false,
      lint: !!opts.lint,
      workspace_path: opts.workspacePath || '',
      locale: opts.locale || (typeof navigator !== 'undefined' ? navigator.language : 'en')
    };
  }

  class AuraOverlayClient {
    constructor(options) {
      options = options || {};
      this.backendHost = options.backendHost || null;
      this.ws = null;
      this.history = [];
      this.onStatus = options.onStatus || function () {};
      this.onChunk = options.onChunk || function () {};
      this.onDone = options.onDone || function () {};
      this.onError = options.onError || function () {};
    }

    connect() {
      const self = this;
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        return Promise.resolve();
      }
      if (this.ws && this.ws.readyState === WebSocket.CONNECTING) {
        return new Promise(function (resolve, reject) {
          const existing = self.ws;
          existing.addEventListener('open', function () { resolve(); }, { once: true });
          existing.addEventListener('error', function () {
            reject(new Error('WebSocket connection failed'));
          }, { once: true });
        });
      }

      return new Promise(function (resolve, reject) {
        const wsUrl = resolveBackendWsUrl(self.backendHost);
        console.log('[AURA Overlay] Connecting:', wsUrl);
        const ws = new WebSocket(wsUrl);
        self.ws = ws;
        ws.addEventListener('open', function () { resolve(); }, { once: true });
        ws.addEventListener('error', function () {
          reject(new Error('Cannot reach AURA backend on port 7860. Start: py python_backend/main.py'));
        }, { once: true });
      });
    }

    disconnect() {
      if (this.ws) {
        try { this.ws.close(); } catch (e) {}
        this.ws = null;
      }
    }

    async send(prompt, sandboxOpts) {
      sandboxOpts = sandboxOpts || {};
      await this.connect();

      const ctx = await fetch(resolveBackendHttpUrl('/overlay/context', this.backendHost))
        .then(function (r) { return r.ok ? r.json() : {}; })
        .catch(function () { return {}; });

      const win = await fetch(resolveBackendHttpUrl('/system/active-window', this.backendHost))
        .then(function (r) { return r.ok ? r.json() : {}; })
        .catch(function () { return {}; });

      const sandbox = buildSandbox(Object.assign({}, sandboxOpts, {
        activeApp: sandboxOpts.activeApp || ctx.active_app || win.process || '',
        windowTitle: sandboxOpts.windowTitle || ctx.window_title || win.title || ''
      }));

      const payload = {
        prompt: prompt,
        conversationId: CONVERSATION_ID,
        projectId: 'global',
        history: this.history.slice(-8),
        sandbox: sandbox
      };

      const self = this;
      const ws = this.ws;

      return new Promise(function (resolve, reject) {
        let full = '';
        let settled = false;

        function finish(err, text) {
          if (settled) return;
          settled = true;
          clearTimeout(timer);
          if (err) reject(err);
          else resolve(text);
        }

        const timer = setTimeout(function () {
          self.onError('Request timed out. Check backend on port 7860.');
          finish(new Error('Request timed out'));
        }, REQUEST_TIMEOUT_MS);

        ws.onmessage = function (event) {
          try {
            const data = JSON.parse(event.data);
            if (data.type === 'status') {
              self.onStatus(data.content);
            } else if (data.type === 'chunk') {
              full += data.content || '';
              self.onChunk(data.content, full);
            } else if (data.done === true) {
              self.history.push({ role: 'user', content: prompt });
              if (full) self.history.push({ role: 'assistant', content: full });
              self.onDone(full);
              finish(null, full);
            }
          } catch (e) {
            finish(e);
          }
        };

        ws.onerror = function () {
          const msg = 'Connection lost. Restart backend: py python_backend/main.py';
          self.onError(msg);
          finish(new Error(msg));
        };

        ws.onclose = function () {
          if (!settled) {
            finish(new Error('Connection closed before reply completed'));
          }
        };

        try {
          ws.send(JSON.stringify(payload));
          console.log('[AURA Overlay] Sent:', prompt.slice(0, 80));
        } catch (e) {
          finish(e);
        }
      });
    }
  }

  root.AuraOverlay = {
    AuraOverlayClient: AuraOverlayClient,
    buildSandbox: buildSandbox,
    resolveBackendWsUrl: resolveBackendWsUrl,
    CONVERSATION_ID: CONVERSATION_ID
  };
  root.AuraOverlayClient = root.AuraOverlay;
})(typeof window !== 'undefined' ? window : this);
