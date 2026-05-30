import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class SemanticReveal extends StatefulWidget {
  final String text;
  final bool isStreaming;

  const SemanticReveal({
    super.key,
    required this.text,
    this.isStreaming = false,
  });

  @override
  State<SemanticReveal> createState() => _SemanticRevealState();
}

class _SemanticRevealState extends State<SemanticReveal> with TickerProviderStateMixin {
  late String _displayText;
  
  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void didUpdateWidget(SemanticReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _displayText = widget.text;
    }
  }

  MarkdownStyleSheet _getMarkdownStyle() {
    return MarkdownStyleSheet(
      p: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 16, height: 1.7),
      h1: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 22, fontWeight: FontWeight.bold),
      h2: GoogleFonts.outfit(color: AppColors.electricBlue, fontSize: 18, fontWeight: FontWeight.bold),
      code: GoogleFonts.firaCode(backgroundColor: Colors.white.withOpacity(0.05), color: AppColors.neonCyan, fontSize: 13),
      codeblockPadding: const EdgeInsets.all(16),
      codeblockDecoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      blockquote: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15, fontStyle: FontStyle.italic),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.neonCyan, width: 3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStreaming) {
      // Direct rendering during streaming for maximum speed and zero jank
      return MarkdownBody(
        data: widget.text,
        selectable: true,
        styleSheet: _getMarkdownStyle(),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: MarkdownBody(
        data: _displayText,
        selectable: true,
        styleSheet: _getMarkdownStyle(),
      ),
    );
  }
}
