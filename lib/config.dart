import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool useLocalBackend = false;
  
  static String get localHost {
    if (!kIsWeb && Platform.isAndroid) {
      return '10.0.2.2'; // Android Emulator loopback to host PC
    }
    return '127.0.0.1';
  }

  static String get baseUrl => useLocalBackend 
      ? 'http://$localHost:7860' 
      : 'https://vijayadhith7-aura-backend.hf.space';

  static String get wsChatUrl => useLocalBackend 
      ? 'ws://$localHost:7860/chat' 
      : 'wss://vijayadhith7-aura-backend.hf.space/chat';

  /// Dedicated overlay engine — isolated from main chat WebSocket
  static String get wsOverlayUrl => useLocalBackend
      ? 'ws://$localHost:7860/overlay'
      : 'wss://vijayadhith7-aura-backend.hf.space/overlay';

  static String get wsResearchUrl => useLocalBackend 
      ? 'ws://$localHost:7860/research' 
      : 'wss://vijayadhith7-aura-backend.hf.space/research';

  static String get wsAssistUrl => useLocalBackend
      ? 'ws://$localHost:7860/overlay'
      : 'wss://vijayadhith7-aura-backend.hf.space/overlay';
      
  static String get wsWorkspaceUrl => useLocalBackend
      ? 'ws://$localHost:7860/workspace/chat'
      : 'wss://vijayadhith7-aura-backend.hf.space/workspace/chat';
}
