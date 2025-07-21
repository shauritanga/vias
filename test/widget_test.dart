// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vias/core/services/tts_service.dart';
import 'package:vias/core/services/speech_service.dart';

import 'package:vias/main.dart';

void main() {
  testWidgets('VIAS app smoke test', (WidgetTester tester) async {
    // Initialize services for testing
    final ttsService = TTSService();
    final speechService = SpeechService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ViasApp(ttsService: ttsService, speechService: speechService),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app loads with the correct title
    expect(find.text('VIAS - DIT Assistant'), findsOneWidget);

    // Verify that command buttons are present
    expect(find.text('Explore Programs'), findsOneWidget);
    expect(find.text('View Fees'), findsOneWidget);
    expect(find.text('Admissions Info'), findsOneWidget);
    expect(find.text('Ask Questions'), findsOneWidget);
  });
}
