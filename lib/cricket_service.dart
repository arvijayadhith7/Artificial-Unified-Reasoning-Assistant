import 'dart:convert';
import 'package:http/http.dart' as http;

class CricketService {
  static const String _apiKey = "53952fac-3cfa-4ade-b678-440bd5b12d50";
  static const String _baseUrl = "https://api.cricapi.com/v1";

  Future<List<dynamic>> getCurrentMatches() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/currentMatches?apikey=$_apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> allMatches = data['data'] ?? [];
          // Strict Filter: Only IPL and Indian National Team
          return allMatches.where((m) {
            final name = m['name'].toString().toLowerCase();
            return name.contains('ipl') || name.contains('indian premier league') || name.contains('india');
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMatchScore(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/cricScore?apikey=$_apiKey&id=$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print("💥 Cricket Score Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAuraIPLIntel() async {
    try {
      print("📡 Synchronizing AURA IPL Intel...");
      final response = await http.get(Uri.parse('https://vijayadhith7-aura-backend.hf.space/cricket/ipl'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print("💥 IPL Intel Sync Error: $e");
      return null;
    }
  }
}
