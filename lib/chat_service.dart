import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

class ChatService {
  late io.Socket socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get responseStream => _controller.stream;

  void connect() {
    socket = io.io('https://vijayadhith7-aura-backend.hf.space', io.OptionBuilder()
      .setTransports(['websocket'])
      .enableForceNew()
      .build());

    socket.onConnect((_) => print('🚀 SUCCESS: Connected to AURA Backend'));
    socket.onConnectError((data) => print('❌ Connection Error: $data'));
    socket.onDisconnect((data) => print('🔌 Disconnected: $data'));
    
    socket.on('chunk', (data) {
      print('📥 Received chunk: $data');
      _controller.add(Map<String, dynamic>.from(data));
    });

    socket.on('error', (data) {
      print('💥 Socket Logic Error: $data');
    });
  }

  void sendMessage(String text, {String modelType = 'aura'}) {
    socket.emit('message', {'text': text, 'modelType': modelType});
  }

  void dispose() {
    _controller.close();
    socket.disconnect();
  }
}
