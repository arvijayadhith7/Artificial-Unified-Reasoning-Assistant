import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  static const String baseUrl = 'https://vijayadhith7-aura-backend.hf.space';
  static const String wsUrl = 'wss://vijayadhith7-aura-backend.hf.space/chat';
  
  Stream<Map<String, dynamic>> get responseStream => _controller.stream;

  bool _isConnected = false;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _channel!.stream.listen(
        (data) {
          final decoded = json.decode(data);
          _controller.add(Map<String, dynamic>.from(decoded));
        },
        onError: (_) => _isConnected = false,
        onDone: () => _isConnected = false,
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  Future<List<dynamic>> fetchRecentChats({String? projectId}) async {
    final url = projectId != null ? '$baseUrl/chats?project_id=$projectId' : '$baseUrl/chats';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  Future<List<dynamic>> fetchChatHistory(String convId) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$convId'));
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  void sendMessage(String text, {String? conversationId, String? projectId, List<Map<String, dynamic>> history = const []}) {
    if (!_isConnected || _channel == null) connect();
    
    final payload = json.encode({
      'prompt': text,
      'history': history,
      'conversationId': conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      'projectId': projectId ?? 'global',
    });

    try {
      _channel!.sink.add(payload);
    } catch (_) {}
  }

  void dispose() {
    _isConnected = false;
    _controller.close();
    _channel?.sink.close();
  }
}
