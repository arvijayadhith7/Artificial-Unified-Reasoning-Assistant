const { app, BrowserWindow, screen, ipcMain } = require('electron');
const path = require('path');
const contextEngine = require('./context-engine');

let mainWindow;

function createOverlayWindow() {
  const { width: screenWidth, height: screenHeight } = screen.getPrimaryDisplay().workAreaSize;
  const windowWidth = 400;
  const windowHeight = 560;

  mainWindow = new BrowserWindow({
    width: windowWidth,
    height: windowHeight,
    x: screenWidth - windowWidth - 16,
    y: screenHeight - windowHeight - 16,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: false,
    resizable: true,
    focusable: true,
    hasShadow: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'overlay.html'));
  mainWindow.setAlwaysOnTop(true, 'screen-saver');

  mainWindow.webContents.on('did-finish-load', () => {
    mainWindow.setFocusable(true);
    mainWindow.focus();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

ipcMain.handle('get-active-context', async () => {
  try {
    return await contextEngine.getContextSnapshot();
  } catch (e) {
    return { active_app: 'Unknown', window_title: '', accessibility_text: '' };
  }
});

ipcMain.handle('build-message-context', async (_event, { prompt, forceScreen }) => {
  try {
    return await contextEngine.buildMessageContext(prompt || '', { forceScreen: !!forceScreen });
  } catch (e) {
    console.error('[AURA] build-message-context:', e);
    return {
      activeApp: '',
      windowTitle: '',
      accessibilityText: '',
      selectedText: '',
      screenshot: null,
    };
  }
});

ipcMain.handle('capture-screen', async () => {
  const shot = await contextEngine.captureScreenJpegBase64();
  return shot || 'local';
});

ipcMain.handle('focus-overlay', () => {
  if (!mainWindow) return false;
  mainWindow.setFocusable(true);
  mainWindow.setIgnoreMouseEvents(false);
  mainWindow.show();
  mainWindow.focus();
  mainWindow.webContents.focus();
  return true;
});

app.whenReady().then(() => {
  createOverlayWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createOverlayWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
