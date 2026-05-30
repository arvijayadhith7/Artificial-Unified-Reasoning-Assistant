import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../app_theme.dart';

/// ChatGPT-style per-message action toolbar.
/// Renders below each AURA response with: Copy, Regenerate, Like, Dislike, Share, Export
class MessageActionsBar extends StatefulWidget {
  final String messageText;
  final VoidCallback onRegenerate;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final int messageIndex;

  const MessageActionsBar({
    super.key,
    required this.messageText,
    required this.onRegenerate,
    required this.messageIndex,
    this.onLike,
    this.onDislike,
  });

  @override
  State<MessageActionsBar> createState() => _MessageActionsBarState();
}

class _MessageActionsBarState extends State<MessageActionsBar>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  bool _liked = false;
  bool _disliked = false;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.messageText));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _handleLike() {
    setState(() {
      _liked = !_liked;
      if (_liked) _disliked = false;
    });
    widget.onLike?.call();
  }

  void _handleDislike() {
    setState(() {
      _disliked = !_disliked;
      if (_disliked) _liked = false;
    });
    widget.onDislike?.call();
  }

  void _handleShare() {
    Share.share(widget.messageText);
  }

  void _handleExport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildExportSheet(),
    );
  }

  Future<void> _exportAs(String format) async {
    Navigator.pop(context); // Close the sheet
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName;
      String content;

      switch (format) {
        case 'md':
          fileName = 'aura_response_$timestamp.md';
          content = '# AURA Response\n\n${widget.messageText}';
          break;
        case 'txt':
          fileName = 'aura_response_$timestamp.txt';
          content = widget.messageText;
          break;
        default:
          fileName = 'aura_response_$timestamp.txt';
          content = widget.messageText;
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AURA Response Export',
      );
    } catch (e) {
      debugPrint("Export error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
            tooltip: _copied ? "Copied!" : "Copy",
            isActive: _copied,
            activeColor: const Color(0xFF76FF03),
            onTap: _handleCopy,
          ),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            tooltip: "Regenerate",
            onTap: widget.onRegenerate,
          ),
          _buildActionButton(
            icon: _liked
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            tooltip: "Good response",
            isActive: _liked,
            activeColor: AppColors.neonCyan,
            onTap: _handleLike,
          ),
          _buildActionButton(
            icon: _disliked
                ? Icons.thumb_down_rounded
                : Icons.thumb_down_outlined,
            tooltip: "Bad response",
            isActive: _disliked,
            activeColor: const Color(0xFFFF5252),
            onTap: _handleDislike,
          ),
          _buildActionButton(
            icon: Icons.share_rounded,
            tooltip: "Share",
            onTap: _handleShare,
          ),
          _buildActionButton(
            icon: Icons.download_rounded,
            tooltip: "Export",
            onTap: _handleExport,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = isActive
        ? (activeColor ?? AppColors.neonCyan)
        : Colors.white.withOpacity(0.25);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildExportSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "EXPORT RESPONSE",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                icon: Icons.description_rounded,
                label: "Markdown (.md)",
                color: const Color(0xFF00E5FF),
                onTap: () => _exportAs('md'),
              ),
              const SizedBox(height: 10),
              _buildExportOption(
                icon: Icons.text_snippet_rounded,
                label: "Plain Text (.txt)",
                color: const Color(0xFF76FF03),
                onTap: () => _exportAs('txt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
