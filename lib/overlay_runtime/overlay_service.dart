import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.example.ai_chatbot/overlay_runtime');

  /// Resizes the native WindowManager window layout size in dp
  static Future<void> resize(double width, double height) async {
    try {
      await _channel.invokeMethod('resize', {'width': width, 'height': height});
    } on PlatformException catch (e) {
      print("OverlayService resize failed: ${e.message}");
    }
  }

  /// Sets whether the native window can receive touch focus (enabling keyboard typing)
  static Future<void> setFocusable(bool focusable) async {
    try {
      await _channel.invokeMethod('setFocusable', {'focusable': focusable});
    } on PlatformException catch (e) {
      print("OverlayService setFocusable failed: ${e.message}");
    }
  }

  /// Increments the native window position by dx and dy in dp (used during dragging)
  static Future<void> updatePosition(double dx, double dy) async {
    try {
      await _channel.invokeMethod('updatePosition', {'dx': dx, 'dy': dy});
    } on PlatformException catch (e) {
      print("OverlayService updatePosition failed: ${e.message}");
    }
  }

  /// Sets the absolute position of the native window in dp
  static Future<void> setPosition(double x, double y) async {
    try {
      await _channel.invokeMethod('setPosition', {'x': x, 'y': y});
    } on PlatformException catch (e) {
      print("OverlayService setPosition failed: ${e.message}");
    }
  }

  /// Returns the current active application package, name, and last accessibility text
  static Future<Map<String, String>> getScreenContext() async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('getScreenContext');
      if (res != null) {
        return {
          'text': res['text']?.toString() ?? '',
          'package': res['package']?.toString() ?? '',
          'name': res['name']?.toString() ?? '',
        };
      }
    } on PlatformException catch (e) {
      print("OverlayService getScreenContext failed: ${e.message}");
    }
    return {'text': '', 'package': '', 'name': ''};
  }

  /// Captures screen via MediaProjection and returns a Base64-encoded JPEG image string
  static Future<String?> captureScreenshot() async {
    try {
      final String? b64 = await _channel.invokeMethod('captureScreenshot');
      return b64;
    } on PlatformException catch (e) {
      print("OverlayService captureScreenshot failed: ${e.message}");
      return null;
    }
  }

  /// Shuts down the background service and destroys the overlay view
  static Future<void> close() async {
    try {
      await _channel.invokeMethod('close');
    } on PlatformException catch (e) {
      print("OverlayService close failed: ${e.message}");
    }
  }
}
