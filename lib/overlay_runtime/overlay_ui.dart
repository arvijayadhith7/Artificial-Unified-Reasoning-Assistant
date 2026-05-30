import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'overlay_service.dart';
import 'overlay_socket.dart';
import 'overlay_context.dart';
import 'overlay_memory.dart';
import '../app_theme.dart';

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA Assist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const OverlayMainPage(),
    );
  }
}

class OverlayMainPage extends StatefulWidget {
  const OverlayMainPage({super.key});

  @override
  State<OverlayMainPage> createState() => _OverlayMainPageState();
}

class _OverlayMainPageState extends State<OverlayMainPage> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String _assistantMode = "copilot"; // quick, tutor, copilot, focus, research
  final OverlaySocket _socket = OverlaySocket();
  final List<Map<String, String>> _messages = [];
  
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isSending = false;
  String _currentStatus = "Offline";
  String? _streamingReply;
  bool _isAutoScrollPaused = false;
  
  List<String> _detectedItems = [];
  List<Map<String, String>> _suggestions = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    // Initial size of bubble — compact 52x52 for a cute, non-intrusive feel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OverlayService.resize(52, 52);
      OverlayService.setFocusable(false);
    });

    _socket.connect();
    
    _socket.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });

    _socket.chunkStream.listen((chunk) {
      if (mounted) {
        setState(() {
          _streamingReply = (_streamingReply ?? "") + chunk;
        });
        _scrollToBottom(isStreaming: true);
      }
    });

    _socket.doneStream.listen((_) async {
      if (mounted) {
        final reply = _streamingReply ?? "";
        final userPrompt = _messages.isNotEmpty && _messages.last['role'] == 'user' 
            ? _messages.last['content'] ?? "" 
            : "";
        
        setState(() {
          if (reply.isNotEmpty) {
            _messages.add({'role': 'assistant', 'content': reply});
          }
          _streamingReply = null;
          _isSending = false;
        });
        
        if (userPrompt.isNotEmpty && reply.isNotEmpty) {
          await OverlayMemory.appendTurn(userPrompt, reply);
        }
        _scrollToBottom(force: true);
      }
    });

    _socket.errorStream.listen((err) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': "⚠️ $err"});
          _streamingReply = null;
          _isSending = false;
        });
        _scrollToBottom(force: true);
      }
    });

    _socket.contextStream.listen((contextData) {
      if (mounted) {
        setState(() {
          _detectedItems = List<String>.from(contextData['detected_items'] ?? []);
          _suggestions = List<Map<String, String>>.from(contextData['suggestions'] ?? []);
        });
        _scrollToBottom(force: true);
      }
    });

    _focusNode.addListener(() {
      // Toggle native focusable state when the TextField has focus
      OverlayService.setFocusable(_focusNode.hasFocus);
    });

    _loadConversationHistory();
  }

  Future<void> _loadConversationHistory() async {
    final history = await OverlayMemory.load();
    if (mounted) {
      setState(() {
        _messages.addAll(history);
        if (_messages.isEmpty) {
          _messages.add({
            'role': 'assistant',
            'content': 'How can I assist you in your current workflow today?'
          });
        }
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socket.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool force = false, bool isStreaming = false}) {
    if (_isAutoScrollPaused && !force) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        if (isStreaming) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      OverlayService.resize(300, 420);
      OverlayService.setFocusable(true);
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      OverlayService.resize(52, 52);
      OverlayService.setFocusable(false);
      _focusNode.unfocus();
    }
  }

  void _cycleMode() {
    final modes = ["quick", "tutor", "copilot", "focus", "research"];
    final idx = modes.indexOf(_assistantMode);
    setState(() {
      _assistantMode = modes[(idx + 1) % modes.length];
      _messages.add({
        'role': 'assistant',
        'content': 'System Mode changed to: **${_assistantMode.toUpperCase()}**'
      });
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
      _streamingReply = "";
    });
    _inputController.clear();
    _scrollToBottom(force: true);

    // Compile active workflow metadata from service
    final sandbox = await OverlayContext.buildSandboxPayload(
      assistantMode: _assistantMode,
      includeScreenshot: _assistantMode == 'research' || text.toLowerCase().contains('screen'),
    );

    final history = await OverlayMemory.load();
    _socket.send({
      'prompt': text,
      'conversationId': 'aura_overlay',
      'projectId': 'overlay',
      'history': history,
      'sandbox': sandbox,
    });
  }

  Future<void> _scanContext() async {
    setState(() {
      _messages.add({'role': 'assistant', 'content': 'Scanning active screen and process details...'});
      _isSending = true;
    });
    _scrollToBottom(force: true);

    final metadata = await OverlayContext.gatherScreenMetadata();
    final screenshot = await OverlayContext.gatherScreenshot();

    _socket.send({
      'event': 'analyze',
      'type': 'analyze',
      'active_app': metadata['active_app'],
      'window_title': metadata['window_title'],
      'accessibility_text': metadata['accessibility_text'],
      if (screenshot != null) 'screenshot': screenshot,
    });
  }

  void _clearChat() async {
    await OverlayMemory.clear();
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content': 'Conversation memory cleared. Ready for next workflow.'
      });
    });
    _scrollToBottom(force: true);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return _buildBubble();
    }
    return _buildExpandedChat();
  }

  Widget _buildBubble() {
    return GestureDetector(
      onPanUpdate: (details) {
        OverlayService.updatePosition(details.delta.dx, details.delta.dy);
      },
      onTap: _toggleExpanded,
      child: Center(
        child: ScaleTransition(
          scale: _pulseController,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF00FFFF),
                  Color(0xFF7C3AED),
                  Color(0xFFEC4899),
                  Color(0xFF06B6D4),
                  Color(0xFF00FFFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF050A18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00FFFF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedChat() {
    return Center(
      child: Container(
        width: 286,
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xF00A0E1A), // Sleek glassmorphic deep space dark
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF00FFFF).withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: const Color(0xFF00FFFF).withOpacity(0.06),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Drag & Action Header
            GestureDetector(
              onPanUpdate: (details) {
                OverlayService.updatePosition(details.delta.dx, details.delta.dy);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentStatus.toLowerCase().contains("online") ||
                                _currentStatus.toLowerCase().contains("connected")
                            ? AppColors.neonCyan
                            : (_currentStatus.toLowerCase().contains("connecting")
                                ? Colors.amber
                                : Colors.redAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _cycleMode,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          _assistantMode.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentStatus.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _clearChat,
                      tooltip: "Clear Memory",
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleExpanded,
                      child: const Icon(Icons.minimize_rounded, color: Colors.white70, size: 18),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => OverlayService.close(),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            
            // Messages Board
            Expanded(
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
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length + (_streamingReply != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildMessageBubble('assistant', _streamingReply!);
                    }
                    final msg = _messages[index];
                    return _buildMessageBubble(msg['role']!, msg['content']!);
                  },
                ),
              ),
            ),

            // Dynamic Context Area (Chips and recommendations)
            if (_detectedItems.isNotEmpty || _suggestions.isNotEmpty)
              _buildContextBar(),

            // Bottom Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  // Scan button
                  InkWell(
                    onTap: _isSending ? null : _scanContext,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.neonCyan, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Type task instructions...",
                        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: AppColors.neonCyan, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String role, String text) {
    final isUser = role == 'user';
    final isSystem = role == 'system';
    
    Color bubbleColor = const Color(0xFF1E293B);
    Color borderColor = Colors.transparent;
    
    if (isUser) {
      bubbleColor = const Color(0xFF121824);
      borderColor = Colors.white.withOpacity(0.12);
    } else if (isSystem) {
      bubbleColor = const Color(0x66991B1B);
    } else {
      bubbleColor = const Color(0xFF0F172A);
      borderColor = AppColors.neonCyan.withOpacity(0.3);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14).copyWith(
            topRight: isUser ? const Radius.circular(0) : const Radius.circular(14),
            topLeft: !isUser ? const Radius.circular(0) : const Radius.circular(14),
          ),
          border: borderColor != Colors.transparent ? Border.all(color: borderColor, width: 1) : null,
        ),
        child: MarkdownBody(
          data: text,
          onTapLink: (linkText, href, title) {
            if (href != null) _launchURL(href);
          },
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.outfit(color: Colors.white, fontSize: 12, height: 1.4),
            h1: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
            h2: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            code: GoogleFonts.firaCode(color: const Color(0xFFFFA726), fontSize: 10, backgroundColor: Colors.transparent),
            codeblockPadding: const EdgeInsets.all(6),
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextBar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      width: double.infinity,
      color: Colors.black.withOpacity(0.2),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        children: [
          if (_detectedItems.isNotEmpty)
            SizedBox(
              height: 24,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _detectedItems.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        _detectedItems[i],
                        style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 9),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_detectedItems.isNotEmpty && _suggestions.isNotEmpty)
            const SizedBox(height: 6),
          if (_suggestions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _suggestions.map((sug) {
                final label = sug['label'] ?? sug['prompt'] ?? '';
                final prompt = sug['prompt'] ?? sug['label'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      _inputController.text = prompt;
                      _sendMessage();
                      setState(() {
                        _suggestions.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
