// ==========================================================================
// AURA WORKSPACE OS INTERACTIVE LOGIC (PURE MODERN JS)
// ==========================================================================

// Global state trackers
let currentTab = 'notes';
let activeProject = 'Co-Founder Workspace';
let isSidebarCollapsed = false;
let isSplitScreen = false;
let assistantMode = 'chat';

// Simulated project isolated data store
const projectData = {
    'Co-Founder Workspace': {
        docTitle: 'Strategic Blueprint: Phase 1 launch',
        docContent: `## AURA OS - Phase 1 Launch Strategy

Welcome to the isolated Co-Founder Workspace. Aura has initialized specialized context parameters.

### 🎯 Launch Milestones
1. **Neural Halo Integration**: Complete. Visual CustomPainters are verified inside chat screens.
2. **Aura Overlay Assist**: Active. Draggable glassmorphic controls are mapped dynamically.
3. **Silent Strategic Inference**: Implemented on FastAPI backend spaces.

### 📝 Strategic Outline
* Task 1: Complete local APK signatures verification.
* Task 2: Sync python main server file to Hugging Face docker space settings.`,
        tasks: [
            { id: 1, title: 'Verify Neural Halo custom rendering frames', done: false },
            { id: 2, title: 'Upload main.py silent patch to Hugging Face Space', done: false },
            { id: 3, title: 'Compile release-ready Android APK build', done: true },
            { id: 4, title: 'Build desktop responsive marketing website mockup', done: true }
        ],
        chatHistory: [
            { role: 'assistant', text: 'Hello! I am Aura, your system advisor. I see we have finalized the mobile custom paint components. How can I help you refine the launch today?' }
        ]
    },
    'Personal Research': {
        docTitle: 'LLM Custom Rendering & Canvas benchmarks',
        docContent: `# Research Notes: Visual AI Interface Latencies

This sandbox holds benchmarking metrics for layout semantic parsing bounds.

### 📈 Current Benchmarks
- ML Kit On-Device OCR scanning: ~140ms
- Semantic structural JSON mapping: ~80ms
- UI element classification (WaveUI v2 dataset): ~220ms

*Conclusion: Context-aware overlay bubbles can run completely on-device without high cloud delays.*`,
        tasks: [
            { id: 5, title: 'Run local OCR model benchmark profiles', done: false },
            { id: 6, title: 'Profile custom painter memory leak traces', done: false }
        ],
        chatHistory: [
            { role: 'assistant', text: 'Aura Research Module active. I am monitoring the active document layout to extract citations instantly.' }
        ]
    },
    'UI/UX System Design': {
        docTitle: 'Design Token System v3',
        docContent: `## Design Token Specs

* Primary color: HSL Cyan (#00f2ff)
* Secondary color: Electric Blue (#06b6d4)
* Accent shadow: Violet Glow (#7c3aed)
* Corner radius: 16px (smooth glass corners)`,
        tasks: [
            { id: 7, title: 'Refactor chat screens to use primary custom colors', done: false }
        ],
        chatHistory: [
            { role: 'assistant', text: 'Design context active. I will validate UI contrast ratios and layout token parameters inline.' }
        ]
    }
};

// INITIALIZATION
document.addEventListener('DOMContentLoaded', () => {
    // Setup event listeners
    setupSidebarToggle();
    setupProjectDropdown();
    setupKeyboardShortcuts();
    
    // Load initial project data
    loadProjectData(activeProject);
    
    // Render initial tasks
    renderTasks();
});

// SIDEBAR COLLAPSIBILITY
function setupSidebarToggle() {
    const toggle = document.getElementById('sidebar-toggle');
    const sidebar = document.getElementById('sidebar');
    toggle.addEventListener('click', () => {
        isSidebarCollapsed = !isSidebarCollapsed;
        sidebar.classList.toggle('collapsed', isSidebarCollapsed);
        toggle.querySelector('i').className = isSidebarCollapsed ? 'fas fa-chevron-right' : 'fas fa-chevron-left';
    });
}

// PROJECT SELECTOR DROPDOWN
function setupProjectDropdown() {
    const btn = document.getElementById('project-dropdown-btn');
    const list = document.getElementById('project-list');
    
    btn.addEventListener('click', (e) => {
        e.stopPropagation();
        list.classList.toggle('active');
    });

    document.addEventListener('click', () => {
        list.classList.remove('active');
    });
}

// SWITCH ACTIVE PROJECT
function switchProject(projectName) {
    // Save current active project details
    saveCurrentProjectState();
    
    // Update active project
    activeProject = projectName;
    document.getElementById('active-project-name').innerText = projectName;
    document.getElementById('breadcrumb-active').innerText = projectName;
    
    // Toggle active dropdown styles
    const items = document.querySelectorAll('.project-item');
    items.forEach(item => {
        if (item.innerText.includes(projectName)) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });

    // Load new project details
    loadProjectData(projectName);
}

// SAVE CURRENT STATE
function saveCurrentProjectState() {
    const editor = document.getElementById('markdown-editor');
    const titleInput = document.getElementById('doc-title-input');
    
    if (projectData[activeProject]) {
        projectData[activeProject].docContent = editor.value;
        projectData[activeProject].docTitle = titleInput.value;
    }
}

// LOAD PROJECT DATA
function loadProjectData(projectName) {
    const data = projectData[projectName];
    if (!data) return;

    // Load editor info
    document.getElementById('doc-title-input').value = data.docTitle;
    document.getElementById('markdown-editor').value = data.docContent;

    // Load chat viewport logs
    const viewport = document.getElementById('chat-viewport');
    viewport.innerHTML = '';
    
    // Add default system msg
    viewport.innerHTML = `
        <div class="message system-msg">
            <div class="msg-content">
                Hello! I am Aura, your productivity system. I analyze your current tab (<strong id="current-tab-indicator">${currentTab.toUpperCase()}</strong>) to advise you in real time. 🌌
            </div>
        </div>
    `;

    data.chatHistory.forEach(msg => {
        appendChatMessageHTML(msg.role, msg.text);
    });

    // Render tasks
    renderTasks();
}

// TAB ROUTING SYSTEM
function switchTab(tabId) {
    currentTab = tabId;
    
    // Update active menu item in sidebar
    const menuItems = document.querySelectorAll('.menu-item');
    menuItems.forEach(item => {
        if (item.onclick.toString().includes(tabId)) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });

    // Toggle Tab viewports
    const tabs = document.querySelectorAll('.workspace-tab');
    tabs.forEach(tab => {
        if (tab.id === `tab-${tabId}`) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });

    // Update contextual indicators in Chat Panel
    document.getElementById('current-tab-indicator').innerText = tabId.toUpperCase();
    document.getElementById('input-context-label').innerHTML = `<i class="fas fa-link"></i> ${tabId.charAt(0).toUpperCase() + tabId.slice(1)} Context Active`;
}

// TASK PLANNER RENDERER
function renderTasks() {
    const data = projectData[activeProject];
    if (!data) return;

    const todoList = document.getElementById('todo-tasks-list');
    const doneList = document.getElementById('done-tasks-list');
    
    todoList.innerHTML = '';
    doneList.innerHTML = '';
    
    let todoCount = 0;
    let doneCount = 0;

    data.tasks.forEach(task => {
        const itemHTML = `
            <div class="task-item" onclick="toggleTaskStatus(${task.id})">
                <div class="task-checkbox ${task.done ? 'checked' : ''}">
                    ${task.done ? '<i class="fas fa-check"></i>' : ''}
                </div>
                <span class="task-title">${task.title}</span>
            </div>
        `;

        if (task.done) {
            doneList.innerHTML += itemHTML;
            doneCount++;
        } else {
            todoList.innerHTML += itemHTML;
            todoCount++;
        }
    });

    document.getElementById('todo-count').innerText = todoCount;
    document.getElementById('done-count').innerText = doneCount;
}

// TOGGLE TASK CHECKBOX
function toggleTaskStatus(taskId) {
    const data = projectData[activeProject];
    if (!data) return;

    const task = data.tasks.find(t => t.id === taskId);
    if (task) {
        task.done = !task.done;
        renderTasks();
        
        // Notify AI panel context
        appendChatMessageHTML('assistant', `Acknowledged. I have updated the status of your task: **"${task.title}"** to **${task.done ? 'COMPLETED' : 'PENDING'}**.`);
    }
}

// ADD NEW TASK
function addNewTask() {
    const taskTitle = prompt("Enter a workflow action item:");
    if (!taskTitle || taskTitle.trim() === '') return;

    const data = projectData[activeProject];
    if (!data) return;

    const newId = Date.now();
    data.tasks.push({
        id: newId,
        title: taskTitle.trim(),
        done: false
    });

    renderTasks();
}

// MARKDOWN EDITOR: INLINE AI POPUP AUTOCOMPLETE
function triggerInlineAI() {
    const bubble = document.getElementById('inline-ai-bubble');
    bubble.classList.add('active');
    document.getElementById('inline-ai-prompt').focus();
}

function handleInlineSubmit(e) {
    if (e.key === 'Enter') {
        const promptInput = document.getElementById('inline-ai-prompt');
        const query = promptInput.value.trim();
        if (query === '') return;

        const bubble = document.getElementById('inline-ai-bubble');
        bubble.classList.remove('active');
        promptInput.value = '';

        const textarea = document.getElementById('markdown-editor');
        const originalText = textarea.value;

        // Visual streaming text simulation inline!
        const generatedSnippet = `\n\n### ⚡ AURA Auto-Generated Segment (${query})\n- Dynamic context generated based on structural OCR blueprints.\n- Isolated dependencies declared for FastAPI server ports.\n- Release artifacts deployed under active workspace buffers.`;
        
        let index = 0;
        const interval = setInterval(() => {
            textarea.value = originalText + generatedSnippet.slice(0, index);
            textarea.scrollTop = textarea.scrollHeight;
            index++;
            if (index > generatedSnippet.length) {
                clearInterval(interval);
                projectData[activeProject].docContent = textarea.value;
            }
        }, 15);
    }
}

// SAVE NOTE MANUAL TRIGGER
function saveActiveDocument() {
    saveCurrentProjectState();
    alert("Note saved successfully inside isolated workspace context!");
}

// DEEP WEB RESEARCH ENGINE
function executeResearchSearch() {
    const input = document.getElementById('research-query-input');
    const query = input.value.trim();
    if (query === '') return;

    const resultsDiv = document.getElementById('research-results');
    
    // Transition state
    resultsDiv.innerHTML = `
        <div class="results-placeholder">
            <i class="fas fa-spinner fa-spin text-gradient" style="font-size: 3rem;"></i>
            <h3>Querying Tavily Web Cluster...</h3>
            <p>Aggregating visual OCR contexts and strategic industry standards...</p>
        </div>
    `;

    setTimeout(() => {
        // Mocked real-time comparison result layout with citations!
        resultsDiv.innerHTML = `
            <div class="research-brief-card">
                <h4><i class="fas fa-microchip"></i> Strategic Context: ${query}</h4>
                <p>Based on Tavily search indexes, LLM workflow overlay systems represent the fastest-growing sector in modern enterprise productivity design. By serving contextual hints over workspace windows, systems decrease operational error rates by 72%.</p>
                
                <div class="research-sources">
                    <div class="source-tag"><i class="fas fa-link"></i> TechCrunch Citation [1]</div>
                    <div class="source-tag"><i class="fas fa-link"></i> arXiv Layout Blueprint [2]</div>
                    <div class="source-tag"><i class="fas fa-link"></i> WaveUI Dataset Analysis [3]</div>
                </div>
            </div>
            
            <div class="research-brief-card">
                <h4><i class="fas fa-shield-alt"></i> Security & Isolation Summary</h4>
                <p>Modern architectures enforce isolation boundaries using custom sandbox windows (SYSTEM_ALERT_WINDOW inside Android kernels). Context parsing operates purely locally utilizing lightweight OCR to preserve client security metrics.</p>
            </div>
        `;
        
        appendChatMessageHTML('assistant', `I have executed deep web research on: **"${query}"**. Summarized data tables and source citations are rendered inside your active Research Board.`);
    }, 1500);
}

function handleResearchQuery(e) {
    if (e.key === 'Enter') {
        executeResearchSearch();
    }
}

// RIGHT CHAT INTERFACE LOGIC
function sendChatMessage() {
    const textarea = document.getElementById('chat-textarea');
    const text = textarea.value.trim();
    if (text === '') return;

    // User Message bubble
    appendChatMessageHTML('user', text);
    textarea.value = '';

    // Save to historical logs
    projectData[activeProject].chatHistory.push({ role: 'user', text: text });

    // Smooth scroll chat viewport
    const viewport = document.getElementById('chat-viewport');
    viewport.scrollTop = viewport.scrollHeight;

    // AURA Contextual Intelligence Response Simulation
    setTimeout(() => {
        let response = "";
        
        if (text.toLowerCase().includes('hi') || text.toLowerCase().includes('hello')) {
            response = `Hello! I am monitoring your active project **"${activeProject}"**. Let's build something beautiful. What strategic step are we tackling next?`;
        } else if (text.toLowerCase().includes('task') || text.toLowerCase().includes('todo')) {
            response = `I see you have pending workflow elements inside your active checklist. Let's finish the **"${projectData[activeProject].tasks[0].title}"** module first to keep architectural progress aligned.`;
        } else if (text.toLowerCase().includes('tamil')) {
            response = `நிச்சயமாக! உங்கள் தற்போதைய பக்கத்தின் பகுப்பாய்வை வெற்றிகரமாக முடித்துள்ளேன். என்ன உதவி வேண்டும் என்று கேளுங்கள்!`;
        } else {
            response = `I have contextually analyzed your request against the active notes buffer in **"${activeProject}"**. Based on current stack patterns, the best course of action is to draft an isolated workflow layer to eliminate side-effects.`;
        }

        // Mimic pure character-by-character live streaming response!
        appendStreamingMessage(response);
    }, 600);
}

function handleChatSubmit(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendChatMessage();
    }
}

function appendChatMessageHTML(role, text) {
    const viewport = document.getElementById('chat-viewport');
    const msgHTML = `
        <div class="message ${role}-msg">
            <div class="msg-content">
                ${text}
            </div>
        </div>
    `;
    viewport.innerHTML += msgHTML;
    viewport.scrollTop = viewport.scrollHeight;
}

// LIVE STREAMING TEXT TRANSITION
function appendStreamingMessage(fullText) {
    const viewport = document.getElementById('chat-viewport');
    
    // Create assistant message container
    const msgId = 'msg-' + Date.now();
    const msgHTML = `
        <div class="message assistant-msg" id="${msgId}">
            <div class="msg-content"></div>
        </div>
    `;
    viewport.innerHTML += msgHTML;
    viewport.scrollTop = viewport.scrollHeight;

    const container = document.getElementById(msgId).querySelector('.msg-content');
    
    let index = 0;
    const interval = setInterval(() => {
        container.innerHTML = fullText.slice(0, index);
        viewport.scrollTop = viewport.scrollHeight;
        index++;
        if (index > fullText.length) {
            clearInterval(interval);
            // Save to logs
            projectData[activeProject].chatHistory.push({ role: 'assistant', text: fullText });
        }
    }, 12);
}

// KEYBOARD SHORTCUTS SYSTEM
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
        // Ctrl + K -> Toggle Command Palette
        if (e.ctrlKey && e.key === 'k') {
            e.preventDefault();
            toggleCommandPalette();
        }

        // ESC -> Close Command Palette or Modals
        if (e.key === 'Escape') {
            closeCommandPalette();
            closeModals();
        }

        // Ctrl + B -> Toggle Sidebar
        if (e.ctrlKey && e.key === 'b') {
            e.preventDefault();
            document.getElementById('sidebar-toggle').click();
        }
    });
}

// UNIVERSAL COMMAND PALETTE (CTRL + K)
function toggleCommandPalette() {
    const overlay = document.getElementById('cmd-overlay');
    overlay.classList.toggle('active');
    if (overlay.classList.contains('active')) {
        document.getElementById('cmd-input').focus();
    }
}

function closeCommandPalette(e) {
    if (!e || e.target === document.getElementById('cmd-overlay')) {
        document.getElementById('cmd-overlay').classList.remove('active');
    }
}

function handleCommandKey(e) {
    if (e.key === 'Enter') {
        const query = document.getElementById('cmd-input').value.trim();
        if (query === '') return;

        closeCommandPalette();
        document.getElementById('cmd-input').value = '';

        // Route command input context
        if (query.toLowerCase().includes('search') || query.toLowerCase().includes('find')) {
            switchTab('research');
            document.getElementById('research-query-input').value = query.replace(/search|find/gi, '').trim();
            executeResearchSearch();
        } else if (query.toLowerCase().includes('task') || query.toLowerCase().includes('todo')) {
            switchTab('tasks');
        } else {
            // Send direct to chat
            appendChatMessageHTML('user', `Command run: ${query}`);
            setTimeout(() => {
                appendStreamingMessage(`Universal Action executed. Triggered contextual indexing routines successfully.`);
            }, 500);
        }
    }
}

function triggerCommandAction(actionId) {
    closeCommandPalette();
    if (actionId === 'notes' || actionId === 'research' || actionId === 'tasks') {
        switchTab(actionId);
    } else if (actionId === 'memory') {
        toggleMemoryModal();
    }
}

// MODALS CONTROL FLOW
function toggleMemoryModal() {
    closeModals();
    document.getElementById('memory-modal').classList.add('active');
}

function togglePromptsModal() {
    closeModals();
    document.getElementById('prompts-modal').classList.add('active');
}

function toggleSettingsModal() {
    closeModals();
    document.getElementById('settings-modal').classList.add('active');
}

function closeModals() {
    const overlays = document.querySelectorAll('.modal-overlay');
    overlays.forEach(overlay => overlay.classList.remove('active'));
}

function usePromptTemplate(promptText) {
    closeModals();
    const textarea = document.getElementById('chat-textarea');
    textarea.value = promptText;
    textarea.focus();
}

// SPLIT SCREEN & TOGGLES
function toggleSplitScreen() {
    isSplitScreen = !isSplitScreen;
    const panel = document.getElementById('assistant-panel');
    panel.style.width = isSplitScreen ? '50vw' : '360px';
}

function setAssistantMode(mode) {
    assistantMode = mode;
    document.getElementById('mode-btn-chat').classList.toggle('active', mode === 'chat');
    document.getElementById('mode-btn-code').classList.toggle('active', mode === 'code');
    
    appendChatMessageHTML('assistant', `Aura changed profile settings. Switch to **${mode.toUpperCase()}** Mode active.`);
}

function startNewChat() {
    const viewport = document.getElementById('chat-viewport');
    viewport.innerHTML = `
        <div class="message system-msg">
            <div class="msg-content">
                New clean session started in **${activeProject}**. History archived contextually. 🌌
            </div>
        </div>
    `;
}
