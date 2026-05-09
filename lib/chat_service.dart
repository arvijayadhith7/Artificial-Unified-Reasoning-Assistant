import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

class ChatService {
  late io.Socket socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get responseStream => _controller.stream;

  void connect() {
    socket = io.io('http://192.168.1.4:3000', io.OptionBuilder()
      .setTransports(['websocket'])
      .build());

    socket.onConnect((_) => print('Connected to backend'));
    
    socket.on('chunk', (data) {
      // data is now { 'type': '...', 'content': '...' }
      _controller.add(Map<String, dynamic>.from(data));
    });

    socket.on('error', (data) {
      print('Socket Error: $data');
    });
  }

  void sendMessage(String text, {String modelType = 'gemini'}) {
    socket.emit('message', {'text': text, 'modelType': modelType});
  }

  void dispose() {
    _controller.close();
    socket.disconnect();
  }
}
