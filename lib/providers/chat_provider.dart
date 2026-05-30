import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatState {
  final List<dynamic> recentChats;
  final List<dynamic> currentMessages;
  final bool isLoading;
  final String? activeConvId;

  ChatState({
    this.recentChats = const [],
    this.currentMessages = const [],
    this.isLoading = false,
    this.activeConvId,
  });

  ChatState copyWith({
    List<dynamic>? recentChats,
    List<dynamic>? currentMessages,
    bool? isLoading,
    String? activeConvId,
  }) {
    return ChatState(
      recentChats: recentChats ?? this.recentChats,
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
      activeConvId: activeConvId ?? this.activeConvId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _service;

  ChatNotifier(this._service) : super(ChatState());

  Future<void> loadRecentChats({String? projectId}) async {
    state = state.copyWith(isLoading: true);
    final chats = await _service.fetchRecentChats(projectId: projectId);
    state = state.copyWith(recentChats: chats, isLoading: false);
  }

  Future<void> openChat(String convId) async {
    state = state.copyWith(isLoading: true, activeConvId: convId, currentMessages: []);
    final messages = await _service.fetchChatHistory(convId);
    state = state.copyWith(currentMessages: messages, isLoading: false);
  }

  void startNewChat() {
    state = state.copyWith(activeConvId: null, currentMessages: []);
  }

  Future<bool> deleteChat(String convId, {String? projectId}) async {
    final success = await _service.deleteChat(convId);
    if (success) {
      // If we deleted the active chat, clear the viewport
      if (state.activeConvId == convId) {
        state = state.copyWith(activeConvId: null, currentMessages: []);
      }
      // Refresh the sidebar list
      await loadRecentChats(projectId: projectId);
    }
    return success;
  }

  void addMessage(Map<String, dynamic> msg) {
    msg['timestamp'] = DateTime.now().toIso8601String();
    state = state.copyWith(currentMessages: [...state.currentMessages, msg]);
  }

  void truncateMessages(int length) {
    if (length >= 0 && length <= state.currentMessages.length) {
      state = state.copyWith(
        currentMessages: state.currentMessages.sublist(0, length),
      );
    }
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
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(chatServiceProvider);
  return ChatNotifier(service);
});

final overlayVisibleProvider = StateProvider<bool>((ref) => false);
final neuralHaloStateProvider = StateProvider<String>((ref) => 'idle');
