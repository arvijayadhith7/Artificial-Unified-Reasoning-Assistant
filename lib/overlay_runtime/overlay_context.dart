import 'overlay_service.dart';

class OverlayContext {
  /// Scans active app metadata and accessibility text.
  static Future<Map<String, dynamic>> gatherScreenMetadata() async {
    final Map<String, String> nativeContext = await OverlayService.getScreenContext();
    return {
      'active_app': nativeContext['package'] ?? '',
      'window_title': nativeContext['name'] ?? '',
      'accessibility_text': nativeContext['text'] ?? '',
      'platform': 'android',
    };
  }

  /// Captures active screen screenshot base64 string.
  static Future<String?> gatherScreenshot() async {
    return await OverlayService.captureScreenshot();
  }

  /// Gathers all available screen context parameters into a payload.
  static Future<Map<String, dynamic>> buildSandboxPayload({
    required String assistantMode,
    bool includeScreenshot = false,
  }) async {
    final Map<String, dynamic> metadata = await gatherScreenMetadata();
    
    String? screenshotB64;
    if (includeScreenshot) {
      screenshotB64 = await gatherScreenshot();
    }

    return {
      'platform': 'android',
      'overlay_mode': true,
      'assistant_mode': assistantMode,
      'ocr': true,
      'accessibility_text': metadata['accessibility_text'],
      'active_app': metadata['active_app'],
      'window_title': metadata['window_title'],
      'persona': 'warm-narrative',
      'search_strategy': assistantMode == 'research' ? 'multi-tier' : 'local-only',
      if (screenshotB64 != null) 'screenshot': screenshotB64,
    };
  }
}
