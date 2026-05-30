import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayMemory {
  static const String _keyHistory = 'aura_overlay_history_dart';
  static const int maxTurns = 10;

  /// Loads history turns as a List of Maps
  static Future<List<Map<String, String>>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_keyHistory);
      if (raw == null || raw.isEmpty) return [];
      
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        return {
          'role': item['role']?.toString() ?? '',
          'content': item['content']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      print("OverlayMemory failed to load: $e");
      return [];
    }
  }

  /// Saves the complete list of turns
  static Future<void> save(List<Map<String, String>> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHistory, jsonEncode(history));
    } catch (e) {
      print("OverlayMemory failed to save: $e");
    }
  }

  /// Appends a new user & assistant message turn and keeps it within the limit
  static Future<void> appendTurn(String userText, String assistantText) async {
    final List<Map<String, String>> history = await load();
    history.add({'role': 'user', 'content': userText});
    history.add({'role': 'assistant', 'content': assistantText});
    
    // limit history size
    while (history.length > maxTurns * 2) {
      history.removeAt(0);
    }
    await save(history);
  }

  /// Wipes history
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
    } catch (e) {
      print("OverlayMemory failed to clear: $e");
    }
  }
}
