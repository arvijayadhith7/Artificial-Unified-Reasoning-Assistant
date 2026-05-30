import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../models/attachment_model.dart';
import '../app_theme.dart';
import '../widgets/attachment_chip.dart';
import '../widgets/file_picker_sheet.dart';
import '../widgets/neural_send_button.dart';

/// Feature-rich chat input bar with multi-modal support:
/// Text, attachments, paste interception, and file picker integration.
class ChatInputBar extends StatefulWidget {
  final void Function(String text, List<ChatAttachment> attachments) onSend;
  final VoidCallback? onVoiceToggle;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onVoiceToggle,
    this.isSending = false,
  });

  @override
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatAttachment> _attachments = [];
  late AnimationController _attachBarAnim;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    _attachBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _attachBarAnim.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _textController.text.trim().isNotEmpty || _attachments.isNotEmpty;

  void _handleSend() {
    final text = _textController.text.trim();
    if (!_hasContent) return;

    widget.onSend(text, List.from(_attachments));
    _textController.clear();
    setState(() {
      _attachments.clear();
    });
    _attachBarAnim.reverse();
  }

  /// Programmatically trigger a text-only send
  void sendText(String text) {
    _textController.text = text;
    _handleSend();
  }

  void _addAttachments(List<ChatAttachment> newAttachments) {
    setState(() {
      _attachments.addAll(newAttachments);
    });
    if (_attachments.isNotEmpty) {
      _attachBarAnim.forward();
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    if (_attachments.isEmpty) {
      _attachBarAnim.reverse();
    }
  }

  void _showFilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FilePickerSheet(
        onFilesSelected: _addAttachments,
      ),
    );
  }

  /// Expose focus for external callers
  FocusNode get focusNode => _focusNode;

  /// Expose text controller for external callers (e.g., suggestion taps)
  TextEditingController get textController => _textController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment preview row
            if (_attachments.isNotEmpty) _buildAttachmentBar(),
            // Main input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentBar() {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _attachments.length,
        itemBuilder: (context, index) {
          return AttachmentChip(
            attachment: _attachments[index],
            onRemove: () => _removeAttachment(index),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // + button (file picker)
              GestureDetector(
                onTap: _showFilePicker,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(bottom: 2, left: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neonCyan.withOpacity(0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.neonCyan,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Text field (auto-expanding, max 6 lines)
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 6,
                  minLines: 1,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: "Message AURA...",
                    hintStyle: GoogleFonts.outfit(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              // Send button
              Padding(
                padding: const EdgeInsets.only(bottom: 2, right: 2),
                child: NeuralSendButton(
                  onTap: _handleSend,
                  isActive: _hasContent,
                  isSending: widget.isSending,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
