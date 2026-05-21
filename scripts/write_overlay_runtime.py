from pathlib import Path

JS = r"""/* AURA Universal Overlay Runtime */
(function (global) {
  const Core = global.AuraOverlayClient;
  if (!Core) {
    console.warn("[AURA Overlay] Load overlay_core/overlay_client.js first");
    return;
  }

  let client = null;
  let isSending = false;
  let assistantMode = "copilot";
  let incognito = false;

  function getEl(id) {
    return document.getElementById(id);
  }

  function sandboxFromPage() {
    const p = document.getElementById("sb-persona");
    const d = document.getElementById("sb-search-depth");
    const w = document.getElementById("sb-workspace-path");
    return {
      platform: global.electronAPI ? "windows" : "web",
      assistantMode: assistantMode,
      persona: p ? p.value : "warm-narrative",
      searchStrategy: d ? d.value : "multi-tier",
      workspacePath: w ? w.value : "",
      screenshot: "local",
      incognito: incognito,
      ocr: true
    };
  }

  async function submitOverlayQuery() {
    if (isSending) return;
    const input = getEl("overlay-user-input");
    const container = getEl("overlay-chat-messages");
    if (!input || !container) return;

    const text = input.value.trim();
    if (!text) return;
    input.value = "";
    isSending = true;

    const userDiv = document.createElement("div");
    userDiv.className = "overlay-user-msg";
    userDiv.textContent = text;
    container.appendChild(userDiv);

    const auraDiv = document.createElement("motion" === "x" ? "motion" : "motion");
"""

# Fix - write correct JS without typo
JS = """/* AURA Universal Overlay Runtime */
(function (global) {
  const Core = global.AuraOverlayClient;
  if (!Core) {
    console.warn("[AURA Overlay] Load overlay_core/overlay_client.js first");
    return;
  }

  let client = null;
  let isSending = false;
  let assistantMode = "copilot";
  let incognito = false;

  function getEl(id) {
    return document.getElementById(id);
  }

  function sandboxFromPage() {
    const p = document.getElementById("sb-persona");
    const d = document.getElementById("sb-search-depth");
    const w = document.getElementById("sb-workspace-path");
    return {
      platform: global.electronAPI ? "windows" : "web",
      assistantMode: assistantMode,
      persona: p ? p.value : "warm-narrative",
      searchStrategy: d ? d.value : "multi-tier",
      workspacePath: w ? w.value : "",
      screenshot: "local",
      incognito: incognito,
      ocr: true
    };
  }

  async function submitOverlayQuery() {
    if (isSending) return;
    const input = getEl("overlay-user-input");
    const container = getEl("overlay-chat-messages");
    if (!input || !container) return;

    const text = input.value.trim();
    if (!text) return;
    input.value = "";
    isSending = true;

    const userDiv = document.createElement("div");
    userDiv.className = "overlay-user-msg";
    userDiv.textContent = text;
    container.appendChild(userDiv);

    const auraDiv = document.createElement("div");
    auraDiv.className = "overlay-aura-msg";
    auraDiv.innerHTML = "<strong>AURA</strong><span class=\"overlay-txt-body\">Thinking...</span>";
    container.appendChild(auraDiv);
    const body = auraDiv.querySelector(".overlay-txt-body");
    container.scrollTop = container.scrollHeight;

    try {
      if (!client) {
        client = new Core.AuraOverlayClient({
          onStatus: function(s) { if (body) body.textContent = s; },
          onChunk: function(chunk, full) {
            if (body) body.innerHTML = full.replace(/\\n/g, "<br>");
            container.scrollTop = container.scrollHeight;
          },
          onError: function(err) {
            if (body) body.textContent = err;
          }
        });
      }
      client.disconnect();
      await client.connect();
      await client.send(text, sandboxFromPage());
    } catch (e) {
      if (body) body.textContent = e.message || "Connection failed. Start backend on port 7860.";
    } finally {
      isSending = false;
    }
  }

  global.AuraOverlayRuntime = {
    submitOverlayQuery: submitOverlayQuery,
    setAssistantMode: function(m) { assistantMode = m; },
    setIncognito: function(v) { incognito = !!v; }
  };
  global.submitOverlayQuery = submitOverlayQuery;
})();
"""

out = Path(r"d:\ANTIGRAVITY\llm APP\aura_web_portal\overlay\overlay-runtime.js")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(JS, encoding="utf-8")
print("Wrote", out)
