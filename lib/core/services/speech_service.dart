import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

/// Speech-to-Text service for voice commands from visually impaired users
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  late SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  double _confidence = 0.0;
  String _localeId = 'en_US'; // Default locale

  // Callbacks
  Function(String)? _onResult;
  Function(String)? _onError;
  Function()? _onListeningStart;
  Function()? _onListeningStop;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  String get localeId => _localeId;

  /// Set locale
  Future<void> setLocale(String locale) async {
    _localeId = locale;
  }

  /// Initialize the Speech service
  Future<bool> initialize() async {
    try {
      _speechToText = SpeechToText();
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) print('Speech Error: ${error.errorMsg}');
          _onError?.call(error.errorMsg);
          _isListening = false;
        },
        onStatus: (status) {
          if (kDebugMode) print('Speech Status: $status');
          if (status == 'listening') {
            _isListening = true;
            _onListeningStart?.call();
          } else if (status == 'notListening') {
            _isListening = false;
            _onListeningStop?.call();
          }
        },
      );

      _isInitialized = _isAvailable;

      if (_isInitialized) {
        if (kDebugMode) print('Speech Service initialized successfully');
      } else {
        if (kDebugMode)
          print('Speech recognition not available on this device');
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) print('Speech initialization error: $e');
      return false;
    }
  }

  /// Start listening for voice commands
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onError,
    Function()? onListeningStart,
    Function()? onListeningStop,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized || !_isAvailable) {
      if (kDebugMode) print('Speech service not available');
      onError?.call('Speech recognition not available');
      return;
    }

    if (_isListening) {
      if (kDebugMode) print('Already listening');
      return;
    }

    // Set callbacks
    _onResult = onResult;
    _onError = onError;
    _onListeningStart = onListeningStart;
    _onListeningStop = onListeningStop;

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidence = result.confidence;

          if (kDebugMode) {
            print(
              'Speech Result: $_lastWords (confidence: ${(_confidence * 100).toStringAsFixed(1)}%)',
            );
          }

          if (result.finalResult) {
            // Only call the result callback - don't double process
            _onResult?.call(_lastWords);
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30), // Listen for up to 30 seconds
        pauseFor: const Duration(
          seconds: 3,
        ), // Pause after 3 seconds of silence
        listenOptions: SpeechListenOptions(
          partialResults: true, // Get partial results while speaking
          cancelOnError: true,
          listenMode:
              ListenMode.confirmation, // Wait for user to finish speaking
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Start listening error: $e');
      _onError?.call('Failed to start listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isInitialized || !_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      if (kDebugMode) print('Stopped listening');
    } catch (e) {
      if (kDebugMode) print('Stop listening error: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isInitialized) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      if (kDebugMode) print('Cancelled listening');
    } catch (e) {
      if (kDebugMode) print('Cancel listening error: $e');
    }
  }

  // Removed _processVoiceCommand method to prevent double processing
  // Voice command processing is now handled by the home screen directly

  // Removed _isQuestion method - question detection now handled by home screen

  /// Switch to Swahili if available, else fallback to English
  Future<void> switchToSwahili() async {
    final locales = await getLocales();
    if (locales.contains('sw_TZ')) {
      await setLocale('sw_TZ');
    } else {
      await setLocale('en_US');
    }
  }

  /// Switch to English
  Future<void> switchToEnglish() async {
    await setLocale('en_US');
  }

  /// Get available locales
  Future<List<String>> getLocales() async {
    if (!_isInitialized) return [];

    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      if (kDebugMode) print('Get locales error: $e');
      return [];
    }
  }

  /// Check if speech recognition has permission
  Future<bool> hasPermission() async {
    if (!_isInitialized) return false;
    return _speechToText.hasPermission;
  }

  /// Request speech recognition permission
  Future<bool> requestPermission() async {
    try {
      return await SpeechToText().initialize();
    } catch (e) {
      if (kDebugMode) print('Request permission error: $e');
      return false;
    }
  }

  /// Dispose of the service
  void dispose() {
    stopListening();
    _isInitialized = false;
  }
}
