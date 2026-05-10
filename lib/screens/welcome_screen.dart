import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Mock Google Sign-In for demo purposes
      // In a real app, you'd use: final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ Authenticating with Google Cloud...')),
      );
      await Future.delayed(const Duration(seconds: 2));
      await _completeOnboarding(context);
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1A1A2E),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Neural Core Image
                  Center(
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonBlue.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/neural_core.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.neonBlue, Colors.white],
                    ).createShader(bounds),
                    child: Text(
                      "Elevate Your\nIntelligence.",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Experience AURA — the next generation of autonomous reasoning and cognitive assistance.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Google Auth Button
                  GestureDetector(
                    onTap: () => _handleGoogleSignIn(context),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/1200px-Google_\"G\"_logo.svg.png',
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Continue with Google",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Secondary Initialize Button
                  Center(
                    child: TextButton(
                      onPressed: () => _completeOnboarding(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Initialize System",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.neonBlue, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
