import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config.dart';

class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.example.ai_chatbot/overlay');

  static Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check overlay permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print("Failed to request overlay permission: ${e.message}");
    }
  }

  static Future<bool> checkAccessibilityPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkAccessibilityPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check accessibility permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      print("Failed to request accessibility permission: ${e.message}");
    }
  }

  static Future<void> syncOverlayEnabledPref(bool enabled) async {
    try {
      await _channel.invokeMethod('setOverlayEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      debugPrint("Failed to sync overlay pref: ${e.message}");
    }
  }

  static Future<void> startOverlay() async {
    try {
      final String url = AppConfig.baseUrl;
      await syncOverlayEnabledPref(true);
      await _channel.invokeMethod('startOverlayService', {'backend_url': url});
    } on PlatformException catch (e) {
      debugPrint("Failed to start overlay service: ${e.message}");
      rethrow;
    }
  }

  static Future<void> stopOverlay() async {
    try {
      await _channel.invokeMethod('stopOverlayService');
      await syncOverlayEnabledPref(false);
    } on PlatformException catch (e) {
      debugPrint("Failed to stop overlay service: ${e.message}");
    }
  }

  static Future<bool> checkBatteryOptimizationIgnored() async {
    try {
      final bool ignored = await _channel.invokeMethod('checkBatteryOptimizationIgnored');
      return ignored;
    } on PlatformException catch (e) {
      print("Failed to check battery optimization: ${e.message}");
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } on PlatformException catch (e) {
      print("Failed to request battery optimization: ${e.message}");
    }
  }

  static Future<bool> checkScreenCapturePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkScreenCapturePermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check screen capture permission: ${e.message}");
      return false;
    }
  }

  static Future<bool> requestScreenCapturePermission() async {
    try {
      final bool success = await _channel.invokeMethod('requestScreenCapturePermission');
      return success;
    } on PlatformException catch (e) {
      print("Failed to request screen capture permission: ${e.message}");
      return false;
    }
  }
}

