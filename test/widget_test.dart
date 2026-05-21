// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_chatbot/main.dart';

void main() {
  testWidgets('AURA App Splash Screen Smoke Test', (WidgetTester tester) async {
    // Pump the app wrapped in a ProviderScope (required by Riverpod)
    await tester.pumpWidget(
      const ProviderScope(
        child: AIChatbotApp(),
      ),
    );

    // Verify that the splash screen shows "AURA"
    expect(find.text('AURA'), findsOneWidget);

    // Advance time by 2 seconds to let the splash screen Timer execute
    await tester.pump(const Duration(seconds: 2));
    // Settle the navigation frame without running infinite animations indefinitely
    await tester.pump();
  });
}
