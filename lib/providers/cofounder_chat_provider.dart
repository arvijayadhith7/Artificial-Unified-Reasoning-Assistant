import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat_service.dart';

/// Dedicated provider for co-founder chat sessions.
/// This is SEPARATE from the main chat provider so that
/// co-founder conversations are project-isolated and don't
/// leak into the global chat history or vice-versa.

class CofounderChatState {
  final List<dynamic> currentMessages;
  final bool isLoading;
  final String? activeConvId;
  final String? activeProjectId;

  CofounderChatState({
    this.currentMessages = const [],
    this.isLoading = false,
    this.activeConvId,
    this.activeProjectId,
  });

  CofounderChatState copyWith({
    List<dynamic>? currentMessages,
    bool? isLoading,
    String? activeConvId,
    String? activeProjectId,
  }) {
    return CofounderChatState(
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
      activeConvId: activeConvId ?? this.activeConvId,
      activeProjectId: activeProjectId ?? this.activeProjectId,
    );
  }
}

class CofounderChatNotifier extends StateNotifier<CofounderChatState> {
  final ChatService _service;

  CofounderChatNotifier(this._service) : super(CofounderChatState());

  Future<void> loadProjectChats(String projectId) async {
    state = state.copyWith(isLoading: true, activeProjectId: projectId);
    final chats = await _service.fetchRecentChats(projectId: projectId);
    if (chats.isNotEmpty) {
      // Auto-open the most recent co-founder conversation
      final latestConvId = chats.first['id'] as String?;
      if (latestConvId != null) {
        final messages = await _service.fetchChatHistory(latestConvId);
        state = state.copyWith(
          currentMessages: messages,
          activeConvId: latestConvId,
          isLoading: false,
        );
        return;
      }
    }
    state = state.copyWith(currentMessages: [], isLoading: false);
  }

  void startNewSession(String projectId) {
    final convId = "cofounder_${projectId}_${DateTime.now().millisecondsSinceEpoch}";
    state = state.copyWith(
      activeConvId: convId,
      activeProjectId: projectId,
      currentMessages: [],
    );
  }

  void addMessage(Map<String, dynamic> msg) {
    msg['timestamp'] = DateTime.now().toIso8601String();
    state = state.copyWith(currentMessages: [...state.currentMessages, msg]);
  }

  void updateLastMessage(String content, {bool isFullReplace = false}) {
    if (state.currentMessages.isEmpty) {
      addMessage({'role': 'assistant', 'content': content});
      return;
    }

    final lastMsg = Map<String, dynamic>.from(state.currentMessages.last);
    if (lastMsg['role'] == 'assistant') {
      if (isFullReplace) {
        lastMsg['content'] = content;
      } else {
        lastMsg['content'] = (lastMsg['content'] ?? '') + content;
      }
      lastMsg['timestamp'] = DateTime.now().toIso8601String();
      final newList = List<dynamic>.from(state.currentMessages);
      newList[newList.length - 1] = lastMsg;
      state = state.copyWith(currentMessages: newList);
    } else {
      addMessage({'role': 'assistant', 'content': content});
    }
  }

  void updateLastMessageThought(String thought) {
    if (state.currentMessages.isEmpty) {
      addMessage({'role': 'assistant', 'content': '', 'thought': thought});
      return;
    }

    final lastMsg = Map<String, dynamic>.from(state.currentMessages.last);
    if (lastMsg['role'] == 'assistant') {
      lastMsg['thought'] = thought;
      lastMsg['timestamp'] = DateTime.now().toIso8601String();
      final newList = List<dynamic>.from(state.currentMessages);
      newList[newList.length - 1] = lastMsg;
      state = state.copyWith(currentMessages: newList);
    } else {
      addMessage({'role': 'assistant', 'content': '', 'thought': thought});
    }
  }

  void clearSession() {
    state = CofounderChatState();
  }
}

final cofounderChatProvider = StateNotifierProvider<CofounderChatNotifier, CofounderChatState>((ref) {
  final service = ChatService();
  return CofounderChatNotifier(service);
});
