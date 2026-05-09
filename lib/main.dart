import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const AIChatbotApp());
}

class AIChatbotApp extends StatelessWidget {
  const AIChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
