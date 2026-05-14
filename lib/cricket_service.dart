import 'dart:convert';
import 'package:http/http.dart' as http;

class CricketService {
  static const String _apiKey = "53952fac-3cfa-4ade-b678-440bd5b12d50";
  static const String _baseUrl = "https://api.cricapi.com/v1";

  Future<List<dynamic>> getCurrentMatches() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/currentMatches?apikey=$_apiKey'));
      print("📡 Cricket API Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📊 Cricket API Response: ${data['status']}");
        if (data['status'] == 'success') {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print("💥 Cricket API Error: $e");
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

  Future<String?> getAuraIPLScore() async {
    try {
      print("📡 Fetching AURA IPL Intel...");
      final response = await http.get(Uri.parse('https://vijayadhith7-aura-backend.hf.space/cricket/ipl'));
      print("📊 AURA IPL Response: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          print("✅ IPL Intel Sync Successful");
          return data['data'];
        }
      }
      return "AURA Sync: Neural link established. Waiting for match data clusters...";
    } catch (e) {
      print("💥 IPL Intel Error: $e");
      return "AURA Sync: Research pipeline interrupted. Retrying neural link...";
    }

  }
}
