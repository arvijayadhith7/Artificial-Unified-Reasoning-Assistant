import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../app_theme.dart';
import '../chat_service.dart';
import '../models/attachment_model.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/neural_send_button.dart';
import '../widgets/neural_thinking_indicator.dart';
import '../widgets/aura_assist_bubble.dart';
import '../widgets/neural_halo.dart';
import '../widgets/semantic_reveal.dart';
import '../widgets/overlay_permission_dialog.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_actions_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const ChatScreen({super.key, this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ChatInputBarState> _inputKey = GlobalKey<ChatInputBarState>();
  bool _isVoiceMode = false;
  OrbState _orbState = OrbState.idle;
  String _currentResponse = "";
  String _currentThought = "";
  bool _isSending = false;
  String _canvasContent = "";
  String _canvasLanguage = "plaintext";
  final String _canvasTitle = "Neural Output";
  bool _isCanvasMarkdown = false;
  bool _isAutoScrollPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadRecentChats(projectId: widget.projectId);
      
      ref.listenManual(chatProvider.select((s) => s.activeConvId), (prev, next) {
        if (prev != next) {
          setState(() {
            _currentResponse = "";
            _currentThought = "";
            _canvasContent = "";
            _orbState = OrbState.idle;
          });
        }
      });

      ref.listenManual(chatProvider.select((s) => s.isLoading), (prev, next) {
        if (prev == true && next == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    });
    
    _chatService.connect();
    _chatService.responseStream.listen((data) {
      final type = data['type'];
      final content = data['content'] as String?;

      if (type == 'chunk' && content != null) {
        setState(() {
          _orbState = OrbState.speaking;
          _currentResponse += content;
        });
        ref.read(chatProvider.notifier).updateLastMessage(content);
        _detectCodeInResponse(_currentResponse);
        _scrollToBottom(isStreaming: true);
      } else if (type == 'thought' && content != null) {
        setState(() {
          _orbState = OrbState.thinking;
          _currentThought += content; // Append to accumulate the thought process!
        });
        ref.read(chatProvider.notifier).updateLastMessageThought(_currentThought);
        _scrollToBottom(isStreaming: true);
      } else if (data['done'] == true) {
        setState(() {
          _orbState = OrbState.idle;
          _isSending = false;
        });
        _scrollToBottom(force: true);
      }
    });
  }

  void _scrollToBottom({bool force = false, bool isStreaming = false}) {
    if (!_scrollController.hasClients) return;
    if (_isAutoScrollPaused && !force) return; // ChatGPT behavior: pause if user scrolled up
    
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

  void _handleSend(String text, [List<ChatAttachment> attachments = const []]) async {
    final chatState = ref.read(chatProvider);
    final conversationId = chatState.activeConvId ?? "conv_${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      _currentResponse = "";
      _currentThought = ""; // Clear for the new request!
      _orbState = OrbState.thinking;
      _isSending = true;
    });

    // Render attachments in user bubble by saving in state
    final userMsg = {
      'role': 'user',
      'content': text,
      'attachments': attachments.map((a) => {
        'name': a.name,
        'path': a.path,
        'mimeType': a.mimeType,
        'sizeBytes': a.sizeBytes,
        'type': a.type.name,
      }).toList(),
    };

    ref.read(chatProvider.notifier).addMessage(userMsg);

    // Upload attachments to backend to get their URLs
    List<String> uploadedUrls = [];
    if (attachments.isNotEmpty) {
      final files = attachments.map((a) => File(a.path)).toList();
      uploadedUrls = await _chatService.uploadFiles(files);
    }
    
    _chatService.sendMessage(
      text, 
      conversationId: conversationId,
      projectId: widget.projectId,
      history: chatState.currentMessages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
      attachmentUrls: uploadedUrls,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true); // Force scroll when user sends a message
    });
  }

  @override
  void dispose() {
    _chatService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AuraSidebar(),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildNeuralAtmosphere(),
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40),
              if (_isVoiceMode) _buildVoiceView() else _buildChatView(),
              ChatInputBar(
                key: _inputKey,
                onSend: _handleSend,
                isSending: _isSending,
              ),
            ],
          ),
          _buildThinkingAura(),
          AuraAssistBubble(
            onSuggestionTapped: (suggestion) {
              _inputKey.currentState?.sendText(suggestion);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralAtmosphere() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: _buildAmbientGlow(AppColors.electricBlue, 0.05),
        ),
        Positioned(
          bottom: 200,
          left: -50,
          child: _buildAmbientGlow(AppColors.violetGlow, 0.03),
        ),
      ],
    );
  }

  Widget _buildAmbientGlow(Color color, double opacity) {
    return Container(
      width: 400, height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }

  void _showAuraAssistantChooser(BuildContext context) {
    final settings = ref.read(settingsProvider);
    final isDark = settings.themeMode == 'DARK';
    final accent = AppTheme.getAccentColor(settings.accentColor);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AURA ASSISTANT CHOOSE ENVIRONMENT",
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                final isOverlayVisible = ref.read(overlayVisibleProvider);
                ref.read(overlayVisibleProvider.notifier).state = !isOverlayVisible;
              },
              leading: Icon(Icons.chat_bubble_outline_rounded, color: accent),
              title: Text(
                "Use Inside App",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Toggle floating assistant bubble inside the current chat",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                handleActivateOverlay(context, ref);
              },
              leading: Icon(Icons.picture_in_picture_alt_rounded, color: accent),
              title: Text(
                "Use Outside App (System Overlay)",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Launch system-wide overlay assistant over other apps",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
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
        style: GoogleFonts.outfit(fontSize: 18, letterSpacing: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.9)),
      ),
      actions: [
        Center(
          child: NeuralHaloWidget(
            onTap: () => _showAuraAssistantChooser(context),
          ),
        ),
        const SizedBox(width: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length + (_isSending && _currentResponse.isEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < messages.length) {
              final msg = messages[index] as Map;
              final isUser = msg['role'] == 'user';
              return _buildAnimatedBubble(isUser, msg, index);
            } else {
              return const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: NeuralThinkingIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble(bool isUser, Map msg, int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildMessageBubble(isUser, msg, index),
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
            style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 14, letterSpacing: 4.0, fontWeight: FontWeight.w900),
          ),
          if (_currentResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: SemanticReveal(text: _currentResponse, isStreaming: true),
            ),
        ],
      ),
    );
  }

  String _parseAndFormatTimestamp(dynamic timestampVal) {
    if (timestampVal == null) return "";
    try {
      final tsStr = timestampVal.toString();
      final doubleValue = double.tryParse(tsStr);
      if (doubleValue != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch((doubleValue * 1000).toInt());
        return TimeOfDay.fromDateTime(dt).format(context);
      }
      final dt = DateTime.parse(tsStr);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return "";
    }
  }

  Widget _buildMessageBubble(bool isUser, Map msg, int index) {
    final timestamp = _parseAndFormatTimestamp(msg['timestamp']);

    if (isUser) {
      return _buildUserBubble(msg, timestamp);
    } else {
      return _buildAuraResponse(msg['content'] ?? '', timestamp, index, msg['thought']);
    }
  }

  Widget _buildUserBubble(Map msg, String time) {
    final text = msg['content'] ?? '';
    final List<dynamic> attachmentsData = msg['attachments'] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(4)),
              border: Border.all(color: AppColors.electricBlue.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (text.isNotEmpty)
                  Text(text, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15)),
                if (attachmentsData.isNotEmpty) ...[
                  if (text.isNotEmpty) const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: attachmentsData.map((aData) {
                      final name = aData['name'] as String;
                      final path = aData['path'] as String;
                      final typeStr = aData['type'] as String;
                      
                      final isImage = typeStr == 'image';
                      final accentColor = isImage ? AppColors.electricBlue : AppColors.neonCyan;
                      
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.insert_drive_file_rounded, color: AppColors.electricBlue, size: 20),
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  typeStr == 'code' ? Icons.code_rounded :
                                  typeStr == 'document' ? Icons.description_rounded : Icons.insert_drive_file_rounded,
                                  color: accentColor,
                                  size: 16,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(time, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAuraResponse(String text, String time, int index, [String? thought]) {
    final hasSuggestions = text.contains('[Suggestions]');
    final cleanText = text.split('[Suggestions]')[0].trim();
    final displayThought = (thought ?? "").isNotEmpty ? thought : (text == _currentResponse ? _currentThought : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlowingOrb(size: 16),
              const SizedBox(width: 12),
              Text("AURA NEURAL OS", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Spacer(),
              Text(time, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildRefineButton(cleanText),
            ],
          ),
          const SizedBox(height: 16),

          if (displayThought != null && displayThought.isNotEmpty) ...[
            _buildReasoningBlock(displayThought),
            const SizedBox(height: 12),
          ],
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SemanticReveal(
              text: cleanText, 
              isStreaming: text == _currentResponse,
            ),
          ),
          if (text != _currentResponse && !cleanText.endsWith("..."))
            MessageActionsBar(
              messageText: cleanText,
              messageIndex: index,
              onRegenerate: () => _handleRegenerate(index),
            ),
          if (hasSuggestions) _buildFollowUpSuggestions(text),
        ],
      ),
    );
  }

  void _handleRegenerate(int index) {
    final chatState = ref.read(chatProvider);
    final messages = chatState.currentMessages;
    if (index <= 0 || index >= messages.length) return;

    final userMsg = messages[index - 1];
    if (userMsg['role'] != 'user') return;

    final prompt = userMsg['content'] as String;
    
    // Extract attachments if they were present
    final List<dynamic> attachmentsData = userMsg['attachments'] ?? [];
    final List<ChatAttachment> attachments = attachmentsData.map((a) {
      return ChatAttachment(
        name: a['name'],
        path: a['path'],
        mimeType: a['mimeType'],
        sizeBytes: a['sizeBytes'],
        type: AttachmentType.values.firstWhere((t) => t.name == a['type'], orElse: () => AttachmentType.unknown),
      );
    }).toList();

    // Truncate the list of messages back to index - 1
    ref.read(chatProvider.notifier).truncateMessages(index - 1);

    // Call _handleSend to re-send the prompt
    _handleSend(prompt, attachments);
  }

  Widget _buildRefineButton(String text) {
    return GestureDetector(
      onTap: () => _handleRefine(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neonCyan.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: AppColors.neonCyan, size: 10),
            const SizedBox(width: 4),
            Text("REFINE", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _handleRefine(String text) async {
    setState(() => _orbState = OrbState.thinking);
    final refined = await _chatService.refineMessage(text);
    if (refined != null && mounted) {
      setState(() {
        _currentResponse = refined;
        _orbState = OrbState.idle;
      });
      ref.read(chatProvider.notifier).updateLastMessage(refined, isFullReplace: true);
    }
  }

  Widget _buildReasoningBlock(String thought) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonCyan.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.neonCyan, size: 14),
                const SizedBox(width: 8),
                Text("COGNITIVE TRACE", style: GoogleFonts.outfit(color: AppColors.neonCyan.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 10),
            Text(thought, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpSuggestions(String text) {
    final match = RegExp(r'\[Suggestions\]\n([\s\S]*)').firstMatch(text);
    if (match == null) return const SizedBox();
    final suggestionLines = match.group(1)?.split('\n') ?? [];
    final suggestions = suggestionLines.where((l) => l.startsWith('- ')).map((l) => l.replaceFirst('- ', '')).toList();
    if (suggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: suggestions.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    _inputKey.currentState?.sendText(suggestions[i]);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(suggestions[i], style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingAura() {
    return const SizedBox();
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
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white38)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: HighlightView(_canvasContent, language: _canvasLanguage, theme: atomOneDarkTheme, padding: const EdgeInsets.all(20), textStyle: GoogleFonts.firaCode(fontSize: 13, height: 1.5)),
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
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context); // Close sidebar
                  handleActivateOverlay(context, ref);
                },
                leading: const Icon(Icons.picture_in_picture_alt_rounded, color: AppColors.neonCyan),
                title: Text("USE AURA OUTSIDE APP", style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2.0)),
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
          onPressed: () => _showDeleteConfirmDialog(chat['id'], chat['title'] ?? "Neural Session"),
          tooltip: "Delete chat",
          splashRadius: 18,
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String convId, String chatTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        title: Text(
          "Delete Chat",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Permanently delete \"$chatTitle\"? This cannot be undone.",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(chatProvider.notifier).deleteChat(convId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Chat deleted", style: GoogleFonts.outfit(color: Colors.white)),
                    backgroundColor: Colors.red.withOpacity(0.8),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text("Delete", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
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
