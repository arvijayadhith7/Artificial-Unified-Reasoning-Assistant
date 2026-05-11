import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../chat_service.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/aura_pulse.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _isVoiceMode = false;
  OrbState _orbState = OrbState.idle;
  String _currentResponse = "";
  String _currentThought = "";
  String _currentTool = "";
  final String _selectedModel = 'aura';

  // Code Canvas State
  String _canvasTitle = "Code Canvas";
  String _canvasContent = "";
  String _canvasLanguage = "dart";
  bool _isCanvasMarkdown = false;

  // Chat history for sidebar
  List<String> _chatHistory = []; // Stores "id|title" strings
  bool _chatSaved = false;
  String? _currentChatId;
  String? _currentChatTitle;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _chatService.connect();
    _chatService.responseStream.listen((data) {
      final type = data['type'];
      final content = data['content'] as String;

      setState(() {
        if (type == 'chunk') {
          _orbState = OrbState.speaking;
          if (_messages.isNotEmpty && !_messages.last.isUser && _currentResponse.isNotEmpty) {
            _currentResponse += content;
            _messages[_messages.length - 1] = ChatMessage(text: _currentResponse, isUser: false);
          } else {
            _currentResponse = content;
            _messages.add(ChatMessage(text: _currentResponse, isUser: false));
          }
          _currentThought = "";
          _currentTool = "";
          // Auto-detect code blocks for Canvas
          _detectCodeInResponse(_currentResponse);
        } else if (type == 'thought') {
          _orbState = OrbState.thinking;
          _currentThought = content;
        } else if (type == 'tool') {
          _currentTool = content;
        } else if (data['done'] == true) {
          _orbState = OrbState.idle;
        }
      });
      _scrollToBottom();
    });
    
    // Add listener to update send button state in real-time
    _textController.addListener(() {
      setState(() {});
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _detectCodeInResponse(String text) {
    final regExp = RegExp(r'```(\w+)?\n([\s\S]*?)```');
    final matches = regExp.allMatches(text);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      final language = lastMatch.group(1) ?? 'plaintext';
      final code = lastMatch.group(2) ?? '';
      _canvasContent = code;
      _canvasLanguage = language;
      _isCanvasMarkdown = (language == 'markdown' || language == 'md');
    }
  }

  // --- Chat History Persistence ---
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatHistory = prefs.getStringList('chat_history') ?? [];
    });
  }

  Future<void> _saveChatTitle(String title) async {
    if (_currentChatId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final entry = "${_currentChatId!}|$title";
    
    // Remove old entry for this ID if it exists
    _chatHistory.removeWhere((item) => item.startsWith("${_currentChatId!}|"));
    _chatHistory.insert(0, entry);
    
    if (_chatHistory.length > 20) _chatHistory = _chatHistory.sublist(0, 20);
    await prefs.setStringList('chat_history', _chatHistory);
    
    _currentChatTitle = title;
    setState(() {});
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentResponse = "";
      _canvasContent = "";
      _chatSaved = false;
      _currentChatTitle = null;
      // Generate a stable ID immediately for chat continuity
      _currentChatId = "chat_${DateTime.now().millisecondsSinceEpoch}";
      _textController.clear();
    });
  }

  Future<void> _loadMessagesForChat(String idWithTitle) async {
    final parts = idWithTitle.split('|');
    final id = parts[0];
    final title = parts.length > 1 ? parts[1] : id;

    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_content_$id';
    final content = prefs.getStringList(key) ?? [];
    
    setState(() {
      _messages.clear();
      _currentChatId = id;
      _currentChatTitle = title;
      for (var msgJson in content) {
        if (msgJson.startsWith('user:')) {
          _messages.add(ChatMessage(text: msgJson.substring(5), isUser: true));
        } else if (msgJson.startsWith('aura:')) {
          _messages.add(ChatMessage(text: msgJson.substring(5), isUser: false));
        }
      }
      _chatSaved = true; 
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_chatSaved && _messages.isEmpty) {
      final title = text.length > 40 ? '${text.substring(0, 40)}...' : text;
      _saveChatTitle(title);
      _chatSaved = true;
      // Keep the currentChatId stable, but we can associate it with the title in storage
    }

    if (_currentChatId == null) {
      _currentChatId = "chat_${DateTime.now().millisecondsSinceEpoch}";
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _currentResponse = "";
      _textController.clear();
      _orbState = OrbState.thinking;
    });
    
    _chatService.sendMessage(text, chatId: _currentChatId, modelType: _selectedModel);
    _scrollToBottom();
    _persistCurrentChat();
  }

  Future<void> _persistCurrentChat() async {
    if (_currentChatId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_content_${_currentChatId!}';
    
    final List<String> data = _messages.map((m) => '${m.isUser ? "user" : "aura"}:${m.text}').toList();
    await prefs.setStringList(key, data);
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AuraSidebar(
        chatHistory: _chatHistory,
        onNewChat: _startNewChat,
        onHistorySelected: _loadMessagesForChat,
      ),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Static background for professional look
          Container(color: AppColors.background),
          
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40),
              if (_isVoiceMode) _buildVoiceView() else _buildChatView(),
              _buildInputSection(),
            ],
          ),
          
          if (_currentThought.isNotEmpty || _currentTool.isNotEmpty) _buildStatusIndicator(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        "AURA",
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 16,
          letterSpacing: 5,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _isVoiceMode = !_isVoiceMode),
          icon: Icon(
            _isVoiceMode ? Icons.chat_bubble_outline_rounded : Icons.mic_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        if (_canvasContent.isNotEmpty)
          IconButton(
            onPressed: _showCanvasSheet,
            icon: const Icon(Icons.auto_awesome_mosaic_rounded, color: AppColors.primaryGreen, size: 22),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatView() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _messages.length + (_orbState == OrbState.thinking ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _messages.length) {
            final msg = _messages[index];
            return _buildMessageBubble(msg);
          } else {
            return _buildThinkingIndicator();
          }
        },
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.neonBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "AURA is processing",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceView() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuraPulse(isSpeaking: _orbState == OrbState.speaking),
          const SizedBox(height: 40),
          Text(
            _orbState == OrbState.listening ? "Listening..." : 
            _orbState == OrbState.thinking ? "Thinking..." :
            _orbState == OrbState.speaking ? "AURA is speaking" : "Ready to listen",
            style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 1.5),
          ),
          if (_currentResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                _currentResponse,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: Column(
            crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!msg.isUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "AURA",
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: msg.isUser ? AppColors.userBubble : AppColors.aiBubble,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.3),
                  ),
                ),
                child: MarkdownBody(
                  data: msg.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.6,
                    ),
                    code: const TextStyle(
                      backgroundColor: Colors.black12,
                      color: AppColors.hoverGreen,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    codeblockPadding: const EdgeInsets.all(16),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Message AURA...",
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (val) => _handleSend(),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSend,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _textController.text.trim().isNotEmpty ? AppColors.primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded, 
                    color: _textController.text.trim().isNotEmpty ? Colors.white : AppColors.textSecondary, 
                    size: 20
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.neonBlue, size: 14),
                  const SizedBox(width: 10),
                  Text(
                    _currentTool.isNotEmpty ? "SEARCHING..." : "THINKING...",
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCanvasSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, color: AppColors.neonBlue, size: 20),
                    const SizedBox(width: 10),
                    Text(_canvasTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_canvasLanguage.toUpperCase(), style: const TextStyle(color: AppColors.neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _canvasContent));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied!"), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // Code body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: HighlightView(
                    _canvasContent,
                    language: _canvasLanguage,
                    theme: atomOneDarkTheme,
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedThinkingDots extends StatefulWidget {
  @override
  State<_AnimatedThinkingDots> createState() => _AnimatedThinkingDotsState();
}

class _AnimatedThinkingDotsState extends State<_AnimatedThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String dots = "." * (_animation.value + 1);
        return Text(
          dots,
          style: const TextStyle(color: AppColors.neonBlue, fontSize: 18, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}

class AuraSidebar extends StatelessWidget {
  final List<String> chatHistory;
  final VoidCallback onNewChat;
  final Function(String) onHistorySelected;

  const AuraSidebar({
    super.key, 
    required this.chatHistory, 
    required this.onNewChat,
    required this.onHistorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.sidebar,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const GlowingOrb(size: 32),
                    const SizedBox(width: 12),
                    Text(
                      "AURA WORKSPACE",
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: InkWell(
                  onTap: () {
                    onNewChat();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "New chat",
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: chatHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No conversations yet",
                          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildSectionHeader("RECENT CHATS"),
                          ...chatHistory.map((title) => _buildHistoryItem(context, title)),
                        ],
                      ),
              ),
              const Divider(color: Colors.white10),
              _buildUserSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String idWithTitle) {
    final parts = idWithTitle.split('|');
    final title = parts.length > 1 ? parts[1] : parts[0];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 16),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          onHistorySelected(idWithTitle);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildUserSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.neonBlue, AppColors.neonPurple]),
            ),
            child: const Center(child: Text("A", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AURA PRO", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("Enterprise Account", style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.settings_outlined, color: Colors.white38, size: 20),
        ],
      ),
    );
  }
}
