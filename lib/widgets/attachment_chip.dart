import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/attachment_model.dart';
import '../app_theme.dart';

/// A compact chip that previews an attached file (image thumbnail, doc icon, code icon)
/// with a pulsing upload indicator and ✕ remove button.
class AttachmentChip extends StatefulWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final bool isUploading;

  const AttachmentChip({
    super.key,
    required this.attachment,
    required this.onRemove,
    this.isUploading = false,
  });

  @override
  State<AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<AttachmentChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isUploading) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AttachmentChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUploading && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isUploading && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isUploading ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        constraints: const BoxConstraints(maxWidth: 160),
        decoration: BoxDecoration(
          color: widget.attachment.accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.attachment.accentColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPreview(),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.attachment.formattedSize,
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildRemoveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.attachment.type == AttachmentType.image) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: Image.file(
          File(widget.attachment.path),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildIconPreview(),
        ),
      );
    }
    return _buildIconPreview();
  }

  Widget _buildIconPreview() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.attachment.accentColor.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          widget.attachment.icon,
          color: widget.attachment.accentColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return GestureDetector(
      onTap: widget.onRemove,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.close_rounded,
          color: Colors.white38,
          size: 14,
        ),
      ),
    );
  }
}
