/**
 * AURA Windows Overlay — main-process context engine (no UI blocking).
 */
const { desktopCapturer, clipboard } = require('electron');

const BACKEND = 'http://127.0.0.1:7860';
const SCREEN_KEYWORDS = [
  'screen', 'error', 'this page', 'visible', 'looking at', 'what is on',
  'what is in', 'screenshot', 'why is this', 'explain this', 'debug',
  'what does this', 'summarize', 'scan', 'ocr', 'layout'
];

let activeWinModule = null;
try {
  activeWinModule = require('active-win');
} catch (_) {
  console.warn('[AURA Context] active-win not installed; using backend fallback');
}

function needsScreenCapture(prompt) {
  const p = (prompt || '').toLowerCase();
  return SCREEN_KEYWORDS.some((k) => p.includes(k));
}

async function getActiveWindowFromBackend() {
  try {
    const res = await fetch(`${BACKEND}/system/active-window`);
    if (!res.ok) return null;
    const data = await res.json();
    return {
      title: data.title || '',
      owner: { name: data.process || 'Unknown' },
      process: data.process || '',
    };
  } catch (e) {
    return null;
  }
}

let lastNonOverlayWindow = {
  title: 'VS Code',
  owner: { name: 'Code' },
  process: 'Code.exe',
};

async function getActiveWindow() {
  let win = null;
  if (activeWinModule) {
    try {
      win = await activeWinModule();
    } catch (e) {
      console.warn('[AURA Context] active-win failed:', e.message);
    }
  }
  if (!win) {
    win = await getActiveWindowFromBackend();
  }

  if (win) {
    const appName = (win.owner?.name || win.process || '').toLowerCase();
    const title = (win.title || '').toLowerCase();
    const isOverlay =
      appName.includes('electron') ||
      appName.includes('aura') ||
      title.includes('aura universal overlay') ||
      title.includes('aura system overlay');
    if (!isOverlay) {
      lastNonOverlayWindow = win;
    }
  }
  return lastNonOverlayWindow;
}


function getClipboardText() {
  try {
    const text = clipboard.readText();
    return (text || '').trim().slice(0, 2000);
  } catch (_) {
    return '';
  }
}

async function captureScreenJpegBase64() {
  try {
    const sources = await desktopCapturer.getSources({
      types: ['screen'],
      thumbnailSize: { width: 1280, height: 720 },
    });
    const primary = sources.find((s) => s.id.toLowerCase().includes('screen')) || sources[0];
    if (!primary || !primary.thumbnail) return null;
    const jpeg = primary.thumbnail.toJPEG(72);
    return `data:image/jpeg;base64,${jpeg.toString('base64')}`;
  } catch (e) {
    console.warn('[AURA Context] screen capture failed:', e.message);
    return null;
  }
}

function buildAccessibilitySummary(win, clipboardText) {
  const lines = [];
  const appName = win?.owner?.name || win?.process || '';
  const title = win?.title || '';
  if (appName) lines.push(`Current App: ${appName}`);
  if (title) lines.push(`Window: ${title}`);
  if (clipboardText) {
    lines.push(`Clipboard/selection: ${clipboardText.slice(0, 600)}`);
  }
  return lines.join('\n');
}

/**
 * Full context bundle for one overlay message.
 */
async function buildMessageContext(prompt, options = {}) {
  const forceScreen = options.forceScreen === true;
  const win = await getActiveWindow();
  const clip = getClipboardText();
  const accessibilityText = buildAccessibilitySummary(win, clip);

  let screenshot = null;
  if (forceScreen || needsScreenCapture(prompt)) {
    screenshot = await captureScreenJpegBase64();
    if (!screenshot) {
      screenshot = 'local';
    }
  }

  return {
    activeApp: win?.owner?.name || win?.process || '',
    windowTitle: win?.title || '',
    accessibilityText,
    selectedText: clip,
    screenshot,
    workflow: win?.owner?.name || '',
  };
}

async function getContextSnapshot() {
  const win = await getActiveWindow();
  const clip = getClipboardText();
  return {
    active_app: win?.owner?.name || win?.process || 'Unknown',
    window_title: win?.title || '',
    accessibility_text: buildAccessibilitySummary(win, clip),
    platform: 'windows',
  };
}

module.exports = {
  buildMessageContext,
  getContextSnapshot,
  needsScreenCapture,
  captureScreenJpegBase64,
};
