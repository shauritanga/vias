import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vias/core/services/tts_service.dart';
import 'package:vias/shared/widgets/tts_controls.dart';

void main() {
  group('TTSControls Widget Tests', () {
    late TTSService mockTtsService;

    setUp(() {
      mockTtsService = TTSService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<TTSService>.value(
          value: mockTtsService,
          child: const Scaffold(body: TTSControls()),
        ),
      );
    }

    testWidgets('should display TTS control buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for control buttons
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Check for icons
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('should expand settings when settings button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially settings should be collapsed
      expect(find.text('Speech Settings'), findsNothing);

      // Tap settings button
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Settings should now be expanded
      expect(find.text('Speech Settings'), findsOneWidget);
      expect(find.text('Speech Rate'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Pitch'), findsOneWidget);
    });

    testWidgets('should display sliders when settings are expanded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Check for sliders
      expect(
        find.byType(Slider),
        findsNWidgets(3),
      ); // Speech rate, volume, pitch
      expect(find.text('Test Speech Settings'), findsOneWidget);
    });

    testWidgets('should show correct initial values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Check for default values (these are displayed as percentages/multipliers)
      expect(find.textContaining('50%'), findsOneWidget); // Default speech rate
      expect(find.textContaining('100%'), findsOneWidget); // Default volume
      expect(find.textContaining('1.0x'), findsOneWidget); // Default pitch
    });

    testWidgets('should handle slider interactions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Find the first slider (speech rate)
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(3));

      // Test slider interaction (this tests that the widget responds to gestures)
      await tester.drag(sliders.first, const Offset(50, 0));
      await tester.pumpAndSettle();

      // The widget should still be present and functional
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('should display test speech button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Check for test button
      expect(find.text('Test Speech Settings'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should handle test speech button tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Tap test speech button
      await tester.tap(find.text('Test Speech Settings'));
      await tester.pumpAndSettle();

      // Widget should still be present (no crashes)
      expect(find.text('Test Speech Settings'), findsOneWidget);
    });

    testWidgets(
      'should collapse settings when settings button is tapped again',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('Speech Settings'), findsOneWidget);

        // Collapse settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('Speech Settings'), findsNothing);
      },
    );

    testWidgets('should handle multiple rapid taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Rapidly tap settings button
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Settings'));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Widget should still be functional
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should maintain state during widget rebuilds', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Speech Settings'), findsOneWidget);

      // Trigger a rebuild by pumping the widget again
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Settings should still be expanded (state maintained)
      expect(find.text('Speech Settings'), findsOneWidget);
    });
  });

  group('TTSControls Accessibility Tests', () {
    late TTSService mockTtsService;

    setUp(() {
      mockTtsService = TTSService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<TTSService>.value(
          value: mockTtsService,
          child: const Scaffold(body: TTSControls()),
        ),
      );
    }

    testWidgets('should have proper semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that buttons have proper semantics for screen readers
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should have accessible touch targets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find button widgets and check their size
      final stopButton = find.ancestor(
        of: find.text('Stop'),
        matching: find.byType(ElevatedButton),
      );
      expect(stopButton, findsOneWidget);

      // Get the button size
      final RenderBox buttonBox = tester.renderObject(stopButton);
      expect(
        buttonBox.size.width,
        greaterThanOrEqualTo(44),
      ); // Minimum touch target
      expect(buttonBox.size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('should support keyboard navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test that buttons can receive focus
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // At least one button should be focusable
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('TTSControls Performance Tests', () {
    late TTSService mockTtsService;

    setUp(() {
      mockTtsService = TTSService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Provider<TTSService>.value(
          value: mockTtsService,
          child: const Scaffold(body: TTSControls()),
        ),
      );
    }

    testWidgets('should render quickly', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Widget should render quickly (under 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('should handle rapid state changes efficiently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Rapidly toggle settings
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Settings'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Should handle rapid changes efficiently (under 500ms for 10 toggles)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
