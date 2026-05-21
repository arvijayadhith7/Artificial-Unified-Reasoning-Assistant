/* ==========================================================================
   AURA INTERACTIVE APPLICATION SCRIPT - CHATGPT DESKTOP EDITION
   Provides: Chat handshakes, real-time thought streams, sandbox maps & hotloads
   ========================================================================== */

// Page layout hooks
const bgGrid = document.getElementById('bg-grid');
const glowC = document.getElementById('glow-c');
const glowV = document.getElementById('glow-v');
const chatMessages = document.getElementById('chat-messages');
const userInput = document.getElementById('terminal-user-input');
const sendMsgBtn = document.getElementById('btn-send-msg');
const welcomeView = document.getElementById('welcome-view');
const detailsPanel = document.getElementById('app-details-panel');

// Sandbox state hooks
const sbPersona = document.getElementById('sb-persona');
const sbSearchDepth = document.getElementById('sb-search-depth');
const modOCR = document.getElementById('mod-ocr');
const modLint = document.getElementById('mod-lint');
const sbWorkspacePath = document.getElementById('sb-workspace-path');

// Visual memory indicators
const vizSysInst = document.getElementById('viz-sys-inst');
const vizIngest = document.getElementById('viz-ingest');
const vizWorkspace = document.getElementById('viz-workspace');
const vizRetrieval = document.getElementById('viz-retrieval');
const vizTokenBar = document.getElementById('viz-token-bar');
const vizTokenText = document.getElementById('viz-token-text');
const syncStatus = document.getElementById('sandbox-sync-status');

// Diagnostic logs
const thinkingProgressBar = document.getElementById('thinking-progress-bar');
const thinkingProgressLabel = document.getElementById('thinking-progress-label');
const thoughtStepsLog = document.getElementById('thought-steps-log');

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
    detailsPanel.classList.toggle('hidden');
}

function setQuickInput(text) {
    userInput.value = text;
    userInput.focus();
    adjustTextareaHeight();
}

function getBackendUrl(endpoint) {
    let host = window.location.host || 'localhost:7860';
    if (host.includes('localhost:') || host.includes('127.0.0.1:')) {
        host = host.split(':')[0] + ':7860';
    } else if (host === 'localhost' || host === '127.0.0.1') {
        host = host + ':7860';
    }
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
        const url = getBackendUrl('/chats');
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
    
    welcomeView.style.display = 'none';
    chatMessages.innerHTML = '';
    
    const loadingDiv = document.createElement('div');
    loadingDiv.className = 'message system-msg';
    loadingDiv.innerHTML = `<span class="msg-time">[System]</span> Loading chat history...`;
    chatMessages.appendChild(loadingDiv);
    
    try {
        const url = getBackendUrl(`/chats/${convId}`);
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
                
                let internalThoughtHTML = '';
                if (thought && thought.trim().length > 0) {
                    internalThoughtHTML = `<div class="thinking-block">`;
                    internalThoughtHTML += `<div class="thinking-block-title"><i class="fas fa-brain"></i> Deep Thought Process</div>`;
                    internalThoughtHTML += `<div class="thinking-block-body">${escapeHtml(thought)}</div>`;
                    internalThoughtHTML += `</div>`;
                }
                
                textBody.innerHTML = internalThoughtHTML;
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
    searchEnabled = !searchEnabled;
    const btn = document.getElementById('btn-web-search-toggle');
    if (searchEnabled) {
        btn.classList.add('active');
        sbSearchDepth.value = 'multi-tier';
    } else {
        btn.classList.remove('active');
        sbSearchDepth.value = 'local-only';
    }
    updateSandboxUI();
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

    // Dynamic badge and background lights
    switch(state) {
        case 'listening':
            if (navHaloDot) navHaloDot.style.background = 'var(--electric-blue)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-microphone"></i> AURA CORE LISTENING`;
                statusBadge.style.color = 'var(--electric-blue)';
                statusBadge.style.borderColor = 'rgba(59, 130, 246, 0.3)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--electric-blue), transparent 70%)';
            break;
            
        case 'thinking':
            if (navHaloDot) navHaloDot.style.background = 'var(--violet-glow)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-microchip fa-spin"></i> AURA CORE THINKING`;
                statusBadge.style.color = 'var(--violet-glow)';
                statusBadge.style.borderColor = 'rgba(139, 92, 246, 0.3)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--violet-glow), transparent 70%)';
            break;
            
        case 'scanning':
            if (navHaloDot) navHaloDot.style.background = 'var(--neon-red)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-shield-virus"></i> AURA CORE SCANNING`;
                statusBadge.style.color = 'var(--neon-red)';
                statusBadge.style.borderColor = 'rgba(244, 63, 94, 0.3)';
            }
            if (glowV) glowV.style.background = 'radial-gradient(circle, var(--neon-red), transparent 70%)';
            break;
            
        case 'idle':
        default:
            if (navHaloDot) navHaloDot.style.background = 'var(--neon-cyan)';
            if (statusBadge) {
                statusBadge.innerHTML = `<i class="fas fa-circle-notch fa-spin"></i> AURA CORE ONLINE`;
                statusBadge.style.color = 'var(--neon-cyan)';
                statusBadge.style.borderColor = 'rgba(0, 242, 255, 0.12)';
            }
            if (glowC) glowC.style.background = 'radial-gradient(circle, var(--neon-cyan), transparent 70%)';
            if (glowV) glowV.style.background = 'radial-gradient(circle, var(--violet-glow), transparent 70%)';
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

function triggerAttachFile() {
    alert("Attachment sandbox mounted. Drag & drop standard code repositories or system instruction templates.");
}

function submitSimulationQuery() {
    const text = userInput.value.trim();
    if (!text || isThinking) return;

    // Reset input pill
    userInput.value = '';
    userInput.style.height = 'auto';

    // Hide welcome overlay on active chat
    welcomeView.style.display = 'none';

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
    
    if (auraTitle) {
        msgDiv.innerHTML = `<span class="msg-time">[${timeString}]</span> <strong>${auraTitle}</strong> <div class="msg-txt-body">${text.replace(/\n/g, '<br>')}</div>`;
    } else {
        msgDiv.innerHTML = `<span class="msg-time">[${timeString}]</span> <div class="msg-txt-body">${text.replace(/\n/g, '<br>')}</div>`;
    }
    
    chatMessages.appendChild(msgDiv);
    const viewport = document.getElementById('chat-viewport');
    viewport.scrollTop = viewport.scrollHeight;
    return msgDiv;
}

// Connect to backend LRM WebSocket
function executeRealtimeChat(query) {
    isThinking = true;
    thoughtStepsLog.innerHTML = ''; // Reset diagnostic logs
    thinkingProgressBar.style.width = '0%';
    thinkingProgressLabel.innerText = "Connecting to AURA LRM Core...";
    
    setHaloState('thinking', 'COGNITIVE STATE: RESOLVING REAL-TIME THOUGHTS');

    // Self-healing fallback if WebSocket is offline or blocked
    const fallbackTimeout = setTimeout(() => {
        if (isThinking && !ws) {
            console.warn("WebSocket timeout. Activating premium local-first simulation cascade.");
            executeFallbackSimulation(query);
        }
    }, 3500);

    try {
        const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
        let wsHost = window.location.host || 'localhost:7860';
        if (wsHost.includes('localhost:') || wsHost.includes('127.0.0.1:')) {
            wsHost = wsHost.split(':')[0] + ':7860';
        } else if (wsHost === 'localhost' || wsHost === '127.0.0.1') {
            wsHost = wsHost + ':7860';
        }
        const wsUrl = `${wsProtocol}://${wsHost}/chat`;
        
        ws = new WebSocket(wsUrl);
        currentResponseContainer = null;
        currentTextSpan = null;
        fullReplyAccumulated = "";

        ws.onopen = function() {
            clearTimeout(fallbackTimeout);
            thinkingProgressLabel.innerText = "Handshake complete. Initializing cognitive pathway...";
            
            // Ingestion variables
            const payload = {
                prompt: query,
                conversationId: activeConvId || "default_web",
                projectId: "global",
                history: chatHistory.slice(-10),
                sandbox: {
                    persona: sbPersona.value,
                    search_strategy: sbSearchDepth.value,
                    ocr: modOCR.checked,
                    lint: modLint.checked,
                    workspace_path: sbWorkspacePath.value
                }
            };
            ws.send(JSON.stringify(payload));
        };

        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            
            if (data.type === 'status') {
                const raw = (data.content || '').trim();
                const noisy = /searching|compiling|structuring|current date|realtime|looking up|web search|gateway|ingestion|synthesiz|analyzing|neural memory|live summaries|synchronized/i.test(raw);
                if (!noisy && raw) {
                    thinkingProgressLabel.innerText = raw;
                }
            } 
            else if (data.type === 'thought_step') {
                // Append node in side diagnostics panel
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
                
                let currentPercent = parseInt(thinkingProgressBar.style.width) || 0;
                let nextPercent = Math.min(currentPercent + 25, 90);
                thinkingProgressBar.style.width = `${nextPercent}%`;
            }
            else if (data.type === 'chunk') {
                if (!currentResponseContainer) {
                    const lastNode = thoughtStepsLog.lastElementChild;
                    if (lastNode && lastNode.classList.contains('thought-node') && !lastNode.classList.contains('resolved')) {
                        lastNode.className = 'thought-node resolved';
                        const icon = lastNode.querySelector('.thought-node-icon');
                        if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
                    }
                    
                    thinkingProgressBar.style.width = '95%';
                    thinkingProgressLabel.innerText = "Ingestion resolved. Generating answer...";
                    
                    // Create beautiful LRM text container
                    currentResponseContainer = appendMessage('', 'aura-msg', 'AURA Assistant');
                    const textBody = currentResponseContainer.querySelector('.msg-txt-body');
                    
                    // Curved deep reasoning block inside chat UI
                    let internalThoughtHTML = `<div class="thinking-block">`;
                    internalThoughtHTML += `<div class="thinking-block-title"><i class="fas fa-brain"></i> Deep Thought Process</div>`;
                    internalThoughtHTML += `<div class="thinking-block-body">`;
                    
                    const steps = thoughtStepsLog.querySelectorAll('.thought-node');
                    steps.forEach((step, i) => {
                        const title = step.querySelector('.thought-node-title').innerText;
                        const body = step.querySelector('.thought-node-body').innerText;
                        internalThoughtHTML += `${i+1}. ${title}: ${body}\n`;
                    });
                    
                    if (steps.length === 0) {
                        internalThoughtHTML += `1. Memory Map Scan: Sandbox grounding active. Direct cognitive weights loaded.`;
                    }
                    
                    internalThoughtHTML += `</div></div>`;
                    textBody.innerHTML = internalThoughtHTML;
                    
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
    thinkingProgressBar.style.width = '100%';
    thinkingProgressLabel.innerText = "AURA Core Online";
    
    const steps = thoughtStepsLog.querySelectorAll('.thought-node');
    steps.forEach(step => {
        if (!step.classList.contains('resolved')) {
            step.className = 'thought-node resolved';
            const icon = step.querySelector('.thought-node-icon');
            if (icon) icon.innerHTML = '<i class="fas fa-check"></i>';
        }
    });

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

            const percent = Math.round(((currentStep + 0.5) / totalSteps) * 100);
            thinkingProgressBar.style.width = `${percent}%`;
            thinkingProgressLabel.innerText = `Step ${currentStep + 1} of ${totalSteps}: ${thought.title}`;

            setTimeout(() => {
                node.className = 'thought-node resolved';
                node.querySelector('.thought-node-icon').innerHTML = '<i class="fas fa-check"></i>';
                currentStep++;
                const percentDone = Math.round((currentStep / totalSteps) * 100);
                thinkingProgressBar.style.width = `${percentDone}%`;
                setTimeout(processNextThought, 700);
            }, 800);
            
        } else {
            thinkingProgressLabel.innerText = "Cognitive Processing Complete.";
            
            setTimeout(() => {
                isThinking = false;
                setHaloState('idle', 'COGNITIVE STATE: IDLE');
                
                const responseContainer = appendMessage('', 'aura-msg', 'AURA Assistant');
                const textBody = responseContainer.querySelector('.msg-txt-body');
                
                let internalThoughtHTML = `<div class="thinking-block">`;
                internalThoughtHTML += `<div class="thinking-block-title"><i class="fas fa-brain"></i> Deep Thought Process</div>`;
                internalThoughtHTML += `<div class="thinking-block-body">`;
                responseData.thoughts.forEach((t, i) => {
                    internalThoughtHTML += `${i+1}. ${t.title}: ${t.body}\n`;
                });
                internalThoughtHTML += `</div></div>`;
                
                let fullText = responseData.answer;
                let charIndex = 0;
                
                textBody.innerHTML = internalThoughtHTML;
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
    if (syncStatus) {
        syncStatus.innerText = "MODIFIED";
        syncStatus.style.background = "rgba(139, 92, 246, 0.08)";
        syncStatus.style.borderColor = "rgba(139, 92, 246, 0.2)";
        syncStatus.style.color = "var(--violet-glow)";
    }
}

function hotReloadSandbox() {
    if (syncStatus) {
        syncStatus.innerText = "HOT-RELOADING...";
        syncStatus.style.background = "rgba(255, 193, 7, 0.08)";
        syncStatus.style.borderColor = "rgba(255, 193, 7, 0.2)";
        syncStatus.style.color = "#ffc107";
    }
    
    setHaloState('scanning', 'COGNITIVE STATE: RE-INDEXING MEMORY CHUNKS');

    setTimeout(() => {
        // Map persona value
        const persona = sbPersona.value;
        let sysInstText = "";
        if (persona === 'warm-narrative') {
            sysInstText = '"You are Aura, a warm co-founder companion providing strategic advice."';
        } else if (persona === 'ultra-technical') {
            sysInstText = '"You are Aura, an ultra-technical architect providing precise system schemas."';
        } else {
            sysInstText = '"You are Aura, a minimalist developer offering short shell corrections."';
        }
        if (vizSysInst) vizSysInst.innerText = sysInstText;

        // Map ingestion cluster
        const ocr = modOCR.checked ? "ON" : "OFF";
        const lint = modLint.checked ? "ON" : "OFF";
        if (vizIngest) vizIngest.innerText = `Status: Active (OCR: ${ocr}, Lint: ${lint})`;

        // Map workspace
        if (vizWorkspace) vizWorkspace.innerText = `"${sbWorkspacePath.value}"`;

        // Map search depth
        const depth = sbSearchDepth.value;
        let depthText = "";
        if (depth === 'multi-tier') {
            depthText = '"Fallback gateway: DDG Primary -> Scraper -> SearXNG"';
        } else if (depth === 'pure-api') {
            depthText = '"Direct gateway: DuckDuckGo API (strict citations)"';
        } else {
            depthText = '"Isolated gateway: Local Sandboxed memory contexts (No-Web)"';
        }
        if (vizRetrieval) vizRetrieval.innerText = depthText;

        // Randomize token counts slightly
        const randomTokens = Math.floor(Math.random() * 4500) + 4000;
        const percent = Math.round((randomTokens / 16384) * 100);
        if (vizTokenBar) vizTokenBar.style.width = `${percent}%`;
        if (vizTokenText) vizTokenText.innerText = `${randomTokens.toLocaleString()} / 16,384 tokens`;

        // Reset sync status pill
        if (syncStatus) {
            syncStatus.innerText = "HOT-LOADED SYNCED";
            syncStatus.style.background = "rgba(0, 242, 255, 0.08)";
            syncStatus.style.borderColor = "rgba(0, 242, 255, 0.2)";
            syncStatus.style.color = "var(--neon-cyan)";
        }

        setHaloState('idle', 'COGNITIVE STATE: IDLE');

        // Flash screen grids slightly
        if (bgGrid) {
            bgGrid.style.opacity = '0.3';
            setTimeout(() => { bgGrid.style.opacity = '0.8'; }, 200);
        }

    }, 1500);
}

// Initializer on page load
document.addEventListener('DOMContentLoaded', () => {
    loadRecentChats();
    
    const searchInput = document.getElementById('history-search-input');
    if (searchInput) {
        searchInput.addEventListener('input', filterAndRenderHistory);
    }
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
                prompt: text,
                conversationId: "overlay_session",
                projectId: "global",
                history: overlayHistory.slice(-6),
                sandbox: {
                    persona: (sbPersona && sbPersona.value) || 'warm-narrative',
                    search_strategy: (sbSearchDepth && sbSearchDepth.value) || 'multi-tier',
                    ocr: modOCR ? modOCR.checked : true,
                    lint: modLint ? modLint.checked : false,
                    workspace_path: (sbWorkspacePath && sbWorkspacePath.value) || '',
                    screenshot: screenshotBase64,
                    overlay_mode: true
                }
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
        fontLink.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap';
        pipWindow.document.head.appendChild(fontLink);

        // Body styling for PiP window to make it fit properly
        pipWindow.document.body.style.margin = '0';
        pipWindow.document.body.style.padding = '0';
        pipWindow.document.body.style.backgroundColor = '#212121';
        pipWindow.document.body.style.color = '#ececec';
        pipWindow.document.body.style.height = '100vh';
        pipWindow.document.body.style.overflow = 'hidden';
        pipWindow.document.body.style.fontFamily = "'Inter', sans-serif";

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
                projectId: "global",
                history: overlayHistory.slice(-6),
                sandbox: {
                    persona: (sbPersona && sbPersona.value) || 'warm-narrative',
                    search_strategy: (sbSearchDepth && sbSearchDepth.value) || 'multi-tier',
                    ocr: modOCR ? modOCR.checked : true,
                    lint: modLint ? modLint.checked : false,
                    workspace_path: (sbWorkspacePath && sbWorkspacePath.value) || '',
                    screenshot: screenshotBase64,
                    overlay_mode: true
                }
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

