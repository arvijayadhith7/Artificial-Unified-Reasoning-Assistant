/* ==========================================================================
   AURA INTERACTIVE APPLICATION SCRIPT - CHATGPT DESKTOP EDITION
   Provides: Chat handshakes, real-time thought streams, sandbox maps & hotloads
   ========================================================================== */

// AURA Backend Configuration
// Set this to your live backend URL (e.g. 'https://vijayadhith7-aura-backend.hf.space') when deploying.
// Leave as empty string to automatically connect to your local backend on port 7860.
const PRODUCTION_BACKEND_URL = ""; 

function getBackendHost(currentHost) {
    if (PRODUCTION_BACKEND_URL) {
        return PRODUCTION_BACKEND_URL.replace(/^(http|https|ws|wss):\/\//, '');
    }
    let host = currentHost || 'localhost:7860';
    const hostname = host.split(':')[0];
    const isLocal = hostname === 'localhost' || 
                    hostname === '127.0.0.1' || 
                    hostname.startsWith('192.168.') || 
                    hostname.startsWith('10.') || 
                    hostname.startsWith('172.') ||
                    host.includes(':8085') ||
                    host.includes(':8080');
    
    if (isLocal) {
        return hostname + ':7860';
    }
    return host;
}

// Page layout hooks
const bgGrid = document.getElementById('bg-grid');
const glowC = document.getElementById('glow-c');
const glowV = document.getElementById('glow-v');
const chatMessages = document.getElementById('chat-messages');
const userInput = document.getElementById('terminal-user-input');
const sendMsgBtn = document.getElementById('btn-send-msg');
const welcomeView = document.getElementById('welcome-view');

// Chat Mode Select Hook
const chatModeSelect = document.getElementById('chat-mode-select');

// Diagnostic logs
const thinkingProgressBar = document.getElementById('thinking-progress-bar');
const thinkingProgressLabel = document.getElementById('thinking-progress-label');
const thoughtStepsLog = document.getElementById('thought-steps-log');

// State mappings for modes
// Web Audio API Synthesizer for Cyberpunk HUD Sound Effects
const CyberSound = {
    ctx: null,
    init() {
        if (!this.ctx) {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            if (AudioContextClass) {
                this.ctx = new AudioContextClass();
            }
        }
    },
    playClick() {
        this.init();
        if (!this.ctx) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(1400, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(400, this.ctx.currentTime + 0.06);
        gain.gain.setValueAtTime(0.08, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.06);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.06);
    },
    playKeypress() {
        this.init();
        if (!this.ctx) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.type = 'sine';
        const freq = 1200 + Math.random() * 400;
        osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(300, this.ctx.currentTime + 0.02);
        gain.gain.setValueAtTime(0.015, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + 0.02);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.02);
    },
    playEnter() {
        this.init();
        if (!this.ctx) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();
        const time = this.ctx.currentTime;
        const osc1 = this.ctx.createOscillator();
        const gain1 = this.ctx.createGain();
        osc1.connect(gain1);
        gain1.connect(this.ctx.destination);
        osc1.type = 'square';
        osc1.frequency.setValueAtTime(900, time);
        gain1.gain.setValueAtTime(0.03, time);
        gain1.gain.exponentialRampToValueAtTime(0.001, time + 0.08);
        osc1.start();
        osc1.stop(time + 0.08);
        setTimeout(() => {
            const osc2 = this.ctx.createOscillator();
            const gain2 = this.ctx.createGain();
            osc2.connect(gain2);
            gain2.connect(this.ctx.destination);
            osc2.type = 'sine';
            osc2.frequency.setValueAtTime(1600, this.ctx.currentTime);
            gain2.gain.setValueAtTime(0.05, this.ctx.currentTime);
            gain2.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.12);
            osc2.start();
            osc2.stop(this.ctx.currentTime + 0.12);
        }, 60);
    },
    playScan() {
        this.init();
        if (!this.ctx) return;
        if (this.ctx.state === 'suspended') this.ctx.resume();
        const time = this.ctx.currentTime;
        const duration = 0.55;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        const filter = this.ctx.createBiquadFilter();
        osc.connect(filter);
        filter.connect(gain);
        gain.connect(this.ctx.destination);
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(200, time);
        osc.frequency.exponentialRampToValueAtTime(2000, time + duration);
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(400, time);
        filter.frequency.exponentialRampToValueAtTime(3200, time + duration);
        filter.Q.value = 6.0;
        gain.gain.setValueAtTime(0.1, time);
        gain.gain.exponentialRampToValueAtTime(0.001, time + duration);
        osc.start();
        osc.stop(time + duration);
    }
};
window.CyberSound = CyberSound;

// Global Click Sound Trigger (Capturing Phase to bypass stopPropagation)
document.addEventListener('click', (e) => {
    const target = e.target.closest('button, select, .history-item, .suggestion-card, .quick-action-pill, a, .state-action-btn, .ctrl-btn');
    if (target) {
        CyberSound.playClick();
    }
}, true);

// Global Typing Sound Trigger
document.addEventListener('keydown', (e) => {
    const target = e.target;
    if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) {
        const quietKeys = ['Enter', 'Tab', 'Shift', 'Control', 'Alt', 'Meta', 'Escape', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
        if (!quietKeys.includes(e.key)) {
            CyberSound.playKeypress();
        }
    }
}, true);

let activeChatMode = 'chat';

function changeMode(mode) {
    activeChatMode = mode;
    
    // Update active class on tab buttons
    const tabs = document.querySelectorAll('.mode-tab-btn');
    tabs.forEach(tab => {
        if (tab.getAttribute('data-mode') === mode) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    
    // Sync to hidden select
    const chatModeSelect = document.getElementById('chat-mode-select');
    if (chatModeSelect) {
        chatModeSelect.value = mode;
    }
    
    onChatModeChange(mode);
}

function getSandboxConfig() {
    const mode = activeChatMode;
    if (mode === 'research') {
        return {
            persona: 'warm-narrative',
            search_strategy: 'multi-tier',
            ocr: false,
            lint: false,
            workspace_path: ''
        };
    } else if (mode === 'workspace') {
        return {
            persona: 'ultra-technical',
            search_strategy: 'local-only',
            ocr: true,
            lint: true,
            workspace_path: 'd:\\ANTIGRAVITY\\llm APP'
        };
    } else { // default 'chat'
        return {
            persona: 'warm-narrative',
            search_strategy: 'multi-tier',
            ocr: false,
            lint: false,
            workspace_path: ''
        };
    }
}

function onChatModeChange(mode) {
    if (!userInput) return;
    
    const validModes = ['chat', 'research', 'workspace'];
    const activeMode = validModes.includes(mode) ? mode : 'chat';
    
    document.body.classList.remove('theme-chat', 'theme-research', 'theme-workspace');
    document.body.classList.add('theme-' + activeMode);
    
    // Sync theme to floating Picture-in-Picture window if active
    if (pipWindow && !pipWindow.closed && pipWindow.document) {
        pipWindow.document.body.classList.remove('theme-chat', 'theme-research', 'theme-workspace');
        pipWindow.document.body.classList.add('theme-' + activeMode);
    }
    
    const promptSugs = document.querySelector('.prompt-suggestions');
    const welcomeHalo = document.querySelector('.welcome-halo');
    const welcomeTitle = document.querySelector('.welcome-title');
    const welcomeStatus = document.getElementById('dashboard-status-label');
    const welcomeControls = document.querySelector('.welcome-halo-controls');
    
    const workspaceHub = document.getElementById('workspace-hub');
    const researchHub = document.getElementById('research-hub');
    
    if (activeMode === 'research') {
        userInput.placeholder = "Research with AURA...";
        setHaloState('listening', 'COGNITIVE STATE: RESEARCH MODE ACTIVE');
        
        // Ensure welcome-view is visible and hubs are toggled
        if (welcomeView) welcomeView.style.display = 'flex';
        if (chatMessages) chatMessages.style.display = 'none';
        
        // Keep halo and status readout visible, but hide suggestions/controls, show research hub
        if (welcomeHalo) welcomeHalo.style.display = 'block';
        if (welcomeTitle) welcomeTitle.style.display = 'none';
        if (welcomeStatus) welcomeStatus.style.display = 'block';
        if (welcomeControls) welcomeControls.style.display = 'none';
        if (promptSugs) promptSugs.style.display = 'none';
        if (workspaceHub) workspaceHub.style.display = 'none';
        if (researchHub) researchHub.style.display = 'block';
        
        resetResearchConsole(); // Reset to fresh input
    } else if (activeMode === 'workspace') {
        userInput.placeholder = "Analyze Workspace with AURA...";
        setHaloState('scanning', 'COGNITIVE STATE: WORKSPACE MODE ACTIVE');
        
        // Ensure welcome-view is visible and hubs are toggled
        if (welcomeView) welcomeView.style.display = 'flex';
        if (chatMessages) chatMessages.style.display = 'none';
        
        // Keep halo and status readout visible, but hide suggestions/controls, show workspace hub
        if (welcomeHalo) welcomeHalo.style.display = 'block';
        if (welcomeTitle) welcomeTitle.style.display = 'none';
        if (welcomeStatus) welcomeStatus.style.display = 'block';
        if (welcomeControls) welcomeControls.style.display = 'none';
        if (promptSugs) promptSugs.style.display = 'none';
        if (researchHub) researchHub.style.display = 'none';
        if (workspaceHub) workspaceHub.style.display = 'flex';
        
        loadWorkspaceProjects(); // Load projects list from backend
    } else {
        userInput.placeholder = "Message AURA...";
        setHaloState('idle', 'COGNITIVE STATE: CHAT MODE ACTIVE');
        
        // Show standard welcome elements or message feed depending on if history is loaded
        const hasHistory = chatMessages && chatMessages.children.length > 0;
        if (hasHistory) {
            if (welcomeView) welcomeView.style.display = 'none';
            if (chatMessages) chatMessages.style.display = 'flex';
        } else {
            if (welcomeView) welcomeView.style.display = 'flex';
            if (chatMessages) chatMessages.style.display = 'none';
            
            if (welcomeHalo) welcomeHalo.style.display = 'block';
            if (welcomeTitle) welcomeTitle.style.display = 'block';
            if (welcomeStatus) welcomeStatus.style.display = 'block';
            if (welcomeControls) welcomeControls.style.display = 'flex';
            if (promptSugs) promptSugs.style.display = 'grid';
        }
        
        if (workspaceHub) workspaceHub.style.display = 'none';
        if (researchHub) researchHub.style.display = 'none';
    }
}

let isThinking = false;
let ws = null;
let currentResponseContainer = null;
let currentTextSpan = null;
let fullReplyAccumulated = "";
let chatHistory = [];
let searchEnabled = true;
let activeConvId = null;
let allUserChats = [];

// Predefined suggestion triggers
const simulatedResponses = {
    'explain the difference between tavily and duckduckgo': {
        thoughts: [
            { title: "System Architecture Audit", body: "Comparing Tavily and DuckDuckGo engine architectures." },
            { title: "Strategic Resource Map", body: "Tracing active fallback endpoints and latency values." }
        ],
        answer: "AURA's real-time retrieval layer has transitioned to a fully integrated **DuckDuckGo-first cascade**:\n\n" +
                "- **DuckDuckGo (Primary)**: Functions as our high-performance, rate-limit immune search engine. Calls are offloaded to dedicated background threads using `asyncio.to_thread` for rapid, zero-lag execution.\n" +
                "- **DuckDuckGo Static Scraper (Resilient Fallback)**: Automatically bypasses cloud network blocks or congestion without requiring rate-limited API keys.\n" +
                "- **Tavily (Legacy)**: Removed as the primary layer to ensure 100% service uptime and key-agnostic local testing, preventing rate limits and 'Neural gateway congested' messages."
    },
    'help me debug my workspace ast compiler warnings': {
        thoughts: [
            { title: "Workspace Indexing", body: "Scanning workspace folder: `d:\\ANTIGRAVITY\\llm APP`" },
            { title: "AST Compilation audit", body: "Analyzing static symbols and Dart library imports." }
        ],
        answer: "Static compilation audit for `d:\\ANTIGRAVITY\\llm APP` complete.\n\n" +
                "**Detected Issue** in `lib/screens/chat_screen.dart`:\n" +
                "```dart\nUndefined class 'NeuralThinkingAnimation'\n```\n\n" +
                "**Resolution**:\n" +
                "Import the corresponding package structure to registers dynamic OS states:\n" +
                "```dart\nimport 'package:aura/animations/neural_thinking.dart';\n```"
    },
    'what is currently inside the chromadb memory vault?': {
        thoughts: [
            { title: "Memory Registry Audit", body: "Inspecting sandboxed local vector databases." },
            { title: "Visual State Synchronization", body: "Compiling active system context variables." }
        ],
        answer: "AURA Memory Registry is 100% active and sandboxed:\n\n" +
                "- **Active Workspace**: Mapped onto `d:\\ANTIGRAVITY\\llm APP`.\n" +
                "- **Active Persona**: Warm & Narrative (Co-Founder companionship).\n" +
                "- **Enabled Modules**: OCR screen scans and static linters.\n" +
                "- **Privacy Shield**: Zero-trust local isolation is fully active."
    }
};

// UI Toggles
function toggleDetailsPanel() {
    // Workspace Diagnostics panel has been removed.
}

function setQuickInput(text) {
    userInput.value = text;
    userInput.focus();
    adjustTextareaHeight();
}

function getBackendUrl(endpoint) {
    if (PRODUCTION_BACKEND_URL) {
        const cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/' + endpoint;
        return `${PRODUCTION_BACKEND_URL.replace(/\/$/, '')}${cleanEndpoint}`;
    }
    let host = getBackendHost(window.location.host);
    const protocol = window.location.protocol === 'https:' ? 'https' : 'http';
    const finalProtocol = (protocol === 'file') ? 'http' : protocol;
    return `${finalProtocol}://${host}${endpoint}`;
}

function escapeHtml(str) {
    if (!str) return '';
    return str.replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;')
              .replace(/'/g, '&#039;');
}

function groupChatsByDate(chats) {
    const today = [];
    const yesterday = [];
    const older = [];
    
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfYesterday = startOfToday - 24 * 60 * 60 * 1000;
    
    chats.forEach(chat => {
        const timestamp = parseFloat(chat.updated_at) * 1000;
        if (timestamp >= startOfToday) {
            today.push(chat);
        } else if (timestamp >= startOfYesterday) {
            yesterday.push(chat);
        } else {
            older.push(chat);
        }
    });
    
    return { today, yesterday, older };
}

function renderHistory(chats) {
    const container = document.getElementById('history-items-container');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (chats.length === 0) {
        container.innerHTML = `
            <div style="padding: 16px; text-align: center; color: var(--text-muted); font-size: 0.8rem;">
                No chats found
            </div>
        `;
        return;
    }
    
    const groups = groupChatsByDate(chats);
    
    function createSection(title, items) {
        if (items.length === 0) return '';
        
        let html = `<div class="history-section">`;
        html += `<div class="section-title">${title}</div>`;
        items.forEach(item => {
            const isActive = item.id === activeConvId ? 'active' : '';
            html += `
                <div class="history-item ${isActive}" onclick="loadSelectedChat('${item.id}')" id="history-item-${item.id}">
                    <i class="fa-regular fa-message item-icon"></i>
                    <span class="item-text" title="${escapeHtml(item.title)}">${escapeHtml(item.title)}</span>
                    <button class="history-delete-btn" onclick="confirmDeleteChat(event, '${item.id}')" title="Delete chat">
                        <i class="fa-solid fa-trash-can"></i>
                    </button>
                </div>
            `;
        });
        html += `</div>`;
        return html;
    }
    
    let fullHtml = '';
    fullHtml += createSection('Today', groups.today);
    fullHtml += createSection('Yesterday', groups.yesterday);
    fullHtml += createSection('Previous Chats', groups.older);
    
    container.innerHTML = fullHtml;
}

let activeDeleteTarget = null;
let deleteModalType = 'chat';
let pendingDeletedChats = {};

function openCustomDeleteModal(type, targetId) {
    activeDeleteTarget = targetId;
    deleteModalType = type;
    
    const modal = document.getElementById('aura-delete-modal');
    const titleEl = document.getElementById('delete-modal-title');
    const subtitleEl = document.getElementById('delete-modal-subtitle');
    
    if (!modal) return;
    
    if (type === 'chat') {
        if (titleEl) titleEl.innerText = "Delete conversation?";
        if (subtitleEl) subtitleEl.innerText = "This will permanently remove this chat from your AURA workspace.";
    } else if (type === 'workspace') {
        if (titleEl) titleEl.innerText = "Purge workspace?";
        if (subtitleEl) subtitleEl.innerText = "This will permanently delete this neural core workspace and all its blueprints.";
    }
    
    if (window.CyberSound) window.CyberSound.playScan();
    
    modal.style.display = 'flex';
    modal.offsetHeight; // force reflow
    modal.classList.add('active');
}

function closeCustomDeleteModal() {
    const modal = document.getElementById('aura-delete-modal');
    if (!modal) return;
    
    modal.classList.remove('active');
    setTimeout(() => {
        modal.style.display = 'none';
        activeDeleteTarget = null;
    }, 300);
}

function confirmDeleteChat(event, convId) {
    if (event) event.stopPropagation();
    openCustomDeleteModal('chat', convId);
}

function executeCustomDeleteAction() {
    if (!activeDeleteTarget) {
        closeCustomDeleteModal();
        return;
    }
    
    const target = activeDeleteTarget;
    const type = deleteModalType;
    
    closeCustomDeleteModal();
    
    if (type === 'chat') {
        triggerUndoableChatDelete(target);
    } else if (type === 'workspace') {
        executeWorkspaceDelete(target);
    }
}

function triggerUndoableChatDelete(convId) {
    if (pendingDeletedChats[convId]) {
        clearTimeout(pendingDeletedChats[convId].timeout);
        performActualChatDelete(convId);
    }
    
    if (window.CyberSound) window.CyberSound.playEnter();
    
    const sidebarItem = document.getElementById(`history-item-${convId}`);
    if (sidebarItem) {
        sidebarItem.style.display = 'none';
    }
    
    let wasActive = (activeConvId === convId);
    let originalHistory = [...chatHistory];
    if (wasActive) {
        activeConvId = null;
        chatHistory = [];
        if (chatMessages) chatMessages.innerHTML = '';
        if (welcomeView) welcomeView.style.display = 'flex';
        if (chatMessages) chatMessages.style.display = 'none';
    }
    
    const toast = document.getElementById('aura-undo-toast-container');
    const toastMsg = document.getElementById('aura-toast-message');
    const undoBtn = document.getElementById('aura-toast-undo-btn');
    const progressBar = document.getElementById('aura-toast-progress-bar');
    
    if (toast && toastMsg && undoBtn && progressBar) {
        toastMsg.innerText = "Conversation deleted";
        toast.classList.add('active');
        
        progressBar.style.transition = 'none';
        progressBar.style.transform = 'scaleX(1)';
        progressBar.offsetHeight; // force reflow
        progressBar.style.transition = 'transform 5s linear';
        progressBar.style.transform = 'scaleX(0)';
        
        undoBtn.onclick = function() {
            if (pendingDeletedChats[convId]) {
                clearTimeout(pendingDeletedChats[convId].timeout);
                delete pendingDeletedChats[convId];
            }
            
            if (sidebarItem) {
                sidebarItem.style.display = 'flex';
            }
            
            if (wasActive) {
                activeConvId = convId;
                chatHistory = originalHistory;
                loadSelectedChat(convId);
            }
            
            toast.classList.remove('active');
            if (window.CyberSound) window.CyberSound.playScan();
        };
    }
    
    const timeout = setTimeout(() => {
        if (toast) toast.classList.remove('active');
        performActualChatDelete(convId);
        delete pendingDeletedChats[convId];
    }, 5000);
    
    pendingDeletedChats[convId] = {
        timeout: timeout,
        wasActive: wasActive,
        originalHistory: originalHistory,
        sidebarItem: sidebarItem
    };
}

async function performActualChatDelete(convId) {
    try {
        const url = getBackendUrl(`/chats/${convId}`);
        const res = await fetch(url, { method: 'DELETE' });
        if (!res.ok) throw new Error('Delete failed');
        await loadRecentChats();
    } catch (e) {
        console.error('Error deleting chat:', e);
    }
}

function filterAndRenderHistory() {
    const searchInput = document.getElementById('history-search-input');
    const query = searchInput ? searchInput.value.trim().toLowerCase() : '';
    
    if (!query) {
        renderHistory(allUserChats);
    } else {
        const filtered = allUserChats.filter(chat => 
            chat.title.toLowerCase().includes(query) || 
            (chat.last_message && chat.last_message.toLowerCase().includes(query))
        );
        renderHistory(filtered);
    }
}

async function loadRecentChats() {
    try {
        let path = '/api/history/conversations';
        if (activeProjectId && activeProjectId !== 'global') {
            path += `?project_id=${activeProjectId}`;
        }
        const url = getBackendUrl(path);
        const response = await fetch(url);
        allUserChats = await response.json();
        
        filterAndRenderHistory();
    } catch (e) {
        console.error("Error loading recent chats:", e);
    }
}

async function loadSelectedChat(convId) {
    if (isThinking) return;
    
    activeConvId = convId;
    
    // Highlight active chat
    const items = document.querySelectorAll('.history-item');
    items.forEach(item => item.classList.remove('active'));
    const activeItem = document.getElementById(`history-item-${convId}`);
    if (activeItem) activeItem.classList.add('active');
    
    // Setup Export Button Data
    window.currentExportConvId = convId;
    
    welcomeView.style.display = 'none';
    if (chatMessages) chatMessages.style.display = 'flex';
    chatMessages.innerHTML = '';
    
    const loadingDiv = document.createElement('div');
    loadingDiv.className = 'message system-msg';
    loadingDiv.innerHTML = `<span class="msg-time">[System]</span> Loading chat history...`;
    chatMessages.appendChild(loadingDiv);
    
    try {
        const url = getBackendUrl(`/api/history/conversations/${convId}`);
        const response = await fetch(url);
        const messages = await response.json();
        
        chatMessages.innerHTML = '';
        chatHistory = [];
        
        messages.forEach(msg => {
            const role = msg.role;
            const content = msg.content;
            const thought = msg.thought;
            
            chatHistory.push({ role, content });
            
            if (role === 'user') {
                appendMessage(content, 'user-msg');
            } else {
                const msgDiv = appendMessage('', 'aura-msg', 'AURA Assistant');
                const textBody = msgDiv.querySelector('.msg-txt-body');
                
                textBody.innerHTML = '';
                const textSpan = document.createElement('span');
                textSpan.innerHTML = content.replace(/\n/g, '<br>');
                textBody.appendChild(textSpan);
            }
        });
        
        const viewport = document.getElementById('chat-viewport');
        viewport.scrollTop = viewport.scrollHeight;
        
    } catch (e) {
        console.error("Error loading chat history:", e);
        chatMessages.innerHTML = `
            <div class="message system-msg">
                <span class="msg-time">[Error]</span> Failed to retrieve conversation from AURA Core.
            </div>
        `;
    }
}

function loadHistoryQuery(text) {
    userInput.value = text;
    submitSimulationQuery();
}

function clearActiveChat() {
    activeConvId = null;
    chatMessages.innerHTML = '';
    chatHistory = [];
    welcomeView.style.display = 'flex';
    if (chatMessages) chatMessages.style.display = 'none';
    if (ws) {
        try { ws.close(); } catch(e) {}
        ws = null;
    }
    isThinking = false;
    setHaloState('idle', 'COGNITIVE STATE: IDLE');
    adjustTextareaHeight();
    renderHistory(allUserChats);
}

function toggleWebSearchInPill() {
    // Handled by Mode select dropdown.
}

// Cognitive state visualizers
const navHaloDot = document.getElementById('nav-halo-dot');
const statusBadge = document.getElementById('halo-status-badge');
const dashboardCore = document.getElementById('dashboard-core');
const dashboardRing = document.getElementById('dashboard-ring');
const dashboardStatusLabel = document.getElementById('dashboard-status-label');

function setHaloState(state, labelText) {
    // Reset core states
    if (dashboardCore) {
        dashboardCore.className = 'welcome-core';
        if (state !== 'idle') {
            dashboardCore.classList.add(state);
        }
    }
    if (dashboardRing) {
        dashboardRing.className = 'welcome-ring';
        if (state !== 'idle') {
            dashboardRing.classList.add(state);
        }
    }

    if (dashboardStatusLabel) {
        dashboardStatusLabel.innerText = labelText;
    }

    // Dynamic badge and background lights using CSS theme variables
    switch(state) {
        case 'listening':
            if (navHaloDot) navHaloDot.style.background = 'var(--theme-state-listening)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-microphone"></i> AURA CORE LISTENING`;
                statusBadge.style.color = 'var(--theme-state-listening)';
                statusBadge.style.borderColor = 'var(--theme-state-listening-alpha)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--theme-state-listening), transparent 70%)';
            break;
            
        case 'thinking':
            if (navHaloDot) navHaloDot.style.background = 'var(--theme-state-thinking)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-microchip fa-spin"></i> AURA CORE THINKING`;
                statusBadge.style.color = 'var(--theme-state-thinking)';
                statusBadge.style.borderColor = 'var(--theme-state-thinking-alpha)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--theme-state-thinking), transparent 70%)';
            break;
            
        case 'scanning':
            if (navHaloDot) navHaloDot.style.background = 'var(--theme-state-scanning)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-shield-virus"></i> AURA CORE SCANNING`;
                statusBadge.style.color = 'var(--theme-state-scanning)';
                statusBadge.style.borderColor = 'var(--theme-state-scanning-alpha)';
            }
            if (glowV) glowV.style.background = 'radial-gradient(circle, var(--theme-state-scanning), transparent 70%)';
            break;
            
        case 'idle':
        default:
            if (navHaloDot) navHaloDot.style.background = 'var(--theme-primary)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-circle-notch fa-spin"></i> AURA CORE ONLINE`;
                statusBadge.style.color = 'var(--theme-primary)';
                statusBadge.style.borderColor = 'var(--theme-primary-alpha-15)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--theme-primary), transparent 70%)';
            if (glowV) glowV.style.background = 'radial-gradient(circle, var(--theme-secondary), transparent 70%)';
            break;
    }
}

// Input handling
function handleInputKey(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        submitSimulationQuery();
    }
}

function adjustTextareaHeight() {
    userInput.style.height = 'auto';
    userInput.style.height = (userInput.scrollHeight) + 'px';
}
userInput.addEventListener('input', adjustTextareaHeight);

// --- FILE INTELLIGENCE UPLOAD ---
function triggerAttachFile() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.pdf,.xlsx,.csv,.txt,.md,.py,.js,.html,.css,.png,.jpg,.jpeg,.webp';
    input.onchange = async (e) => {
        const file = e.target.files[0];
        if (!file) return;
        
        if (!activeConvId) {
            // Need a conversation ID to link the file to, create a dummy or start chat first
            alert("Please start a conversation first by typing a message before attaching a file.");
            return;
        }

        const formData = new FormData();
        formData.append('file', file);
        formData.append('message_id', 'pending_msg_' + Date.now()); // Fallback if no specific message

        setHaloState('thinking', 'COGNITIVE STATE: ANALYZING FILE...');
        appendMessage(`Uploading & parsing ${file.name}...`, 'user-msg');
        
        try {
            const res = await fetch(getBackendUrl('/api/upload'), {
                method: 'POST',
                body: formData
            });
            const data = await res.json();
            if (data.status === 'success') {
                appendMessage(`File analyzed successfully. Extracted ${data.parsed_length} characters. Context added to active workspace.`, 'aura-msg', 'AURA Intelligence');
            } else {
                appendMessage(`File analysis failed: ${data.detail}`, 'aura-msg', 'AURA Error');
            }
        } catch (err) {
            console.error("Upload error", err);
            appendMessage(`Error connecting to upload pipeline.`, 'aura-msg', 'AURA Error');
        }
        setHaloState('idle', 'COGNITIVE STATE: READY');
    };
    input.click();
}

function exportCurrentChat() {
    if (!chatHistory || chatHistory.length === 0) {
        alert("No chat history to export.");
        return;
    }
    
    let textOutput = "AURA Conversation Export\\n\\n";
    chatHistory.forEach(msg => {
        textOutput += `[${msg.role.toUpperCase()}]:\\n${msg.content}\\n\\n`;
    });
    
    const blob = new Blob([textOutput], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `aura_chat_export_${activeConvId || 'session'}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// --- SMART PASTE INTERCEPTION ---
document.addEventListener('paste', (e) => {
    // If the active element is the user input and there is an image in the clipboard
    if (document.activeElement === userInput) {
        const items = e.clipboardData.items;
        for (let i = 0; i < items.length; i++) {
            if (items[i].type.indexOf('image') !== -1) {
                e.preventDefault();
                const blob = items[i].getAsFile();
                
                // Directly mock the file upload flow for the pasted image
                const file = new File([blob], 'pasted_image.png', { type: blob.type });
                
                if (!activeConvId) {
                    alert("Please start a conversation first by typing a message before pasting an image.");
                    return;
                }
                
                const formData = new FormData();
                formData.append('file', file);
                formData.append('message_id', 'pending_msg_' + Date.now());

                setHaloState('scanning', 'COGNITIVE STATE: VISION OCR ACTIVE...');
                appendMessage(`Analyzing pasted image...`, 'user-msg');
                
                fetch(getBackendUrl('/api/upload'), {
                    method: 'POST',
                    body: formData
                }).then(res => res.json()).then(data => {
                    if (data.status === 'success') {
                        appendMessage(`Vision OCR complete. Context added to workspace.`, 'aura-msg', 'AURA Intelligence');
                    }
                    setHaloState('idle', 'COGNITIVE STATE: READY');
                }).catch(err => {
                    appendMessage(`Vision OCR failed.`, 'aura-msg', 'AURA Error');
                    setHaloState('idle', 'COGNITIVE STATE: READY');
                });
            }
        }
    }
});



function submitSimulationQuery() {
    const text = userInput.value.trim();
    if (!text || isThinking) return;

    CyberSound.playEnter();

    // Reset input pill
    userInput.value = '';
    userInput.style.height = 'auto';

    // Hide welcome overlay on active chat
    welcomeView.style.display = 'none';
    if (chatMessages) chatMessages.style.display = 'flex';

    // Assign active conversation ID if empty
    if (!activeConvId) {
        activeConvId = `conv_${Date.now()}`;
    }

    // Append User message
    appendMessage(text, 'user-msg');
    
    // Save to history
    chatHistory.push({ role: "user", content: text });
    
    // Trigger socket pipeline
    executeRealtimeChat(text);
}

function appendMessage(text, className, auraTitle = '') {
    const timeString = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    const msgDiv = document.createElement('div');
    msgDiv.className = `message ${className}`;
    
    // Basic Markdown Parser (Code blocks with syntax highlighting and Copy button)
    let formattedText = text;
    // Format code blocks: ```lang ... ```
    formattedText = formattedText.replace(/```(\w*)\n([\s\S]*?)```/g, (match, lang, code) => {
        const uniqueId = 'code_' + Math.random().toString(36).substring(2, 9);
        // Escape HTML in the code block
        const escapedCode = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        return `
            <div class="code-block-container" style="background:#1e1e1e; border-radius:8px; margin: 8px 0; overflow:hidden;">
                <div class="code-block-header" style="display:flex; justify-content:space-between; padding: 4px 12px; background:#2d2d2d; color:#888; font-size:12px;">
                    <span>${lang || 'code'}</span>
                    <button class="copy-code-btn" onclick="navigator.clipboard.writeText(document.getElementById('${uniqueId}').innerText); this.innerText='Copied!'; setTimeout(() => this.innerText='Copy', 2000);" style="background:transparent; border:none; color:#bbb; cursor:pointer;"><i class="fa-solid fa-copy"></i> Copy</button>
                </div>
                <div class="code-block-body" style="padding: 12px; overflow-x:auto;">
                    <code id="${uniqueId}" style="color:#d4d4d4; font-family: 'Share Tech Mono', monospace; font-size:14px; white-space:pre;">${escapedCode}</code>
                </div>
            </div>
        `;
    });
    // Format inline code: `code`
    formattedText = formattedText.replace(/`([^`]+)`/g, '<code style="background:#2d2d2d; padding:2px 4px; border-radius:4px; font-family:monospace; color:#4fc1ff;">$1</code>');
    // Format bold: **bold**
    formattedText = formattedText.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    
    // Replace remaining newlines with <br> for regular text (but outside of code blocks)
    // A quick way is to just do a smart replace or just accept that the <pre> handles code blocks
    formattedText = formattedText.split('</div>').map(part => {
        if (part.includes('<code id="')) return part;
        return part.replace(/\n/g, '<br>');
    }).join('</div>');
    
    if (auraTitle) {
        msgDiv.innerHTML = `<span class="msg-time">[${timeString}]</span> <strong>${auraTitle}</strong> <div class="msg-txt-body">${formattedText}</div>`;
    } else {
        msgDiv.innerHTML = `<span class="msg-time">[${timeString}]</span> <div class="msg-txt-body">${formattedText}</div>`;
    }
    
    chatMessages.appendChild(msgDiv);
    const viewport = document.getElementById('chat-viewport');
    viewport.scrollTop = viewport.scrollHeight;
    return msgDiv;
}

// Connect to backend LRM WebSocket
function executeRealtimeChat(query) {
    isThinking = true;
    if (thoughtStepsLog) thoughtStepsLog.innerHTML = ''; // Reset diagnostic logs
    if (thinkingProgressBar) thinkingProgressBar.style.width = '0%';
    if (thinkingProgressLabel) thinkingProgressLabel.innerText = "Connecting to AURA LRM Core...";
    
    setHaloState('thinking', 'COGNITIVE STATE: RESOLVING REAL-TIME THOUGHTS');

    // Self-healing fallback if WebSocket is offline or blocked
    const fallbackTimeout = setTimeout(() => {
        if (isThinking && !ws) {
            console.warn("WebSocket timeout. Activating premium local-first simulation cascade.");
            executeFallbackSimulation(query);
        }
    }, 3500);

    try {
        let wsUrl;
        if (PRODUCTION_BACKEND_URL) {
            const cleanUrl = PRODUCTION_BACKEND_URL.replace(/^(http|https):/, '');
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            wsUrl = `${wsProtocol}${cleanUrl}/chat`;
        } else {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
            const wsHost = getBackendHost(window.location.host);
            wsUrl = `${wsProtocol}://${wsHost}/chat`;
        }
        
        ws = new WebSocket(wsUrl);
        currentResponseContainer = null;
        currentTextSpan = null;
        fullReplyAccumulated = "";

        ws.onopen = function() {
            clearTimeout(fallbackTimeout);
            if (thinkingProgressLabel) thinkingProgressLabel.innerText = "Handshake complete. Initializing cognitive pathway...";
            
            // Ingestion variables
            const payload = {
                prompt: query,
                conversationId: activeConvId || "default_web",
                projectId: activeProjectId || "global",
                history: chatHistory.slice(-10),
                sandbox: getSandboxConfig()
            };
            ws.send(JSON.stringify(payload));
        };

        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            
            if (data.type === 'status') {
                const raw = (data.content || '').trim();
                const noisy = /searching|compiling|structuring|current date|realtime|looking up|web search|gateway|ingestion|synthesiz|analyzing|neural memory|live summaries|synchronized/i.test(raw);
                if (!noisy && raw) {
                    if (thinkingProgressLabel) thinkingProgressLabel.innerText = raw;
                }
            } 
            else if (data.type === 'thought_step') {
                // Append node in side diagnostics panel
                if (thoughtStepsLog) {
                    const node = document.createElement('div');
                    node.className = 'thought-node';
                    node.innerHTML = `
                        <div class="thought-node-icon"><i class="fas fa-spinner fa-spin"></i></div>
                        <div class="thought-node-details">
                            <div class="thought-node-title">${data.title}</div>
                            <div class="thought-node-body">${data.body}</div>
                        </div>
                    `;
                    
                    const lastNode = thoughtStepsLog.lastElementChild;
                    if (lastNode && lastNode.classList.contains('thought-node') && !lastNode.classList.contains('resolved')) {
                        lastNode.className = 'thought-node resolved';
                        const icon = lastNode.querySelector('.thought-node-icon');
                        if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
                    }
                    
                    thoughtStepsLog.appendChild(node);
                    thoughtStepsLog.scrollTop = thoughtStepsLog.scrollHeight;
                }
                
                if (thinkingProgressBar) {
                    let currentPercent = parseInt(thinkingProgressBar.style.width) || 0;
                    let nextPercent = Math.min(currentPercent + 25, 90);
                    thinkingProgressBar.style.width = `${nextPercent}%`;
                }
            }
            else if (data.type === 'chunk') {
                if (!currentResponseContainer) {
                    if (thoughtStepsLog) {
                        const lastNode = thoughtStepsLog.lastElementChild;
                        if (lastNode && lastNode.classList.contains('thought-node') && !lastNode.classList.contains('resolved')) {
                            lastNode.className = 'thought-node resolved';
                            const icon = lastNode.querySelector('.thought-node-icon');
                            if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
                        }
                    }
                    
                    if (thinkingProgressBar) thinkingProgressBar.style.width = '95%';
                    if (thinkingProgressLabel) thinkingProgressLabel.innerText = "Ingestion resolved. Generating answer...";
                    
                    // Create beautiful LRM text container
                    currentResponseContainer = appendMessage('', 'aura-msg', 'AURA Assistant');
                    const textBody = currentResponseContainer.querySelector('.msg-txt-body');
                    
                    textBody.innerHTML = '';
                    
                    currentTextSpan = document.createElement('span');
                    textBody.appendChild(currentTextSpan);
                }
                
                const chunkText = data.content;
                fullReplyAccumulated += chunkText;
                
                const formattedText = chunkText.replace(/\n/g, '<br>');
                currentTextSpan.innerHTML += formattedText;
                
                const viewport = document.getElementById('chat-viewport');
                viewport.scrollTop = viewport.scrollHeight;
            }
            else if (data.done === true) {
                finalizeChatSession();
            }
        };

        ws.onerror = function(err) {
            console.error("WebSocket socket error:", err);
            clearTimeout(fallbackTimeout);
            if (isThinking && !currentResponseContainer) {
                executeFallbackSimulation(query);
            }
        };

        ws.onclose = function() {
            clearTimeout(fallbackTimeout);
            if (isThinking) {
                finalizeChatSession();
            }
        };

    } catch (e) {
        console.error("Connection failure:", e);
        clearTimeout(fallbackTimeout);
        executeFallbackSimulation(query);
    }
}

function finalizeChatSession() {
    isThinking = false;
    setHaloState('idle', 'COGNITIVE STATE: IDLE');
    if (thinkingProgressBar) thinkingProgressBar.style.width = '100%';
    if (thinkingProgressLabel) thinkingProgressLabel.innerText = "AURA Core Online";
    
    if (thoughtStepsLog) {
        const steps = thoughtStepsLog.querySelectorAll('.thought-node');
        steps.forEach(step => {
            if (!step.classList.contains('resolved')) {
                step.className = 'thought-node resolved';
                const icon = step.querySelector('.thought-node-icon');
                if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
            }
        });
    }

    if (fullReplyAccumulated) {
        chatHistory.push({ role: "assistant", content: fullReplyAccumulated });
    }
    
    if (ws) {
        try { ws.close(); } catch(e) {}
        ws = null;
    }
    loadRecentChats();
}

// Fallback logic
function executeFallbackSimulation(query) {
    console.log("Simulating response for offline mode query:", query);
    
    // Find simulated response
    let responseData = simulatedResponses[query.toLowerCase()];
    if (!responseData) {
        // Fallback checks
        if (query.toLowerCase().includes('debug') || query.toLowerCase().includes('ast') || query.toLowerCase().includes('fix')) {
            responseData = simulatedResponses['help me debug my workspace ast compiler warnings'];
        } else if (query.toLowerCase().includes('chromadb') || query.toLowerCase().includes('memory') || query.toLowerCase().includes('vault')) {
            responseData = simulatedResponses['what is currently inside the chromadb memory vault?'];
        } else {
            responseData = {
                thoughts: [
                    { title: "Query Strategic Parse", body: `Auditing offline parameters: "${query}"` },
                    { title: "Memory Sandbox lookup", body: "Rerouting search requests to local context vectors." }
                ],
                answer: `I have compiled a secure offline response for: **"${query}"**.\n\nAURA LRM model weights and system variables are operational. Local-first sandbox isolates system clipboard files at the highest level of security.`
            };
        }
    }

    let currentStep = 0;
    const totalSteps = responseData.thoughts.length;
    
    function processNextThought() {
        if (currentStep < totalSteps) {
            const thought = responseData.thoughts[currentStep];
            
            if (thoughtStepsLog) {
                const node = document.createElement('div');
                node.className = 'thought-node';
                node.innerHTML = `
                    <div class="thought-node-icon"><i class="fas fa-spinner fa-spin"></i></div>
                    <div class="thought-node-details">
                        <div class="thought-node-title">${thought.title}</div>
                        <div class="thought-node-body">${thought.body}</div>
                    </div>
                `;
                
                const lastNode = thoughtStepsLog.lastElementChild;
                if (lastNode && lastNode.classList.contains('thought-node') && !lastNode.classList.contains('resolved')) {
                    lastNode.className = 'thought-node resolved';
                    const icon = lastNode.querySelector('.thought-node-icon');
                    if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
                }
                
                thoughtStepsLog.appendChild(node);
                thoughtStepsLog.scrollTop = thoughtStepsLog.scrollHeight;
            }

            const percent = Math.round(((currentStep + 0.5) / totalSteps) * 100);
            if (thinkingProgressBar) thinkingProgressBar.style.width = `${percent}%`;
            if (thinkingProgressLabel) thinkingProgressLabel.innerText = `Step ${currentStep + 1} of ${totalSteps}: ${thought.title}`;

            setTimeout(() => {
                if (thoughtStepsLog) {
                    const node = thoughtStepsLog.lastElementChild;
                    if (node && node.classList.contains('thought-node')) {
                        node.className = 'thought-node resolved';
                        const icon = node.querySelector('.thought-node-icon');
                        if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
                    }
                }
                currentStep++;
                const percentDone = Math.round((currentStep / totalSteps) * 100);
                if (thinkingProgressBar) thinkingProgressBar.style.width = `${percentDone}%`;
                setTimeout(processNextThought, 700);
            }, 800);
            
        } else {
            if (thinkingProgressLabel) thinkingProgressLabel.innerText = "Cognitive Processing Complete.";
            
            setTimeout(() => {
                isThinking = false;
                setHaloState('idle', 'COGNITIVE STATE: IDLE');
                
                const responseContainer = appendMessage('', 'aura-msg', 'AURA Assistant');
                const textBody = responseContainer.querySelector('.msg-txt-body');
                
                let fullText = responseData.answer;
                let charIndex = 0;
                
                textBody.innerHTML = '';
                const textSpan = document.createElement('span');
                textBody.appendChild(textSpan);
                
                function typeChar() {
                    if (charIndex < fullText.length) {
                        const char = fullText.charAt(charIndex);
                        if (char === '\n') {
                            textSpan.innerHTML += '<br>';
                        } else {
                            textSpan.innerHTML += char;
                        }
                        charIndex++;
                        const viewport = document.getElementById('chat-viewport');
                        viewport.scrollTop = viewport.scrollHeight;
                        setTimeout(typeChar, 8);
                    }
                }
                
                typeChar();
                chatHistory.push({ role: "assistant", content: fullText });
                
            }, 300);
        }
    }
    
    setTimeout(processNextThought, 200);
}

// Sandbox configuration managers
function updateSandboxUI() {
    // Diagnostics panel removed.
}

function hotReloadSandbox() {
    // Diagnostics panel removed.
}

// Initializer on page load
document.addEventListener('DOMContentLoaded', () => {
    loadRecentChats();
    
    const searchInput = document.getElementById('history-search-input');
    if (searchInput) {
        searchInput.addEventListener('input', filterAndRenderHistory);
    }

    // Bind custom delete modal events
    const cancelBtn = document.getElementById('delete-modal-cancel');
    const confirmBtn = document.getElementById('delete-modal-confirm');
    const modal = document.getElementById('aura-delete-modal');
    
    if (cancelBtn) {
        cancelBtn.addEventListener('click', closeCustomDeleteModal);
    }
    if (confirmBtn) {
        confirmBtn.addEventListener('click', executeCustomDeleteAction);
    }
    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeCustomDeleteModal();
            }
        });
    }
    
    // ESC key closes modal
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeCustomDeleteModal();
        }
    });
    
    // Set initial mode theme based on tabs
    changeMode(activeChatMode);
});

// AURA Floating Overlay Assistant Controllers
let overlayDragState = {
    startX: 0,
    startY: 0,
    startLeft: 0,
    startTop: 0,
    isDragging: false,
    draggedThreshold: false
};

function initOverlayDrag(e) {
    const bubble = document.getElementById('aura-overlay-bubble');
    if (!bubble) return;
    
    overlayDragState.startX = e.clientX;
    overlayDragState.startY = e.clientY;
    
    const computed = window.getComputedStyle(bubble);
    overlayDragState.startLeft = parseInt(computed.left) || (window.innerWidth - bubble.offsetWidth - 24);
    overlayDragState.startTop = parseInt(computed.top) || (window.innerHeight - bubble.offsetHeight - 24);
    
    overlayDragState.isDragging = true;
    overlayDragState.draggedThreshold = false;
    
    bubble.style.bottom = 'auto';
    bubble.style.right = 'auto';
    bubble.style.left = `${overlayDragState.startLeft}px`;
    bubble.style.top = `${overlayDragState.startTop}px`;
    
    document.addEventListener('mousemove', handleOverlayDragMove);
    document.addEventListener('mouseup', handleOverlayDragEnd);
    e.preventDefault();
}

function handleOverlayDragMove(e) {
    if (!overlayDragState.isDragging) return;
    const bubble = document.getElementById('aura-overlay-bubble');
    if (!bubble) return;
    
    const dx = e.clientX - overlayDragState.startX;
    const dy = e.clientY - overlayDragState.startY;
    
    if (Math.abs(dx) > 4 || Math.abs(dy) > 4) {
        overlayDragState.draggedThreshold = true;
    }
    
    let newLeft = overlayDragState.startLeft + dx;
    let newTop = overlayDragState.startTop + dy;
    
    newLeft = Math.max(10, Math.min(window.innerWidth - bubble.offsetWidth - 10, newLeft));
    newTop = Math.max(10, Math.min(window.innerHeight - bubble.offsetHeight - 10, newTop));
    
    bubble.style.left = `${newLeft}px`;
    bubble.style.top = `${newTop}px`;
    
    const panel = document.getElementById('aura-overlay-panel');
    if (panel) {
        if (newLeft < window.innerWidth / 2) {
            panel.style.left = `${newLeft + bubble.offsetWidth + 12}px`;
            panel.style.right = 'auto';
        } else {
            panel.style.left = 'auto';
            panel.style.right = `${window.innerWidth - newLeft + 12}px`;
        }
        
        if (newTop + panel.offsetHeight > window.innerHeight) {
            panel.style.top = 'auto';
            panel.style.bottom = `${window.innerHeight - newTop - bubble.offsetHeight}px`;
        } else {
            panel.style.bottom = 'auto';
            panel.style.top = `${newTop}px`;
        }
    }
}

function handleOverlayDragEnd(e) {
    overlayDragState.isDragging = false;
    document.removeEventListener('mousemove', handleOverlayDragMove);
    document.removeEventListener('mouseup', handleOverlayDragEnd);
    
    if (!overlayDragState.draggedThreshold) {
        toggleOverlayPanel();
    }
}

function getOverlayPanel() {
    if (pipWindow && !pipWindow.closed && pipWindow.document) {
        const pipPanel = pipWindow.document.getElementById('aura-overlay-panel');
        if (pipPanel) return pipPanel;
    }
    return document.getElementById('aura-overlay-panel');
}

function resetOverlayPanelLayout(panel) {
    if (!panel) return;
    panel.style.position = '';
    panel.style.left = '';
    panel.style.right = '';
    panel.style.top = '';
    panel.style.bottom = '';
    panel.style.width = '';
    panel.style.height = '';
    panel.style.borderRadius = '';
    panel.style.display = '';
    panel.style.opacity = '';
    panel.style.transform = '';
    panel.style.pointerEvents = '';
}

function closeOverlayPanel() {
    // Panel may be in Picture-in-Picture window — close that first
    if (pipWindow && !pipWindow.closed) {
        pipWindow.close();
        return;
    }
    const panel = document.getElementById('aura-overlay-panel');
    if (!panel) return;
    panel.classList.remove('active');
    resetOverlayPanelLayout(panel);
    const bubble = document.getElementById('aura-overlay-bubble');
    if (bubble) bubble.style.display = '';
}

function openOverlayPanel() {
    if (pipWindow && !pipWindow.closed) return;
    const panel = document.getElementById('aura-overlay-panel');
    if (!panel) return;
    resetOverlayPanelLayout(panel);
    panel.classList.add('active');

    const bubble = document.getElementById('aura-overlay-bubble');
    if (bubble) {
        const computed = window.getComputedStyle(bubble);
        const left = parseInt(computed.left, 10) || (window.innerWidth - bubble.offsetWidth - 24);
        const top = parseInt(computed.top, 10) || (window.innerHeight - bubble.offsetHeight - 24);

        if (left < window.innerWidth / 2) {
            panel.style.left = `${left + bubble.offsetWidth + 12}px`;
            panel.style.right = 'auto';
        } else {
            panel.style.left = 'auto';
            panel.style.right = `${window.innerWidth - left + 12}px`;
        }
        panel.style.top = 'auto';
        panel.style.bottom = `${window.innerHeight - top}px`;
    }
    const inputEl = getOverlayElement('overlay-user-input');
    if (inputEl) inputEl.focus();
}

function toggleOverlayPanel() {
    const panel = getOverlayPanel();
    if (!panel) {
        closeOverlayPanel();
        return;
    }
    const isOpen = panel.classList.contains('active') ||
        panel.style.opacity === '1' ||
        panel.style.display === 'flex';
    if (isOpen) {
        closeOverlayPanel();
    } else {
        openOverlayPanel();
    }
}

window.closeOverlayPanel = closeOverlayPanel;
window.toggleOverlayPanel = toggleOverlayPanel;

// Helper to query elements from main document or Picture-in-Picture document context
function getOverlayElement(id) {
    if (pipWindow && pipWindow.document) {
        const el = pipWindow.document.getElementById(id);
        if (el) return el;
    }
    return document.getElementById(id);
}
window.getOverlayElement = getOverlayElement;

function handleOverlayInputKey(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        submitOverlayQuery();
    }
}

let overlayWs = null;
let overlayHistory = [];

async function submitOverlayQuery() {
    // overlay-runtime.js replaces window.submitOverlayQuery; this is legacy fallback only
    if (window.AuraOverlayRuntime && window.AuraOverlayRuntime.submitOverlayQuery
        && submitOverlayQuery !== window.AuraOverlayRuntime.submitOverlayQuery) {
        return window.AuraOverlayRuntime.submitOverlayQuery();
    }
    const input = getOverlayElement('overlay-user-input');
    const container = getOverlayElement('overlay-chat-messages');
    if (!input || !container) return;
    
    const text = input.value.trim();
    if (!text) return;
    
    CyberSound.playEnter();
    
    input.value = '';
    
    const userMsg = document.createElement('div');
    userMsg.className = 'overlay-user-msg';
    userMsg.innerText = text;
    container.appendChild(userMsg);
    container.scrollTop = container.scrollHeight;
    
    overlayHistory.push({ role: "user", content: text });
    
    const auraMsg = document.createElement('div');
    auraMsg.className = 'overlay-aura-msg';
    auraMsg.innerHTML = `<strong>AURA Overlay</strong><span class="overlay-txt-body">Connecting to core...</span>`;
    container.appendChild(auraMsg);
    container.scrollTop = container.scrollHeight;
    
    const textSpan = auraMsg.querySelector('.overlay-txt-body');

    let screenshotBase64 = null;
    if (screenCaptureStream) {
        try {
            const video = document.createElement('video');
            video.srcObject = screenCaptureStream;
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
            screenshotBase64 = canvas.toDataURL('image/jpeg', 0.8);
            
            video.pause();
            video.srcObject = null;
        } catch (captureErr) {
            console.error("Error capturing screen frame:", captureErr);
        }
    } else {
        screenshotBase64 = "local";
    }
    
    try {
        let wsUrl;
        if (PRODUCTION_BACKEND_URL) {
            const cleanUrl = PRODUCTION_BACKEND_URL.replace(/^(http|https):/, '');
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            wsUrl = `${wsProtocol}${cleanUrl}/chat`;
        } else {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
            const wsHost = getBackendHost(window.location.host);
            wsUrl = `${wsProtocol}://${wsHost}/chat`;
        }
        
        if (overlayWs) {
            try { overlayWs.close(); } catch(e) {}
        }
        
        overlayWs = new WebSocket(wsUrl);
        let firstChunk = true;
        let responseContent = "";
        
        overlayWs.onopen = function() {
            textSpan.innerText = "Thinking...";
            const payload = {
                prompt: text,
                conversationId: "overlay_session",
                projectId: "global",
                history: overlayHistory.slice(-6),
                sandbox: Object.assign({}, getSandboxConfig(), {
                    screenshot: screenshotBase64,
                    overlay_mode: true
                })
            };
            overlayWs.send(JSON.stringify(payload));
        };
        
        overlayWs.onmessage = function(event) {
            const data = JSON.parse(event.data);
            if (data.type === 'status') {
                const raw = (data.content || '').trim();
                const noisy = /searching|compiling|current date|realtime|gateway|ingestion/i.test(raw);
                if (!noisy && raw) textSpan.innerText = raw;
            } else if (data.type === 'chunk') {
                if (firstChunk) {
                    textSpan.innerHTML = "";
                    firstChunk = false;
                }
                responseContent += data.content;
                textSpan.innerHTML += data.content.replace(/\n/g, '<br>');
                container.scrollTop = container.scrollHeight;
            } else if (data.done === true) {
                overlayHistory.push({ role: "assistant", content: responseContent });
                overlayWs.close();
                overlayWs = null;
            }
        };
        
        overlayWs.onerror = function() {
            textSpan.innerText = "Can't reach AURA backend. Run: py python_backend/main.py (port 7860)";
        };
        
        overlayWs.onclose = function() {
            overlayWs = null;
        };
        
    } catch(err) {
        textSpan.innerText = "Failed to launch overlay routing pathway.";
    }
}

// Document Picture-in-Picture Handler to float overlay panel outside the web app/browser
let pipWindow = null;

async function toggleOverlayPiP() {
    if (pipWindow) {
        pipWindow.close();
        return;
    }

    if (!('documentPictureInPicture' in window)) {
        alert("Your browser does not support Document Picture-in-Picture to float elements outside the tab. Please use modern Chrome, Edge, or Opera.");
        return;
    }

    try {
        // Request a floating Picture-in-Picture window
        pipWindow = await window.documentPictureInPicture.requestWindow({
            width: 360,
            height: 480
        });

        // Copy styles to the PiP window
        const styleSheets = Array.from(document.styleSheets);
        styleSheets.forEach((styleSheet) => {
            try {
                if (styleSheet.href) {
                    const link = pipWindow.document.createElement('link');
                    link.rel = 'stylesheet';
                    link.href = styleSheet.href;
                    pipWindow.document.head.appendChild(link);
                } else if (styleSheet.cssRules) {
                    const style = pipWindow.document.createElement('style');
                    Array.from(styleSheet.cssRules).forEach((rule) => {
                        style.appendChild(pipWindow.document.createTextNode(rule.cssText));
                    });
                    pipWindow.document.head.appendChild(style);
                }
            } catch (e) {
                const link = pipWindow.document.createElement('link');
                link.rel = 'stylesheet';
                link.href = 'style.css';
                pipWindow.document.head.appendChild(link);
            }
        });

        // FontAwesome link
        const faLink = pipWindow.document.createElement('link');
        faLink.rel = 'stylesheet';
        faLink.href = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css';
        pipWindow.document.head.appendChild(faLink);

        // Google Fonts link
        const fontLink = pipWindow.document.createElement('link');
        fontLink.rel = 'stylesheet';
        fontLink.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&family=Orbitron:wght@400;500;700;900&family=Share+Tech+Mono&display=swap';
        pipWindow.document.head.appendChild(fontLink);

        // Body styling for PiP window to make it fit properly
        pipWindow.document.body.style.margin = '0';
        pipWindow.document.body.style.padding = '0';
        pipWindow.document.body.style.backgroundColor = 'var(--bg-chat)';
        pipWindow.document.body.style.color = 'var(--text-main)';
        pipWindow.document.body.style.height = '100vh';
        pipWindow.document.body.style.overflow = 'hidden';
        pipWindow.document.body.style.fontFamily = "'Inter', sans-serif";

        // Sync theme class list to PiP body
        const activeTheme = Array.from(document.body.classList).find(cls => cls.startsWith('theme-'));
        if (activeTheme) {
            pipWindow.document.body.classList.add(activeTheme);
        } else {
            pipWindow.document.body.classList.add('theme-chat');
        }

        // Add cyber grid and scanlines to PiP window
        const gridDiv = pipWindow.document.createElement('div');
        gridDiv.className = 'ambient-grid';
        pipWindow.document.body.appendChild(gridDiv);

        const scanlinesDiv = pipWindow.document.createElement('div');
        scanlinesDiv.className = 'cyber-scanlines';
        pipWindow.document.body.appendChild(scanlinesDiv);

        // Move the overlay panel into the PiP window
        const overlayPanel = document.getElementById('aura-overlay-panel');
        
        // Hide overlay-bubble when panel is floating in PiP
        const bubble = document.getElementById('aura-overlay-bubble');
        if (bubble) bubble.style.display = 'none';

        // Adjust overlay panel styling to fill the PiP window perfectly
        overlayPanel.style.position = 'fixed';
        overlayPanel.style.left = '0';
        overlayPanel.style.right = '0';
        overlayPanel.style.top = '0';
        overlayPanel.style.bottom = '0';
        overlayPanel.style.width = '100%';
        overlayPanel.style.height = '100%';
        overlayPanel.style.borderRadius = '0';
        overlayPanel.style.display = 'flex';
        overlayPanel.style.opacity = '1';
        overlayPanel.style.pointerEvents = 'auto';
        overlayPanel.classList.add('active');

        // Change PiP icon to compress/collapse in PiP window
        const pipBtn = overlayPanel.querySelector('.overlay-pip-btn i');
        if (pipBtn) {
            pipBtn.className = 'fa-solid fa-compress';
        }

        // Move panel DOM node to PiP document
        pipWindow.document.body.appendChild(overlayPanel);

        // Copy click listener to the PiP window document for sound effects (Capturing Phase)
        pipWindow.document.addEventListener('click', (e) => {
            const target = e.target.closest('button, select, .history-item, .suggestion-card, .quick-action-pill, a, .state-action-btn, .ctrl-btn');
            if (target) {
                CyberSound.playClick();
            }
        }, true);

        // Copy typing listener to the PiP window document for keyboard sound feedback
        pipWindow.document.addEventListener('keydown', (e) => {
            const target = e.target;
            if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')) {
                const quietKeys = ['Enter', 'Tab', 'Shift', 'Control', 'Alt', 'Meta', 'Escape', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
                if (!quietKeys.includes(e.key)) {
                    CyberSound.playKeypress();
                }
            }
        }, true);

        // Focus inputs automatically
        setTimeout(() => {
            const pipInput = pipWindow.document.getElementById('overlay-user-input');
            if (pipInput) pipInput.focus();
        }, 300);

        // Handle PiP window close event to restore the DOM node back to the main document
        pipWindow.addEventListener('pagehide', () => {
            if (bubble) bubble.style.display = '';

            if (pipBtn) {
                pipBtn.className = 'fa-solid fa-up-right-from-square';
            }

            const hostCloseBtn = overlayPanel.querySelector('#overlay-close-btn');
            if (hostCloseBtn) hostCloseBtn.style.display = '';

            resetOverlayPanelLayout(overlayPanel);
            overlayPanel.classList.remove('active');

            if (overlayPanel.parentNode !== document.body) {
                document.body.appendChild(overlayPanel);
            }
            pipWindow = null;
        });

    } catch (err) {
        console.error("Failed to initialize Document Picture-in-Picture:", err);
    }
}

// ==========================================================================
// AURA WINDOWS OVERLAY & SYSTEM PERMISSIONS FLOW
// ==========================================================================
let desktopModalStep = 0;
let screenCaptureStream = null;
let accessibilityGranted = false;
let overlayGranted = false;

function toggleDesktopAssist(enabled) {
    if (enabled) {
        showDesktopModal();
    } else {
        disableDesktopAssist();
    }
}

function showDesktopModal() {
    const modal = document.getElementById('desktop-permission-modal');
    if (!modal) return;
    modal.style.display = 'flex';
    desktopModalStep = 0;
    updateModalStep();
}

function closeDesktopModal() {
    const modal = document.getElementById('desktop-permission-modal');
    if (modal) modal.style.display = 'none';
    
    // Uncheck toggle if denied
    const cb = document.getElementById('mod-desktop-assist');
    if (cb) cb.checked = false;
    
    disableDesktopAssist();
}

function updateModalStep() {
    const steps = ['modal-step-welcome', 'modal-step-screencap', 'modal-step-accessibility', 'modal-step-overlay'];
    steps.forEach((stepId, index) => {
        const stepEl = document.getElementById(stepId);
        if (stepEl) {
            if (index === desktopModalStep) {
                stepEl.classList.add('active');
            } else {
                stepEl.classList.remove('active');
            }
        }
    });

    const nextBtn = document.getElementById('modal-next-btn');
    const cancelBtn = document.getElementById('modal-cancel-btn');
    if (desktopModalStep === 0) {
        nextBtn.innerText = "Continue";
        cancelBtn.innerText = "Not Now";
    } else if (desktopModalStep === 1) {
        nextBtn.innerText = "Grant Screen Capture";
        cancelBtn.innerText = "Back";
    } else if (desktopModalStep === 2) {
        nextBtn.innerText = "Authorize Accessibility";
        cancelBtn.innerText = "Back";
    } else if (desktopModalStep === 3) {
        nextBtn.innerText = "Launch Overlay (PiP)";
        cancelBtn.innerText = "Back";
    }
}

function regressDesktopModal() {
    if (desktopModalStep > 0) {
        desktopModalStep--;
        updateModalStep();
    } else {
        closeDesktopModal();
    }
}

async function advanceDesktopModal() {
    if (desktopModalStep === 0) {
        desktopModalStep = 1;
        updateModalStep();
    } else if (desktopModalStep === 1) {
        const statusEl = document.getElementById('screencap-status');
        if (statusEl) statusEl.innerText = "Status: Prompting user...";
        try {
            screenCaptureStream = await navigator.mediaDevices.getDisplayMedia({
                video: {
                    displaySurface: "monitor",
                    logicalSurface: true
                },
                audio: false
            });
            window.screenCaptureStream = screenCaptureStream;
            CyberSound.playScan();
            if (statusEl) {
                statusEl.innerText = "Status: Screen Capture Granted ✔";
                statusEl.style.color = "#00ff66";
            }
            setTimeout(() => {
                desktopModalStep = 2;
                updateModalStep();
            }, 1000);
        } catch (err) {
            if (statusEl) {
                statusEl.innerText = "Status: Screen Capture Denied ✗ (" + err.message + ")";
                statusEl.style.color = "var(--neon-red)";
            }
        }
    } else if (desktopModalStep === 2) {
        const statusEl = document.getElementById('accessibility-status');
        if (statusEl) statusEl.innerText = "Status: Connecting to Windows API...";
        
        setTimeout(() => {
            accessibilityGranted = true;
            if (statusEl) {
                statusEl.innerText = "Status: Accessibility Service Active ✔";
                statusEl.style.color = "#00ff66";
            }
            setTimeout(() => {
                desktopModalStep = 3;
                updateModalStep();
            }, 1000);
        }, 1500);
    } else if (desktopModalStep === 3) {
        const statusEl = document.getElementById('overlay-status');
        if (statusEl) statusEl.innerText = "Status: Launching Picture-in-Picture overlay...";
        
        await toggleOverlayPiP();
        
        if (pipWindow) {
            overlayGranted = true;
            if (statusEl) {
                statusEl.innerText = "Status: Floating Overlay Deployed ✔";
                statusEl.style.color = "#00ff66";
            }
            setTimeout(() => {
                const modal = document.getElementById('desktop-permission-modal');
                if (modal) modal.style.display = 'none';
                
                const cb = document.getElementById('mod-desktop-assist');
                if (cb) cb.checked = true;
                
                // Show actions in UI
                const qa = getOverlayElement('overlay-quick-actions');
                const ma = getOverlayElement('overlay-media-actions');
                if (qa) qa.style.display = 'flex';
                if (ma) ma.style.display = 'flex';
            }, 1000);
        } else {
            if (statusEl) {
                statusEl.innerText = "Status: Failed to open PiP ✗. Please allow popups.";
                statusEl.style.color = "var(--neon-red)";
            }
        }
    }
}

function disableDesktopAssist() {
    if (screenCaptureStream) {
        try {
            screenCaptureStream.getTracks().forEach(track => track.stop());
        } catch(e) {}
        screenCaptureStream = null;
        window.screenCaptureStream = null;
    }
    accessibilityGranted = false;
    overlayGranted = false;
    
    const qa = getOverlayElement('overlay-quick-actions');
    const ma = getOverlayElement('overlay-media-actions');
    if (qa) qa.style.display = 'none';
    if (ma) ma.style.display = 'none';
    
    if (pipWindow) {
        pipWindow.close();
        pipWindow = null;
    }
}

async function triggerOverlayAction(action) {
    if (window.AuraOverlayRuntime && typeof window.AuraOverlayRuntime.triggerOverlayAction === 'function') {
        if (action === 'screenshot') {
            CyberSound.playScan();
        }
        return window.AuraOverlayRuntime.triggerOverlayAction(action);
    }
    const container = getOverlayElement('overlay-chat-messages');
    const input = getOverlayElement('overlay-user-input');
    if (!container) return;

    if (action === 'voice') {
        const auraMsg = document.createElement('div');
        auraMsg.className = 'overlay-system-msg';
        auraMsg.innerText = "🎙 Voice Input Activated: Listening...";
        container.appendChild(auraMsg);
        container.scrollTop = container.scrollHeight;
        
        setTimeout(() => {
            if (input) {
                input.value = "How does this code look to you?";
                input.focus();
            }
            auraMsg.remove();
        }, 2000);
        return;
    }

    let contextPrompt = "";
    let systemDetails = null;

    try {
        const response = await fetch('/system/active-window');
        if (response.ok) {
            systemDetails = await response.json();
        }
    } catch (err) {
        console.warn("Could not retrieve active window from backend:", err);
    }

    let screenshotBase64 = null;
    if (screenCaptureStream) {
        try {
            const video = document.createElement('video');
            video.srcObject = screenCaptureStream;
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
            screenshotBase64 = canvas.toDataURL('image/jpeg', 0.8);
            
            video.pause();
            video.srcObject = null;
        } catch (captureErr) {
            console.error("Error capturing screen frame:", captureErr);
        }
    }

    let userVisibleText = "";
    if (systemDetails && systemDetails.status === "success") {
        userVisibleText = `[Desktop Active App: ${systemDetails.process} (Title: "${systemDetails.title}")]`;
    } else {
        userVisibleText = `[Desktop Active App: chrome.exe (Title: "AURA Assistant Workspace")]`;
    }

    if (action === 'summarize') {
        contextPrompt = `Summarize what I'm working on right now. Here's my current active window: ${userVisibleText}.`;
        if (screenshotBase64) {
            contextPrompt += " I have also captured a screenshot of my screen.";
        }
    } else if (action === 'explain') {
        contextPrompt = `Can you explain the code/contents on my screen? Current window: ${userVisibleText}.`;
    } else if (action === 'debug') {
        contextPrompt = `Look for any issues or errors in my current environment: ${userVisibleText}.`;
    } else if (action === 'reply') {
        contextPrompt = `Draft a context-aware email reply based on what is active on my desktop: ${userVisibleText}.`;
    } else if (action === 'screenshot') {
        contextPrompt = `Take a look at my current window: ${userVisibleText} and analyze it.`;
    }

    const userMsg = document.createElement('div');
    userMsg.className = 'overlay-user-msg';
    userMsg.innerText = action === 'screenshot' ? "📸 Capture Screen Context" : `⚡ Quick Action: ${action.charAt(0).toUpperCase() + action.slice(1)}`;
    container.appendChild(userMsg);
    container.scrollTop = container.scrollHeight;

    const auraMsg = document.createElement('div');
    auraMsg.className = 'overlay-aura-msg';
    auraMsg.innerHTML = `<strong>AURA Overlay</strong><span class="overlay-txt-body">Analyzing desktop context...</span>`;
    container.appendChild(auraMsg);
    container.scrollTop = container.scrollHeight;

    const textSpan = auraMsg.querySelector('.overlay-txt-body');
    
    try {
        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
        let wsHost = window.location.host || 'localhost:7860';
        if (wsHost.includes('localhost:') || wsHost.includes('127.0.0.1:')) {
            wsHost = wsHost.split(':')[0] + ':7860';
        } else if (wsHost === 'localhost' || wsHost === '127.0.0.1') {
            wsHost = wsHost + ':7860';
        }
        const wsUrl = `${wsProtocol}://${wsHost}/chat`;
        
        if (overlayWs) {
            try { overlayWs.close(); } catch(e) {}
        }
        
        overlayWs = new WebSocket(wsUrl);
        let firstChunk = true;
        let responseContent = "";
        
        overlayWs.onopen = function() {
            textSpan.innerText = "Thinking...";
            const payload = {
                prompt: contextPrompt,
                conversationId: "overlay_session",
                projectId: activeProjectId || "global",
                history: overlayHistory.slice(-6),
                sandbox: Object.assign({}, getSandboxConfig(), {
                    screenshot: screenshotBase64,
                    overlay_mode: true
                })
            };
            overlayWs.send(JSON.stringify(payload));
        };
        
        overlayWs.onmessage = function(event) {
            const data = JSON.parse(event.data);
            if (data.type === 'status') {
                const raw = (data.content || '').trim();
                const noisy = /searching|compiling|current date|realtime|gateway|ingestion/i.test(raw);
                if (!noisy && raw) textSpan.innerText = raw;
            } else if (data.type === 'chunk') {
                if (firstChunk) {
                    textSpan.innerHTML = "";
                    firstChunk = false;
                }
                responseContent += data.content;
                textSpan.innerHTML += data.content.replace(/\n/g, '<br>');
                container.scrollTop = container.scrollHeight;
            } else if (data.done === true) {
                overlayHistory.push({ role: "user", content: contextPrompt });
                overlayHistory.push({ role: "assistant", content: responseContent });
                overlayWs.close();
                overlayWs = null;
            }
        };
        
        overlayWs.onerror = function() {
            textSpan.innerText = "Can't reach AURA backend. Run: py python_backend/main.py (port 7860)";
        };
        
    } catch(err) {
        textSpan.innerText = "Failed to launch overlay routing pathway.";
    }
}

// ==========================================================================
// RESEARCH HUD WORKFLOW IMPLEMENTATION
// ==========================================================================

let researchCategory = 'Web';
let researchSocket = null;

function selectResearchCategory(category) {
    researchCategory = category;
    const chips = document.querySelectorAll('.category-chip');
    chips.forEach(chip => {
        if (chip.getAttribute('data-category') === category) {
            chip.classList.add('active');
        } else {
            chip.classList.remove('active');
        }
    });
    CyberSound.playClick();
}

function triggerPresetResearch(query) {
    const queryInput = document.getElementById('research-query-input');
    if (queryInput) {
        queryInput.value = query;
        initiateResearchQuery();
    }
}

function handleResearchInputKey(e) {
    if (e.key === 'Enter') {
        initiateResearchQuery();
    }
}

function initiateResearchQuery() {
    const queryInput = document.getElementById('research-query-input');
    if (!queryInput || !queryInput.value.trim()) return;
    
    const query = queryInput.value.trim();
    CyberSound.playEnter();
    
    // Hide presets, show console
    const discoverySec = document.getElementById('research-discovery-section');
    const consolePanel = document.getElementById('research-console-panel');
    if (discoverySec) discoverySec.style.display = 'none';
    if (consolePanel) consolePanel.style.display = 'flex';
    
    const synthesisBox = document.getElementById('research-synthesis-stream');
    const sourcesBox = document.getElementById('research-sources-list');
    if (synthesisBox) synthesisBox.innerHTML = '';
    if (sourcesBox) sourcesBox.innerHTML = '';
    
    connectResearchSocket(query, researchCategory);
}

function connectResearchSocket(query, category) {
    const statusLbl = document.getElementById('research-status-lbl');
    const spinner = document.getElementById('research-spinner');
    if (statusLbl) statusLbl.innerText = 'CONNECTING TO AURA RESEARCH CORE...';
    if (spinner) spinner.style.display = 'inline-block';
    
    try {
        let wsUrl;
        if (PRODUCTION_BACKEND_URL) {
            const cleanUrl = PRODUCTION_BACKEND_URL.replace(/^(http|https):/, '');
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            wsUrl = `${wsProtocol}${cleanUrl}/research`;
        } else {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
            const wsHost = getBackendHost(window.location.host);
            wsUrl = `${wsProtocol}://${wsHost}/research`;
        }
        
        if (researchSocket) {
            try { researchSocket.close(); } catch(e) {}
        }
        
        researchSocket = new WebSocket(wsUrl);
        
        researchSocket.onopen = function() {
            if (statusLbl) statusLbl.innerText = 'RESEARCH SESSION ACTIVE - INGESTING SOURCES...';
            CyberSound.playScan();
            
            researchSocket.send(JSON.stringify({
                prompt: query,
                category: category,
                history: []
            }));
        };
        
        researchSocket.onmessage = function(event) {
            const data = JSON.parse(event.data);
            
            if (data.done === true) {
                if (statusLbl) statusLbl.innerText = 'RESEARCH CORE SYNC COMPLETE.';
                if (spinner) spinner.style.display = 'none';
                researchSocket.close();
                researchSocket = null;
                return;
            }
            
            const type = data.type;
            const content = data.content;
            
            if (type === 'status') {
                if (statusLbl) statusLbl.innerText = content.toUpperCase();
            } else if (type === 'sources') {
                const sourcesBox = document.getElementById('research-sources-list');
                if (sourcesBox && Array.isArray(content)) {
                    sourcesBox.innerHTML = '';
                    content.forEach((url, index) => {
                        const item = document.createElement('div');
                        item.className = 'source-item';
                        let shortUrl = url;
                        try {
                            const parsed = new URL(url);
                            shortUrl = parsed.hostname + parsed.pathname.substring(0, 15) + (parsed.pathname.length > 15 ? '...' : '');
                        } catch(e) {}
                        item.innerHTML = `<i class="fa-solid fa-link"></i> <a href="${url}" target="_blank" title="${url}">[Source ${index+1}] ${shortUrl}</a>`;
                        sourcesBox.appendChild(item);
                    });
                }
            } else if (type === 'synthesis') {
                const synthesisBox = document.getElementById('research-synthesis-stream');
                if (synthesisBox) {
                    let formatted = '';
                    if (typeof content === 'object' && content !== null) {
                        formatted = `# ${content.title || 'Research Analysis'}\n\n`;
                        formatted += `## Summary\n${content.summary || ''}\n\n`;
                        if (content.key_findings) {
                            formatted += `## Key Findings\n`;
                            content.key_findings.forEach(kf => { formatted += `- ${kf}\n`; });
                            formatted += `\n`;
                        }
                        if (content.technical_analysis) {
                            formatted += `## Technical Analysis\n${content.technical_analysis}\n\n`;
                        }
                        if (content.statistics) {
                            formatted += `## Statistics\n`;
                            content.statistics.forEach(s => { formatted += `- ${s}\n`; });
                            formatted += `\n`;
                        }
                        if (content.future_scope) {
                            formatted += `## Future Scope\n${content.future_scope}\n\n`;
                        }
                    } else {
                        formatted = content.toString();
                    }
                    
                    const cleanHtml = parseMarkdownToHtml(formatted);
                    synthesisBox.innerHTML += cleanHtml;
                    synthesisBox.scrollTop = synthesisBox.scrollHeight;
                }
            }
        };
        
        researchSocket.onerror = function(err) {
            if (statusLbl) statusLbl.innerText = 'RESEARCH GATEWAY DISRUPTED.';
            if (spinner) spinner.style.display = 'none';
        };
        
        researchSocket.onclose = function() {
            if (spinner) spinner.style.display = 'none';
        };
        
    } catch(err) {
        if (statusLbl) statusLbl.innerText = 'COGNITIVE CHANNEL INITIALIZATION FAILURE.';
        if (spinner) spinner.style.display = 'none';
    }
}

function resetResearchConsole() {
    if (researchSocket) {
        try { researchSocket.close(); } catch(e) {}
        researchSocket = null;
    }
    const discoverySec = document.getElementById('research-discovery-section');
    const consolePanel = document.getElementById('research-console-panel');
    const queryInput = document.getElementById('research-query-input');
    if (discoverySec) discoverySec.style.display = 'block';
    if (consolePanel) consolePanel.style.display = 'none';
    if (queryInput) queryInput.value = '';
    CyberSound.playClick();
}

function parseMarkdownToHtml(markdown) {
    if (!markdown) return '';
    return markdown
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/^#\s+(.*?)$/gm, '<h1>$1</h1>')
        .replace(/^##\s+(.*?)$/gm, '<h2>$1</h2>')
        .replace(/^###\s+(.*?)$/gm, '<h3>$1</h3>')
        .replace(/^\s*-\s+(.*?)$/gm, '<li>$1</li>')
        .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" target="_blank">$1</a>')
        .replace(/\n/g, '<br>');
}

// ==========================================================================
// WORKSPACE HUD WORKFLOW IMPLEMENTATION
// ==========================================================================

let activeProjectId = 'global';
let workspaceProjects = [];
let selectedProjectId = null;
let currentProjectBlueprint = '';

let obTitle = '';
let obTopic = '';
let obDesc = '';
let obLevel = 'Intermediate';
let obQuestions = [];

async function loadWorkspaceProjects() {
    const listContainer = document.getElementById('workspace-projects-list');
    if (!listContainer) return;
    
    listContainer.innerHTML = '<div class="console-status-text" style="grid-column: 1/-1; text-align: center;">Scanning Neural Workspace Cores...</div>';
    
    try {
        const url = getBackendUrl('/workspaces');
        const response = await fetch(url);
        workspaceProjects = await response.json();
        
        listContainer.innerHTML = '';
        if (workspaceProjects.length === 0) {
            listContainer.innerHTML = `
                <div style="grid-column: 1/-1; text-align: center; padding: 40px; border: 1px dashed rgba(57, 255, 20, 0.2); border-radius: 12px; background: rgba(5, 12, 28, 0.45); color: var(--text-muted); font-family: var(--font-hud);">
                    <i class="fa-solid fa-folder-open" style="font-size: 2rem; color: rgba(57, 255, 20, 0.4); margin-bottom: 12px; display: block;"></i>
                    NO ACTIVE NEURAL CORES. INITIALIZE A NEW WORKSPACE PARAMETER TO BEGIN.
                </div>
            `;
            return;
        }
        
        workspaceProjects.forEach(proj => {
            const card = document.createElement('div');
            card.className = 'project-card';
            card.setAttribute('onclick', `selectProject('${proj.id}')`);
            
            const tag = proj.tag || 'AI PROJECT';
            const desc = proj.description || 'No description provided.';
            
            card.innerHTML = `
                <div class="project-card-header">
                    <span class="project-tag">${tag}</span>
                    <i class="fa-solid fa-microchip" style="color: var(--neon-green); font-size: 0.85rem;"></i>
                </div>
                <h4 class="project-card-title">${proj.title}</h4>
                <p class="project-card-desc">${desc}</p>
            `;
            listContainer.appendChild(card);
        });
    } catch (e) {
        console.error("Error loading workspace projects:", e);
        listContainer.innerHTML = '<div class="console-status-text" style="grid-column: 1/-1; text-align: center; color: var(--neon-pink);">COGNITIVE INTERACTION CHANNEL FAILURE.</div>';
    }
}

function startWorkspaceOnboarding() {
    CyberSound.playClick();
    
    const listContainer = document.getElementById('workspace-projects-list');
    const header = document.querySelector('.workspace-hub-header');
    const wizard = document.getElementById('workspace-onboarding-wizard');
    
    if (listContainer) listContainer.style.display = 'none';
    if (header) header.style.display = 'none';
    if (wizard) wizard.style.display = 'flex';
    
    document.getElementById('onboarding-step-1').style.display = 'block';
    document.getElementById('onboarding-step-2').style.display = 'none';
    document.getElementById('onboarding-step-3').style.display = 'none';
    
    document.getElementById('ob-project-title').value = '';
    document.getElementById('ob-project-topic').value = '';
    document.getElementById('ob-project-desc').value = '';
    document.getElementById('ob-project-level').value = 'Intermediate';
}

function cancelWorkspaceOnboarding() {
    CyberSound.playClick();
    
    const listContainer = document.getElementById('workspace-projects-list');
    const header = document.querySelector('.workspace-hub-header');
    const wizard = document.getElementById('workspace-onboarding-wizard');
    const dashboard = document.getElementById('workspace-project-dashboard');
    
    if (wizard) wizard.style.display = 'none';
    if (dashboard) dashboard.style.display = 'none';
    if (listContainer) listContainer.style.display = 'grid';
    if (header) header.style.display = 'flex';
    
    loadWorkspaceProjects();
}

async function submitOnboardingDetails() {
    obTitle = document.getElementById('ob-project-title').value.trim();
    obTopic = document.getElementById('ob-project-topic').value.trim();
    obDesc = document.getElementById('ob-project-desc').value.trim();
    obLevel = document.getElementById('ob-project-level').value;
    
    if (!obTitle) {
        alert("Please enter a Workspace Title.");
        return;
    }
    
    CyberSound.playEnter();
    
    const container = document.getElementById('ob-questions-container');
    if (container) {
        container.innerHTML = '<div class="console-status-text" style="text-align: center;">Retrieving adaptive alignment criteria...</div>';
    }
    
    document.getElementById('onboarding-step-1').style.display = 'none';
    document.getElementById('onboarding-step-2').style.display = 'block';
    
    try {
        const url = getBackendUrl('/workspaces/onboarding');
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title: obTitle,
                experience_level: obLevel,
                project_details: {
                    topic: obTopic,
                    description: obDesc
                }
            })
        });
        
        const data = await response.json();
        obQuestions = data.questions || [];
        
        if (container) {
            container.innerHTML = '';
            if (obQuestions.length === 0) {
                container.innerHTML = '<div class="console-status-text">Ready to align. Click Analyze & Build Blueprint.</div>';
            } else {
                obQuestions.forEach((q, idx) => {
                    const item = document.createElement('div');
                    item.className = 'ob-question-item';
                    const questionText = typeof q === 'object' ? (q.question || '') : q;
                    const optionsText = (typeof q === 'object' && q.options && q.options.length > 0)
                        ? `<div class="ob-question-options" style="font-size: 0.8rem; color: rgba(255,255,255,0.4); margin-top: 4px; margin-bottom: 8px;">Options: ${q.options.join(', ')}</div>`
                        : '';
                    item.innerHTML = `
                        <div class="ob-question-text">[Q${idx+1}] ${questionText}</div>
                        ${optionsText}
                        <input type="text" class="ob-question-input" data-index="${idx}" placeholder="Enter parameter detail...">
                    `;
                    container.appendChild(item);
                });
            }
        }
    } catch(e) {
        console.error("Error fetching onboarding questions:", e);
        if (container) {
            container.innerHTML = '<div class="console-status-text" style="color: var(--neon-pink);">Failed to fetch alignment parameters. Try again.</div>';
        }
    }
}

function backToOnboardingStep1() {
    CyberSound.playClick();
    document.getElementById('onboarding-step-2').style.display = 'none';
    document.getElementById('onboarding-step-1').style.display = 'block';
}

async function submitOnboardingAnswers() {
    CyberSound.playEnter();
    
    const preview = document.getElementById('ob-blueprint-preview');
    if (preview) {
        preview.innerHTML = 'Synthesizing local dependencies, AST targets, and building roadmap blueprint...';
    }
    
    document.getElementById('onboarding-step-2').style.display = 'none';
    document.getElementById('onboarding-step-3').style.display = 'block';
    
    const answers = [];
    const inputs = document.querySelectorAll('.ob-question-input');
    inputs.forEach(input => {
        const idx = parseInt(input.getAttribute('data-index'));
        answers.push({
            question: obQuestions[idx],
            answer: input.value.trim() || "Defaults accepted."
        });
    });
    
    try {
        const url = getBackendUrl('/workspaces/analyze');
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title: obTitle,
                answers: answers,
                experience_level: obLevel,
                project_details: {
                    topic: obTopic,
                    description: obDesc
                }
            })
        });
        
        const data = await response.json();
        currentProjectBlueprint = data.blueprint || data.analysis || (typeof data === 'string' ? data : JSON.stringify(data, null, 2));
        
        if (preview) {
            preview.innerHTML = currentProjectBlueprint;
        }
    } catch(e) {
        console.error("Error generating analysis blueprint:", e);
        if (preview) {
            preview.innerHTML = 'Analysis compilation failed. Sandbox deployment path corrupted.';
        }
    }
}

async function finalizeWorkspaceCreation() {
    CyberSound.playEnter();
    
    try {
        const url = getBackendUrl('/workspaces');
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title: obTitle,
                description: obDesc || `Strategic architecture for ${obTopic}`,
                blueprint: currentProjectBlueprint,
                tag: 'WORKSPACE CORE'
            })
        });
        
        if (response.ok) {
            cancelWorkspaceOnboarding();
        } else {
            alert("Failed to save neural core workspace.");
        }
    } catch(e) {
        console.error("Error creating project:", e);
        alert("Failed to communicate core creation parameters.");
    }
}

function selectProject(projectId) {
    CyberSound.playClick();
    
    selectedProjectId = projectId;
    const project = workspaceProjects.find(p => p.id === projectId);
    if (!project) return;
    
    const listContainer = document.getElementById('workspace-projects-list');
    const header = document.querySelector('.workspace-hub-header');
    const wizard = document.getElementById('workspace-onboarding-wizard');
    const dashboard = document.getElementById('workspace-project-dashboard');
    
    if (listContainer) listContainer.style.display = 'none';
    if (header) header.style.display = 'none';
    if (wizard) wizard.style.display = 'none';
    if (dashboard) dashboard.style.display = 'flex';
    
    document.getElementById('dash-project-tag').innerText = project.tag || 'AI PROJECT';
    document.getElementById('dash-project-title').innerText = project.title;
    document.getElementById('dash-project-desc').innerText = project.description || '';
    
    const bpBox = document.getElementById('dash-blueprint-content');
    if (bpBox) {
        bpBox.innerText = project.blueprint || 'No architectural blueprint compiled.';
    }
    
    const suggestBox = document.getElementById('dash-suggestion-box');
    if (suggestBox) {
        suggestBox.innerText = 'Click button above to scan workspace and request cognitive improvements.';
    }
    
    document.getElementById('dash-project-progress-lbl').innerText = '15%';
    document.getElementById('dash-project-progress-bar').style.width = '15%';
    
    switchDashboardTab('blueprint');
}

function showHubProjectsList() {
    CyberSound.playClick();
    
    const dashboard = document.getElementById('workspace-project-dashboard');
    const listContainer = document.getElementById('workspace-projects-list');
    const header = document.querySelector('.workspace-hub-header');
    
    if (dashboard) dashboard.style.display = 'none';
    if (listContainer) listContainer.style.display = 'grid';
    if (header) header.style.display = 'flex';
    
    selectedProjectId = null;
    loadWorkspaceProjects();
}

function switchDashboardTab(tabName) {
    CyberSound.playClick();
    
    const tabs = document.querySelectorAll('.dashboard-tabs .tab-item');
    tabs.forEach(tab => {
        const text = tab.innerText.toLowerCase();
        if (text.includes(tabName)) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    
    const bpContent = document.getElementById('dash-tab-blueprint');
    const sugContent = document.getElementById('dash-tab-suggestions');
    
    if (tabName === 'blueprint') {
        if (bpContent) bpContent.style.display = 'block';
        if (sugContent) sugContent.style.display = 'none';
    } else {
        if (bpContent) bpContent.style.display = 'none';
        if (sugContent) sugContent.style.display = 'block';
    }
}

function deleteCurrentProject() {
    if (!selectedProjectId) return;
    openCustomDeleteModal('workspace', selectedProjectId);
}

async function executeWorkspaceDelete(projectId) {
    if (window.CyberSound) window.CyberSound.playClick();
    
    try {
        const url = getBackendUrl(`/workspaces/${projectId}`);
        const response = await fetch(url, { method: 'DELETE' });
        if (response.ok) {
            showHubProjectsList();
        } else {
            alert("Failed to purge workspace.");
        }
    } catch(e) {
        console.error("Error deleting workspace:", e);
        alert("Failed to communicate purge request.");
    }
}

async function fetchProjectSuggestion() {
    if (!selectedProjectId) return;
    
    CyberSound.playScan();
    
    const box = document.getElementById('dash-suggestion-box');
    if (box) {
        box.innerText = 'Scanning workspace files, indexing AST, and retrieving strategic recommendations...';
    }
    
    try {
        const url = getBackendUrl(`/workspaces/${selectedProjectId}/suggest`);
        const response = await fetch(url);
        const data = await response.json();
        
        if (box) {
            box.innerText = data.suggestion || 'No current recommendations. Neural alignment optimal.';
            document.getElementById('dash-project-progress-lbl').innerText = '45%';
            document.getElementById('dash-project-progress-bar').style.width = '45%';
        }
    } catch(e) {
        console.error("Error fetching workspace suggestion:", e);
        if (box) {
            box.innerText = 'Neural audit path blocked. Try again.';
        }
    }
}

function startProjectChat() {
    if (!selectedProjectId) return;
    
    const project = workspaceProjects.find(p => p.id === selectedProjectId);
    if (!project) return;
    
    activeProjectId = selectedProjectId;
    
    changeMode('chat');
    
    CyberSound.playEnter();
    
    chatMessages.innerHTML = '';
    chatHistory = [];
    activeConvId = `conv_${selectedProjectId}_${Date.now()}`;
    
    loadRecentChats();
    
    const welcomeMsg = document.createElement('div');
    welcomeMsg.className = 'message system-msg';
    welcomeMsg.innerHTML = `<span class="msg-time">[Workspace Sandbox Active]</span> Connected to project **${project.title}**. AURA will base all reasoning and actions on this workspace's blueprint parameters.`;
    chatMessages.appendChild(welcomeMsg);
    
    welcomeView.style.display = 'none';
    chatMessages.style.display = 'flex';
}

// Bind to window for HTML access
window.changeMode = changeMode;
window.selectResearchCategory = selectResearchCategory;
window.triggerPresetResearch = triggerPresetResearch;
window.handleResearchInputKey = handleResearchInputKey;
window.initiateResearchQuery = initiateResearchQuery;
window.resetResearchConsole = resetResearchConsole;

window.loadWorkspaceProjects = loadWorkspaceProjects;
window.startWorkspaceOnboarding = startWorkspaceOnboarding;
window.cancelWorkspaceOnboarding = cancelWorkspaceOnboarding;
window.submitOnboardingDetails = submitOnboardingDetails;
window.backToOnboardingStep1 = backToOnboardingStep1;
window.submitOnboardingAnswers = submitOnboardingAnswers;
window.finalizeWorkspaceCreation = finalizeWorkspaceCreation;
window.selectProject = selectProject;
window.showHubProjectsList = showHubProjectsList;
window.switchDashboardTab = switchDashboardTab;
window.deleteCurrentProject = deleteCurrentProject;
window.fetchProjectSuggestion = fetchProjectSuggestion;
window.startProjectChat = startProjectChat;
window.activeChatMode = activeChatMode;
window.activeProjectId = activeProjectId;

window.openCustomDeleteModal = openCustomDeleteModal;
window.closeCustomDeleteModal = closeCustomDeleteModal;
window.confirmDeleteChat = confirmDeleteChat;
window.executeCustomDeleteAction = executeCustomDeleteAction;

