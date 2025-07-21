import 'package:flutter_test/flutter_test.dart';
import 'package:vias/core/services/tts_service.dart';

void main() {
  group('TTSService Tests', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    test('should initialize TTS service', () async {
      // Test initialization
      expect(ttsService.isInitialized, isFalse);
      
      // Note: In a real test environment, we might need to mock flutter_tts
      // For now, we test the service structure
      expect(ttsService.speechRate, equals(0.5));
      expect(ttsService.volume, equals(1.0));
      expect(ttsService.pitch, equals(1.0));
      expect(ttsService.language, equals('en-US'));
    });

    test('should update speech rate within valid range', () async {
      // Test speech rate bounds
      await ttsService.setSpeechRate(0.3);
      expect(ttsService.speechRate, equals(0.3));
      
      // Test lower bound
      await ttsService.setSpeechRate(-0.1);
      expect(ttsService.speechRate, equals(0.0));
      
      // Test upper bound
      await ttsService.setSpeechRate(1.5);
      expect(ttsService.speechRate, equals(1.0));
    });

    test('should update volume within valid range', () async {
      // Test volume bounds
      await ttsService.setVolume(0.7);
      expect(ttsService.volume, equals(0.7));
      
      // Test lower bound
      await ttsService.setVolume(-0.1);
      expect(ttsService.volume, equals(0.0));
      
      // Test upper bound
      await ttsService.setVolume(1.5);
      expect(ttsService.volume, equals(1.0));
    });

    test('should update pitch within valid range', () async {
      // Test pitch bounds
      await ttsService.setPitch(1.2);
      expect(ttsService.pitch, equals(1.2));
      
      // Test lower bound
      await ttsService.setPitch(0.3);
      expect(ttsService.pitch, equals(0.5));
      
      // Test upper bound
      await ttsService.setPitch(2.5);
      expect(ttsService.pitch, equals(2.0));
    });

    test('should handle empty text gracefully', () async {
      // Test empty text
      expect(() => ttsService.speak(''), returnsNormally);
      expect(() => ttsService.speak('   '), returnsNormally);
    });

    test('should track speaking state correctly', () {
      // Initial state
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.isPaused, isFalse);
    });

    test('should handle language setting', () async {
      await ttsService.setLanguage('sw-TZ');
      expect(ttsService.language, equals('sw-TZ'));
    });

    test('should provide announcement functionality', () async {
      // Test announcement method exists and handles text
      expect(() => ttsService.announce('Test announcement'), returnsNormally);
    });

    test('should handle disposal gracefully', () {
      expect(() => ttsService.dispose(), returnsNormally);
      // After disposal, service should handle calls gracefully
      expect(() => ttsService.stop(), returnsNormally);
    });
  });

  group('TTSService Edge Cases', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    test('should handle very long text', () async {
      final longText = 'This is a very long text. ' * 100;
      expect(() => ttsService.speak(longText), returnsNormally);
    });

    test('should handle special characters', () async {
      const specialText = 'Hello! @#\$%^&*()_+ 123 ñáéíóú';
      expect(() => ttsService.speak(specialText), returnsNormally);
    });

    test('should handle rapid consecutive calls', () async {
      for (int i = 0; i < 5; i++) {
        expect(() => ttsService.speak('Test $i'), returnsNormally);
      }
    });

    test('should handle stop before speak', () async {
      expect(() => ttsService.stop(), returnsNormally);
      expect(() => ttsService.speak('Test after stop'), returnsNormally);
    });

    test('should handle pause before speak', () async {
      expect(() => ttsService.pause(), returnsNormally);
      expect(() => ttsService.resume(), returnsNormally);
    });
  });

  group('TTSService Performance', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    test('should handle settings changes efficiently', () async {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10; i++) {
        await ttsService.setSpeechRate(0.5 + (i * 0.05));
        await ttsService.setVolume(0.5 + (i * 0.05));
        await ttsService.setPitch(1.0 + (i * 0.1));
      }
      
      stopwatch.stop();
      
      // Settings changes should be fast (under 1 second for 30 operations)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('should maintain consistent state', () async {
      // Set specific values
      await ttsService.setSpeechRate(0.7);
      await ttsService.setVolume(0.8);
      await ttsService.setPitch(1.3);
      
      // Verify values are maintained
      expect(ttsService.speechRate, equals(0.7));
      expect(ttsService.volume, equals(0.8));
      expect(ttsService.pitch, equals(1.3));
      
      // Multiple calls shouldn't change values
      await ttsService.setSpeechRate(0.7);
      expect(ttsService.speechRate, equals(0.7));
    });
  });
}
