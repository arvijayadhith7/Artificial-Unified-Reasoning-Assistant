import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'create_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleAuraLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithAura(_emailController.text, _passwordController.text);
      if (result['status'] == 'success') {
        await _authService.saveSession(result['token'], result['username']);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Credentials")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Simulating Google Verification Flow
    // In production, use google_sign_in package here
    final simulatedEmail = "user_${DateTime.now().millisecondsSinceEpoch}@gmail.com";
    final simulatedGoogleId = "goog_${DateTime.now().millisecondsSinceEpoch}";

    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithGoogle(email: simulatedEmail, googleId: simulatedGoogleId);
      
      if (result['status'] == 'needs_password') {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePasswordScreen(
            email: simulatedEmail,
            googleId: simulatedGoogleId,
          )));
        }
      } else if (result['status'] == 'success') {
        await _authService.saveSession(result['token'], result['username']);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: _buildAmbientGlow(AppColors.electricBlue, 0.05)),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildLogo(),
                    const SizedBox(height: 60),
                    
                    // Traditional Login
                    _buildTextField("EMAIL", Icons.alternate_email_rounded, _emailController),
                    const SizedBox(height: 20),
                    _buildTextField("PASSWORD", Icons.lock_outline_rounded, _passwordController, isPassword: true),
                    const SizedBox(height: 30),
                    
                    _buildActionButton("GRANT ACCESS", _handleAuraLogin),
                    
                    const SizedBox(height: 30),
                    _buildDivider(),
                    const SizedBox(height: 30),
                    
                    // Google Login
                    _buildGoogleButton(),
                    
                    const SizedBox(height: 40),
                    Text(
                      "Secure Neural Link v2.4",
                      style: GoogleFonts.outfit(color: Colors.white10, fontSize: 10, letterSpacing: 2),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.neonCyan.withOpacity(0.2))),
          child: const Icon(Icons.fingerprint_rounded, color: AppColors.neonCyan, size: 48),
        ),
        const SizedBox(height: 20),
        Text("AURA", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 12)),
        Text("NEURAL OPERATING SYSTEM", style: GoogleFonts.outfit(fontSize: 9, color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 4)),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.white24, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.all(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.electricBlue, AppColors.violetGlow]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.electricBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleLogin,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 8),
            Text("CONTINUE WITH GOOGLE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("OR", style: GoogleFonts.outfit(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildAmbientGlow(Color color, double opacity) {
    return Container(
      width: 400, height: 400,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])),
    );
  }
}
