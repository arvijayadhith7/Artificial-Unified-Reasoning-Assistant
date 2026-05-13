import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class ChatService {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get responseStream => _controller.stream;

  bool _isConnected = false;

  void connect() {
    const url = 'wss://vijayadhith7-aura-backend.hf.space/chat';
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      print('🚀 NEURAL LINK: Initializing WebSocket Connection...');

      _channel!.stream.listen(
        (data) {
          final decoded = json.decode(data);
          _controller.add(Map<String, dynamic>.from(decoded));
        },
        onError: (error) {
          print('❌ Neural Link Error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('🔌 Neural Link Terminated');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('💥 Connection Failed: $e');
      _isConnected = false;
    }
  }

  void sendMessage(String text, {String? chatId, List<Map<String, dynamic>> history = const []}) {
    if (!_isConnected || _channel == null) {
      print('🔄 Reconnecting Neural Link...');
      connect();
    }
    
    final payload = json.encode({
      'prompt': text,
      'history': history,
      'chatId': chatId,
    });

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      print('💥 Failed to send message: $e');
    }
  }

  void dispose() {
    _isConnected = false;
    _controller.close();
    _channel?.sink.close();
  }
}
