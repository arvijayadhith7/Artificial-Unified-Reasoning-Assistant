import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class OverlaySocket {
  WebSocketChannel? _channel;
  bool isConnected = false;
  bool isConnecting = false;
  Timer? _reconnectTimer;
  
  final _statusController = StreamController<String>.broadcast();
  final _chunkController = StreamController<String>.broadcast();
  final _doneController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _contextController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get chunkStream => _chunkController.stream;
  Stream<void> get doneStream => _doneController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get contextStream => _contextController.stream;

  void connect() {
    if (isConnected || isConnecting) return;
    isConnecting = true;
    _statusController.add("Connecting to AURA Assist...");

    final url = AppConfig.wsOverlayUrl;
    print("OverlaySocket: Connecting to $url");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (data) {
          isConnected = true;
          isConnecting = false;
          _handleMessage(data);
        },
        onError: (err) {
          print("OverlaySocket error: $err");
          _handleDisconnect("Connection error: $err");
        },
        onDone: () {
          print("OverlaySocket closed");
          _handleDisconnect("Disconnected from AURA Assist.");
        },
      );
      
      isConnected = true;
      isConnecting = false;
      _statusController.add("AURA Assist Online");
    } catch (e) {
      isConnecting = false;
      _handleDisconnect("Failed to connect: $e");
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw.toString());
      if (msg.containsKey('done') && msg['done'] == true) {
        _doneController.add(null);
        return;
      }

      final type = msg['type'];
      final content = msg['content'];

      switch (type) {
        case 'status':
          _statusController.add(content?.toString() ?? '');
          break;
        case 'chunk':
          _chunkController.add(content?.toString() ?? '');
          break;
        case 'error':
          _errorController.add(content?.toString() ?? 'Unknown error occurred.');
          break;
        case 'context_detected':
          final detected = List<String>.from(msg['detected_items'] ?? []);
          final suggestions = List<dynamic>.from(msg['suggestions'] ?? []).map((s) {
            if (s is Map) {
              return Map<String, String>.from(s.map((k, v) => MapEntry(k.toString(), v.toString())));
            } else {
              return {'label': s.toString(), 'prompt': s.toString()};
            }
          }).toList();
          _contextController.add({
            'detected_items': detected,
            'suggestions': suggestions,
          });
          break;
      }
    } catch (e) {
      print("OverlaySocket failed to parse message: $e");
    }
  }

  void send(Map<String, dynamic> payload) {
    if (_channel == null || !isConnected) {
      _errorController.add("Not connected. Reconnecting...");
      connect();
      return;
    }
    _channel!.sink.add(jsonEncode(payload));
  }

  void _handleDisconnect(String message) {
    isConnected = false;
    isConnecting = false;
    _statusController.add("Offline");
    _errorController.add(message);

    // Auto-reconnect after 3 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      print("OverlaySocket attempting auto-reconnect...");
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    isConnected = false;
    isConnecting = false;
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _chunkController.close();
    _doneController.close();
    _errorController.close();
    _contextController.close();
  }
}
