import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/attachment_model.dart';
import '../app_theme.dart';

/// Glassmorphic bottom sheet with file-picking options:
/// Camera, Gallery, Document, Code File
class FilePickerSheet extends StatelessWidget {
  final void Function(List<ChatAttachment> attachments) onFilesSelected;

  const FilePickerSheet({super.key, required this.onFilesSelected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.neonCyan, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "ATTACH FILES",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Options grid
              Row(
                children: [
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.camera_alt_rounded,
                      label: "Camera",
                      color: const Color(0xFF00E5FF),
                      onTap: () => _pickFromCamera(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.photo_library_rounded,
                      label: "Gallery",
                      color: const Color(0xFF7C4DFF),
                      onTap: () => _pickFromGallery(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.description_rounded,
                      label: "Document",
                      color: const Color(0xFFFF6D00),
                      onTap: () => _pickDocuments(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.code_rounded,
                      label: "Code File",
                      color: const Color(0xFF76FF03),
                      onTap: () => _pickCodeFiles(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Size limit note
              Text(
                "Maximum file size: 25 MB",
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (image != null) {
        final attachment = ChatAttachment.fromFile(File(image.path));
        if (attachment.exceedsLimit) {
          _showSizeError(context);
          return;
        }
        onFilesSelected([attachment]);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        final attachments = images
            .map((img) => ChatAttachment.fromFile(File(img.path)))
            .where((a) => !a.exceedsLimit)
            .toList();
        if (attachments.isNotEmpty) {
          onFilesSelected(attachments);
        }
      }
    } catch (e) {
      debugPrint("Gallery error: $e");
    }
  }

  Future<void> _pickDocuments(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'txt',
          'ppt', 'pptx', 'odt', 'ods', 'rtf', 'md',
        ],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final attachments = result.files
            .where((f) => f.path != null)
            .map((f) => ChatAttachment.fromFile(File(f.path!)))
            .where((a) => !a.exceedsLimit)
            .toList();
        if (attachments.isNotEmpty) {
          onFilesSelected(attachments);
        }
      }
    } catch (e) {
      debugPrint("Document picker error: $e");
    }
  }

  Future<void> _pickCodeFiles(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'py', 'js', 'ts', 'dart', 'java', 'cpp', 'c', 'h',
          'rs', 'go', 'rb', 'php', 'swift', 'kt', 'scala',
          'html', 'css', 'scss', 'json', 'yaml', 'yml', 'xml',
          'sh', 'sql', 'graphql', 'r',
        ],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final attachments = result.files
            .where((f) => f.path != null)
            .map((f) => ChatAttachment.fromFile(File(f.path!)))
            .where((a) => !a.exceedsLimit)
            .toList();
        if (attachments.isNotEmpty) {
          onFilesSelected(attachments);
        }
      }
    } catch (e) {
      debugPrint("Code file picker error: $e");
    }
  }

  void _showSizeError(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "File exceeds 25 MB limit",
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }
}
