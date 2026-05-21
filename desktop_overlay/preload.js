const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  platform: 'windows',
  getActiveContext: () => ipcRenderer.invoke('get-active-context'),
  buildMessageContext: (prompt, forceScreen) =>
    ipcRenderer.invoke('build-message-context', { prompt, forceScreen: !!forceScreen }),
  captureScreen: () => ipcRenderer.invoke('capture-screen'),
  focusOverlay: () => ipcRenderer.invoke('focus-overlay'),
});
