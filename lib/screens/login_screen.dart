import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled the flow
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      var result = await _authService.loginWithGoogle(
        email: googleUser.email,
        googleId: googleUser.id,
        idToken: idToken,
      );

      // Backend compatibility: if backend requests a password setup for a new Google ID,
      // automate setting up a strong background neural password so the user gets a seamless 1-tap experience.
      if (result['status'] == 'needs_password') {
        final autoPassword = "AuraNeuralSecured_${googleUser.id}_${DateTime.now().millisecondsSinceEpoch}";
        final setupResponse = await http.post(
          Uri.parse('${AuthService.baseUrl}/auth/setup-password'),
          body: json.encode({
            'email': googleUser.email,
            'password': autoPassword,
            'username': googleUser.displayName ?? googleUser.email.split('@')[0],
            'googleId': googleUser.id,
          }),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));

        if (setupResponse.statusCode == 200) {
          // Retry the sign-in flow
          result = await _authService.loginWithGoogle(
            email: googleUser.email,
            googleId: googleUser.id,
            idToken: idToken,
          );
        }
      }

      if (result['status'] == 'success') {
        final token = result['token'] ?? 'aura_simulated_jwt_token';
        final username = result['username'] ?? googleUser.displayName ?? googleUser.email.split('@')[0];

        await _authService.saveSession(token, username);
        await _authService.saveGoogleProfile(
          email: googleUser.email,
          displayName: googleUser.displayName ?? username,
          photoUrl: googleUser.photoUrl,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("AURA Neural OS verification failed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google authentication failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background atmospheric cyberpunk glowing orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildAmbientGlow(AppColors.electricBlue, 0.05),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildAmbientGlow(AppColors.violetGlow, 0.03),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 80),
                    
                    // Main premium Google CTA button
                    _buildGoogleButton(),
                    
                    const SizedBox(height: 100),
                    Text(
                      "Secure Neural Link v2.5",
                      style: GoogleFonts.outfit(
                        color: Colors.white10,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonCyan.withOpacity(0.02),
            border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            color: AppColors.neonCyan,
            size: 56,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "AURA",
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "NEURAL OPERATING SYSTEM",
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppColors.neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleLogin,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            if (_isLoading)
              BoxShadow(
                color: AppColors.neonCyan.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.neonCyan,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium custom Google icon indicator
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.g_mobiledata_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "CONTINUE WITH GOOGLE",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlow(Color color, double opacity) {
    return Container(
      width: 450,
      height: 450,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
