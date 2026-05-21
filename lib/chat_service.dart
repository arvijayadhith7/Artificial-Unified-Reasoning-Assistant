import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ChatService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  static String get baseUrl => AppConfig.baseUrl;
  static String get wsUrl => AppConfig.wsChatUrl;
  
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
    try {
      final url = projectId != null ? '$baseUrl/chats?project_id=$projectId' : '$baseUrl/chats';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Error fetching recent chats: $e");
    }
    return [];
  }

  Future<List<dynamic>> fetchChatHistory(String convId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/chats/$convId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Error fetching chat history: $e");
    }
    return [];
  }

  Future<String?> refineMessage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/neural/refine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['refined'];
      }
    } catch (e) {
      print("Refine Error: $e");
    }
    return null;
  }

  void sendMessage(String text, {String? conversationId, String? projectId, List<Map<String, dynamic>> history = const []}) {
    if (!_isConnected || _channel == null) connect();
    
    final payload = json.encode({
      'prompt': text,
      'history': history,
      'conversationId': conversationId ?? 'conv_${DateTime.now().millisecondsSinceEpoch}',
      'projectId': projectId ?? 'global',
      'sandbox': {
        'overlay_mode': false,
        'platform': 'android_app',
      },
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
