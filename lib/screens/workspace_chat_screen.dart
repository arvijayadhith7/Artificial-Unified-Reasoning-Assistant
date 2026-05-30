import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cofounder_chat_provider.dart';
import '../app_theme.dart';
import '../chat_service.dart';
import '../services/workspace_service.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/neural_send_button.dart';
import '../widgets/aura_assist_bubble.dart';
import '../widgets/neural_halo.dart';

class WorkspaceChatScreen extends ConsumerStatefulWidget {
  final Project project;
  const WorkspaceChatScreen({super.key, required this.project});

  @override
  ConsumerState<WorkspaceChatScreen> createState() => _WorkspaceChatScreenState();
}

class _WorkspaceChatScreenState extends ConsumerState<WorkspaceChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String _currentResponse = "";

  String _statusMessage = "Searching latest information...";
  bool _isSending = false;
  bool _isAutoScrollPaused = false;

  final List<String> _quickActions = [
    "Build API Plan",
    "Suggest Features",
    "UI Roadmap",
    "Database Schema",
    "Monetization Strategy",
    "Tech Stack Audit"
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom(force: true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(cofounderChatProvider.notifier);
      notifier.loadProjectChats(widget.project.id);
    });
    
    _chatService.connect();
    _chatService.responseStream.listen((data) {
      final type = data['type'];
      final content = data['content'] as String?;

      if (type == 'chunk' && content != null) {
        setState(() {
          _currentResponse += content;
        });
        ref.read(cofounderChatProvider.notifier).updateLastMessage(content);
        _scrollToBottom(isStreaming: true);
      } else if (type == 'status' && content != null) {
        setState(() {
          _statusMessage = content;
        });
      } else if (type == 'thought' && content != null) {
        setState(() {
          _statusMessage = "Searching latest information...";
        });
      } else if (data['done'] == true) {
        setState(() {
          _isSending = false;
          _statusMessage = "Looking that up...";
        });
        _scrollToBottom(force: true);
      }
    });
  }

  void _scrollToBottom({bool force = false, bool isStreaming = false}) {
    if (!_scrollController.hasClients) return;
    if (_isAutoScrollPaused && !force) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      
      if (isStreaming) {
        _scrollController.jumpTo(maxScroll);
      } else {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final chatState = ref.read(cofounderChatProvider);
    final conversationId = chatState.activeConvId ?? "cofounder_${widget.project.id}_${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      _currentResponse = "";
      if (customText == null) _textController.clear();
      _isSending = true;
    });

    ref.read(cofounderChatProvider.notifier).addMessage({'role': 'user', 'content': text});
    
    _chatService.sendMessage(
      text, 
      conversationId: conversationId,
      projectId: widget.project.id,
      history: chatState.currentMessages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
    );
    
    _scrollToBottom();
  }

  void _handleRefine(String originalText) async {
    setState(() {
      _statusMessage = "Getting live updates...";
      _isSending = true;
    });

    final refined = await _chatService.refineMessage(originalText);
    
    if (refined != null) {
      ref.read(cofounderChatProvider.notifier).addMessage({'role': 'assistant', 'content': refined});
    }

    setState(() {
      _isSending = false;
      _statusMessage = "Looking that up...";
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildAmbientGlow(),
          Column(
            children: [
              _buildChatList(),
              _buildQuickActions(),
              _buildInputSection(),
            ],
          ),
          if (_isSending) _buildNeuralStatus(),
          AuraAssistBubble(
            onSuggestionTapped: (suggestion) {
              _textController.text = suggestion;
              _handleSend();
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neonCyan),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(widget.project.title.toUpperCase(), 
            style: GoogleFonts.outfit(fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w900, color: Colors.white)),
          Text("CO-FOUNDER SESSION", 
            style: GoogleFonts.outfit(fontSize: 8, color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
      actions: [
        const Center(
          child: NeuralHaloWidget(),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, color: Colors.white24),
          onPressed: () {
            ref.read(cofounderChatProvider.notifier).startNewSession(widget.project.id);
          },
          tooltip: "New Session",
        ),
      ],
    );
  }

  Widget _buildAmbientGlow() {
    return Positioned(
      top: -150, left: -100,
      child: Container(
        width: 400, height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.neonCyan.withOpacity(0.05), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final messages = ref.watch(cofounderChatProvider).currentMessages;
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            final isUserScroll = notification.dragDetails != null ||
                _scrollController.position.userScrollDirection != ScrollDirection.idle;
            if (isUserScroll) {
              final metrics = notification.metrics;
              if (metrics.extentAfter > 30) {
                if (!_isAutoScrollPaused) {
                  setState(() {
                    _isAutoScrollPaused = true;
                  });
                }
              } else {
                if (_isAutoScrollPaused) {
                  setState(() {
                    _isAutoScrollPaused = false;
                  });
                }
              }
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: messages.length + (_isSending && _currentResponse.isEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < messages.length) {
              final msg = messages[index];
              final isUser = msg['role'] == 'user';
              return _buildMessageBubble(isUser, msg['content'] ?? '');
            } else {
              return _buildTypingIndicatorBubble();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlowingOrb(size: 14),
              const SizedBox(width: 8),
              Text("AURA", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Aura is typing", style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.neonCyan.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) 
            Row(
              children: [
                const GlowingOrb(size: 14),
                const SizedBox(width: 8),
                Text("AURA CO-FOUNDER", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.neonCyan),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _handleRefine(text),
                  tooltip: "Neural Refine",
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? AppColors.neonCyan.withOpacity(0.05) : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUser ? AppColors.neonCyan.withOpacity(0.2) : AppColors.border),
            ),
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(color: Colors.white, fontSize: 15, height: 1.6),
                h1: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 20, fontWeight: FontWeight.bold),
                code: GoogleFonts.firaCode(backgroundColor: Colors.white.withOpacity(0.05), color: AppColors.neonCyan, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickActions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              onPressed: () => _handleSend("Aura, please ${_quickActions[index]} for this project."),
              backgroundColor: AppColors.surface,
              label: Text(_quickActions[index], style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
              side: BorderSide(color: AppColors.neonCyan.withOpacity(0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Consult with your AI Co-Founder...",
                        hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
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
      ),
    );
  }

  Widget _buildNeuralStatus() {
    return Positioned(
      bottom: 120, left: 0, right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.neonCyan.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.neonCyan.withOpacity(0.2), blurRadius: 40, spreadRadius: 8),
                    BoxShadow(color: AppColors.electricBlue.withOpacity(0.1), blurRadius: 60, spreadRadius: 15),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.neonCyan),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neonCyan.withOpacity(0.8))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(_statusMessage.toUpperCase(), style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
