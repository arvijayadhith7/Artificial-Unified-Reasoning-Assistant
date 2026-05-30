import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart' as mime_pkg;

/// Types of attachments supported by AURA's universal input
enum AttachmentType { image, document, code, unknown }

/// Represents a single file attachment in the chat input
class ChatAttachment {
  final String name;
  final String path;
  final String mimeType;
  final int sizeBytes;
  final AttachmentType type;

  const ChatAttachment({
    required this.name,
    required this.path,
    required this.mimeType,
    required this.sizeBytes,
    required this.type,
  });

  /// Create from a File object with automatic type detection
  factory ChatAttachment.fromFile(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final mimeType = mime_pkg.lookupMimeType(file.path) ?? 'application/octet-stream';
    final sizeBytes = file.existsSync() ? file.lengthSync() : 0;
    final type = _detectType(fileName, mimeType);

    return ChatAttachment(
      name: fileName,
      path: file.path,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      type: type,
    );
  }

  /// Detect attachment type from filename extension and MIME type
  static AttachmentType _detectType(String name, String mimeType) {
    if (mimeType.startsWith('image/')) return AttachmentType.image;

    final ext = name.split('.').last.toLowerCase();
    const codeExts = {
      'py', 'js', 'ts', 'dart', 'java', 'cpp', 'c', 'h', 'hpp',
      'rs', 'go', 'rb', 'php', 'swift', 'kt', 'scala', 'r',
      'html', 'css', 'scss', 'json', 'yaml', 'yml', 'xml',
      'sh', 'bash', 'zsh', 'ps1', 'bat', 'sql', 'graphql',
    };
    const docExts = {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'txt',
      'ppt', 'pptx', 'odt', 'ods', 'rtf', 'md',
    };

    if (codeExts.contains(ext)) return AttachmentType.code;
    if (docExts.contains(ext)) return AttachmentType.document;
    if (mimeType.startsWith('text/')) return AttachmentType.document;

    return AttachmentType.unknown;
  }

  /// Human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Icon for this attachment type
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.document:
        return Icons.description_rounded;
      case AttachmentType.code:
        return Icons.code_rounded;
      case AttachmentType.unknown:
        return Icons.attach_file_rounded;
    }
  }

  /// Accent color for this attachment type
  Color get accentColor {
    switch (type) {
      case AttachmentType.image:
        return const Color(0xFF00E5FF);
      case AttachmentType.document:
        return const Color(0xFFFF6D00);
      case AttachmentType.code:
        return const Color(0xFF76FF03);
      case AttachmentType.unknown:
        return const Color(0xFFB0BEC5);
    }
  }

  /// Whether this file exceeds the 25 MB upload limit
  bool get exceedsLimit => sizeBytes > 25 * 1024 * 1024;

  /// File extension
  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
}
