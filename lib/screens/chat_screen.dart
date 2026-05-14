import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../app_theme.dart';
import '../chat_service.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/neural_send_button.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _isVoiceMode = false;
  OrbState _orbState = OrbState.idle;
  String _currentResponse = "";
  String _currentThought = "";
  String _currentTool = "";
  String _canvasContent = "";
  String _canvasLanguage = "plaintext";
  bool _isCanvasMarkdown = false;
  bool _isSending = false;
  final String _selectedModel = 'aura';

  String _canvasTitle = "Neural Output";

  // Chat history
  List<String> _chatHistory = [];
  bool _chatSaved = false;
  String? _currentChatId;
  String? _currentChatTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadRecentChats();
    });
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    
    _chatService.connect();
    _chatService.responseStream.listen((data) {
      final type = data['type'];
      final content = data['content'] as String?;

      if (type == 'chunk' && content != null) {
        setState(() {
          _orbState = OrbState.speaking;
          _currentResponse += content;
          _currentThought = "";
          _currentTool = "";
        });
        ref.read(chatProvider.notifier).updateLastMessage(content);
        _detectCodeInResponse(_currentResponse);
      } else if (type == 'thought' && content != null) {
        setState(() {
          _orbState = OrbState.thinking;
          _currentThought = content;
        });
      } else if (data['done'] == true) {
        setState(() {
          _orbState = OrbState.idle;
          _isSending = false;
        });
      }
      _scrollToBottom();
    });

    // Listen to conversation changes to reset local state
    ref.listenManual(chatProvider.select((s) => s.activeConvId), (prev, next) {
      if (prev != next) {
        setState(() {
          _currentResponse = "";
          _currentThought = "";
          _currentTool = "";
          _canvasContent = "";
          _orbState = OrbState.idle;
        });
      }
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

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final chatState = ref.read(chatProvider);
    final conversationId = chatState.activeConvId ?? "conv_${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      _currentResponse = "";
      _textController.clear();
      _orbState = OrbState.thinking;
      _isSending = true;
    });

    ref.read(chatProvider.notifier).addMessage({'role': 'user', 'content': text});
    
    _chatService.sendMessage(
      text, 
      conversationId: conversationId,
      history: chatState.currentMessages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
    );
    
    _scrollToBottom();
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
      drawer: const AuraSidebar(),
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
    final messages = ref.watch(chatProvider).currentMessages;
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isUser = msg['role'] == 'user';
          return _buildMessageBubble(isUser, msg['content'] ?? '');
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

  Widget _buildMessageBubble(bool isUser, String text) {
    if (isUser) {
      return _buildUserBubble(text);
    } else {
      return _buildAuraResponse(text);
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
                NeuralSendButton(
                  onTap: _handleSend,
                  isActive: _textController.text.isNotEmpty,
                  isSending: _isSending,
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

class AuraSidebar extends ConsumerStatefulWidget {
  const AuraSidebar({super.key});

  @override
  ConsumerState<AuraSidebar> createState() => _AuraSidebarState();
}

class _AuraSidebarState extends ConsumerState<AuraSidebar> {
  String _activeWorkspace = "PERSONAL";

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final recentChats = chatState.recentChats;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildWorkspaceHub(),
            const Divider(color: AppColors.border, height: 1),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                onTap: () {
                  ref.read(chatProvider.notifier).startNewChat();
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.add_rounded, color: AppColors.neonCyan),
                title: Text("NEW SESSION", style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2.0)),
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.neonCyan.withOpacity(0.2))),
              ),
            ),

            Expanded(
              child: chatState.isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentChats.length,
                    itemBuilder: (context, index) {
                      final chat = recentChats[index];
                      final isActive = chatState.activeConvId == chat['id'];
                      return _buildHistoryItem(chat, isActive);
                    },
                  ),
            ),
            
            _buildUserProfile(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> chat, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.neonCyan.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? AppColors.neonCyan.withOpacity(0.3) : Colors.transparent),
      ),
      child: ListTile(
        onTap: () {
          ref.read(chatProvider.notifier).openChat(chat['id']);
          Navigator.pop(context);
        },
        title: Text(
          chat['title'] ?? "Neural Session",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: isActive ? AppColors.neonCyan : Colors.white70, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(
          chat['last_message'] ?? "No message",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10, size: 16),
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
              Text("AURA HUB", style: GoogleFonts.outfit(fontSize: 14, letterSpacing: 6, fontWeight: FontWeight.w900, color: Colors.white)),
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

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Julian Thorne", style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text("PRO PLAN", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}
