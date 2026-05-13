import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../chat_service.dart';
import '../widgets/glowing_orb.dart';

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
  String _canvasTitle = "Neural Output";
  String _canvasContent = "";
  String _canvasLanguage = "dart";
  bool _isCanvasMarkdown = false;

  // Chat history
  List<String> _chatHistory = [];
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
      final content = data['content'] as String?;

      setState(() {
        if (type == 'chunk' && content != null) {
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
          _detectCodeInResponse(_currentResponse);
        } else if (type == 'thought' && content != null) {
          _orbState = OrbState.thinking;
          _currentThought = content;
        } else if (type == 'tool' && content != null) {
          _currentTool = content;
        } else if (data['done'] == true) {
          _orbState = OrbState.idle;
        }
      });
      _scrollToBottom();
    });
    
    _textController.addListener(() => setState(() {}));
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
    
    // Construct history for context awareness
    final history = _messages
        .take(_messages.length - 1) // exclude current user message
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    _chatService.sendMessage(text, chatId: _currentChatId, history: history);
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
          // Deep Space Background
          Container(color: AppColors.background),
          Positioned(
            top: -100,
            right: -100,
            child: _buildAmbientGlow(AppColors.electricBlue, 0.05),
          ),
          
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

  Widget _buildAmbientGlow(Color color, double opacity) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
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
          icon: const Icon(Icons.menu_rounded, color: AppColors.neonCyan, size: 24),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        "AURA",
        style: GoogleFonts.outfit(
          fontSize: 18,
          letterSpacing: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _isVoiceMode = !_isVoiceMode),
          icon: Icon(
            _isVoiceMode ? Icons.chat_bubble_outline_rounded : Icons.mic_rounded,
            color: _isVoiceMode ? AppColors.neonCyan : AppColors.textSecondary,
            size: 24,
          ),
        ),
        if (_canvasContent.isNotEmpty)
          IconButton(
            onPressed: _showCanvasSheet,
            icon: const Icon(Icons.auto_awesome_mosaic_rounded, color: AppColors.electricBlue, size: 24),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatView() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return _buildMessageBubble(msg);
        },
      ),
    );
  }

  Widget _buildVoiceView() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowingOrb(size: 260, state: _orbState),
          const SizedBox(height: 60),
          Text(
            _orbState == OrbState.listening ? "LISTENING" : 
            _orbState == OrbState.thinking ? "THINKING" :
            _orbState == OrbState.speaking ? "AURA SPEAKING" : "STANDBY",
            style: GoogleFonts.outfit(
              color: AppColors.neonCyan, 
              fontSize: 14, 
              letterSpacing: 4.0,
              fontWeight: FontWeight.w900
            ),
          ),
          if (_currentResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: Text(
                _currentResponse,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return _buildUserBubble(msg.text);
    } else {
      return _buildAuraResponse(msg.text);
    }
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 60),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.electricBlue.withOpacity(0.2)),
          ),
          child: Text(
            text,
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildAuraResponse(String text) {
    // Basic detection for structured tiers
    final hasSummary = text.contains('[Quick Summary]');
    final hasInsights = text.contains('[Key Insights]');
    final hasSuggestions = text.contains('[Suggestions]');

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlowingOrb(size: 24),
              const SizedBox(width: 12),
              Text(
                "AURA INTELLIGENCE",
                style: GoogleFonts.outfit(
                  color: AppColors.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: MarkdownBody(
              data: text,
              selectable: true,
              onTapLink: (text, href, title) {},
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16, height: 1.7),
                h1: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 22, fontWeight: FontWeight.bold),
                h2: GoogleFonts.outfit(color: AppColors.electricBlue, fontSize: 18, fontWeight: FontWeight.bold),
                code: GoogleFonts.firaCode(backgroundColor: Colors.transparent, color: AppColors.neonCyan, fontSize: 14),
                codeblockPadding: const EdgeInsets.all(16),
                codeblockDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                blockquote: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16, fontStyle: FontStyle.italic),
                blockquoteDecoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.neonCyan, width: 4)),
                ),
              ),
            ),
          ),
          if (hasSuggestions) _buildFollowUpSuggestions(text),
        ],
      ),
    );
  }

  Widget _buildFollowUpSuggestions(String text) {
    // Extract suggestions between [Suggestions] tags
    final match = RegExp(r'\[Suggestions\]\n([\s\S]*)').firstMatch(text);
    if (match == null) return const SizedBox();
    
    final suggestionLines = match.group(1)?.split('\n') ?? [];
    final suggestions = suggestionLines
        .where((l) => l.startsWith('- '))
        .map((l) => l.replaceFirst('- ', ''))
        .toList();

    if (suggestions.isEmpty) return const SizedBox();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              onPressed: () {
                _textController.text = suggestions[i];
                _handleSend();
              },
              backgroundColor: AppColors.surface,
              label: Text(
                suggestions[i],
                style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              side: BorderSide(color: AppColors.neonCyan.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Message Aura...",
                      hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 15),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) => _handleSend(),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleSend,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _textController.text.isNotEmpty ? AppColors.neonCyan : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded, 
                        color: _textController.text.isNotEmpty ? Colors.black : AppColors.textSecondary, 
                        size: 20
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
              ),
              const SizedBox(width: 12),
              Text(
                _currentTool.isNotEmpty ? "SYNCING..." : "REASONING...",
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
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
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, color: AppColors.neonCyan, size: 24),
                    const SizedBox(width: 12),
                    Text(_canvasTitle, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: HighlightView(
                    _canvasContent,
                    language: _canvasLanguage,
                    theme: atomOneDarkTheme,
                    padding: const EdgeInsets.all(20),
                    textStyle: GoogleFonts.firaCode(fontSize: 13, height: 1.5),
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

class AuraSidebar extends StatefulWidget {
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
  State<AuraSidebar> createState() => _AuraSidebarState();
}

class _AuraSidebarState extends State<AuraSidebar> {
  String _activeWorkspace = "PERSONAL";

  Map<String, List<String>> _groupHistory() {
    final Map<String, List<String>> groups = {
      "TODAY": [],
      "YESTERDAY": [],
      "ARCHIVE": [],
    };

    final now = DateTime.now();
    for (var item in widget.chatHistory) {
      final parts = item.split('|');
      final id = parts[0];
      // Basic heuristic: check id for timestamp
      if (id.startsWith('chat_')) {
        final ts = int.tryParse(id.substring(5)) ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        final diff = now.difference(date).inDays;
        
        if (diff == 0) groups["TODAY"]!.add(item);
        else if (diff == 1) groups["YESTERDAY"]!.add(item);
        else groups["ARCHIVE"]!.add(item);
      } else {
        groups["ARCHIVE"]!.add(item);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupHistory();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Workspace Hub
            _buildWorkspaceHub(),
            
            const Divider(color: AppColors.border, height: 1),
            
            // New Session Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                onTap: () {
                  widget.onNewChat();
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.add_rounded, color: AppColors.neonCyan),
                title: Text(
                  "NEW SESSION", 
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 12, 
                    letterSpacing: 2.0
                  )
                ),
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: AppColors.neonCyan.withOpacity(0.2))
                ),
              ),
            ),

            // History Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (grouped["TODAY"]!.isNotEmpty) _buildSectionHeader("TODAY"),
                  ...grouped["TODAY"]!.map(_buildHistoryItem),
                  
                  if (grouped["YESTERDAY"]!.isNotEmpty) _buildSectionHeader("YESTERDAY"),
                  ...grouped["YESTERDAY"]!.map(_buildHistoryItem),
                  
                  if (grouped["ARCHIVE"]!.isNotEmpty) _buildSectionHeader("ARCHIVE"),
                  ...grouped["ARCHIVE"]!.map(_buildHistoryItem),
                ],
              ),
            ),
            
            _buildUserProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceHub() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlowingOrb(size: 32),
              const SizedBox(width: 12),
              Text(
                "AURA HUB",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["PERSONAL", "RESEARCH", "CODING"].map((ws) {
                final isActive = _activeWorkspace == ws;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ws, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: isActive,
                    onSelected: (val) => setState(() => _activeWorkspace = ws),
                    backgroundColor: Colors.transparent,
                    selectedColor: AppColors.neonCyan.withOpacity(0.2),
                    side: BorderSide(color: isActive ? AppColors.neonCyan : Colors.white10),
                    labelStyle: TextStyle(color: isActive ? AppColors.neonCyan : Colors.white38),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
      child: Text(
        title, 
        style: GoogleFonts.outfit(
          color: Colors.white24, 
          fontSize: 10, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 3.0
        )
      ),
    );
  }

  Widget _buildHistoryItem(String idWithTitle) {
    final parts = idWithTitle.split('|');
    final title = parts.length > 1 ? parts[1] : parts[0];
    return ListTile(
      onTap: () {
        widget.onHistorySelected(idWithTitle);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 18),
      title: Text(
        title, 
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      ),
      trailing: const Icon(Icons.more_horiz_rounded, color: Colors.white10, size: 16),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.electricBlue.withOpacity(0.2),
            radius: 16,
            child: const Icon(Icons.person_rounded, color: AppColors.electricBlue, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("USER_NEURAL_LINK", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("PRO PLAN ACTIVE", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.settings_outlined, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
