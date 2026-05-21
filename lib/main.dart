import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught platform error: $error\n$stack');
      return true;
    };

    runApp(const ProviderScope(child: AIChatbotApp()));
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

class AIChatbotApp extends ConsumerWidget {
  const AIChatbotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getDynamicTheme(
        themeMode: settings.themeMode,
        accentColor: settings.accentColor,
        fontScale: settings.fontScale,
        density: settings.layoutDensity,
      ),
      home: const SplashScreen(),
    );
  }
}
