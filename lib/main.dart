import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch any errors during initialization
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(const ProviderScope(child: AIChatbotApp()));
}

class AIChatbotApp extends StatelessWidget {
  const AIChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

