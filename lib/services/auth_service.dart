import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://vijayadhith7-aura-backend.hf.space';

  Future<Map<String, dynamic>> loginWithGoogle({String? email, String? googleId, String? idToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      body: json.encode({
        'email': email,
        'googleId': googleId,
        'idToken': idToken,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> setupAuraPassword({
    required String email,
    required String password,
    required String username,
    String? googleId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/setup-password'),
      body: json.encode({
        'email': email,
        'password': password,
        'username': username,
        'googleId': googleId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> loginWithAura(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: json.encode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  Future<void> saveSession(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aura_token', token);
    await prefs.setString('aura_username', username);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<String?> getToken() async {
    return 'aura_guest_token_test_mode';
  }

  Future<String?> getUsername() async {
    return 'AURA GUEST';
  }

  Future<String?> refreshToken() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('aura_token', newToken);
        return newToken;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
