import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glowing_orb.dart';
import '../app_theme.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    Timer(const Duration(seconds: 4), () {
      Widget nextScreen;
      if (isFirstTime) {
        nextScreen = const WelcomeScreen();
      } else {
        nextScreen = const HomeScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GlowingOrb(size: 180),
                  const SizedBox(height: 40),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.neonBlue, AppColors.neonPurple],
                    ).createShader(bounds),
                    child: Text(
                      "AURA",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        letterSpacing: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "NEURAL INTELLIGENCE ENGINE",
                    style: TextStyle(
                      color: AppColors.neonBlue.withOpacity(0.6),
                      fontSize: 10,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
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
