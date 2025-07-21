import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Text-to-Speech service for reading content aloud to visually impaired users
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // Completion tracking
  Completer<void>? _speechCompleter;

  // TTS Settings
  double _speechRate = 0.5; // Default speech rate (0.0 to 1.0)
  double _volume = 1.0; // Default volume (0.0 to 1.0)
  double _pitch = 1.0; // Default pitch (0.5 to 2.0)
  String _language = 'en-US'; // Default language

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  /// Translation map for system prompts
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'welcome':
          'Welcome to VIAS, your DIT Prospectus Assistant. I can help you explore programs, view fees, get admissions information, or answer questions. Use voice commands or tap the buttons to get started.',
      'help':
          'Here are the voice commands you can use: Say "explore programs" to learn about available courses. Say "view fees" to hear about tuition costs. Say "admissions info" to get admission requirements. Say "ask questions" for interactive help. You can also say "stop" to stop speaking, or "repeat" to hear something again.',
      'not_understood':
          'I didn\'t understand "{command}". You can say: explore programs, view fees, admissions info, or ask questions.',
      'exploring_programs': 'Exploring Programs',
      'viewing_fees': 'Viewing Fees',
      'admissions_info': 'Admissions Information',
      'ask_questions_mode': 'Ask Questions Mode',
      'ask_questions':
          'You can ask me questions about DIT programs, fees, admissions, or any other information. For example, you can ask: What is the duration of computer science program? Or: What are the entry requirements for engineering?',
      'stopped': 'Stopped',
      'switched_to_swahili':
          'Language switched to Swahili. You can now speak to me in Swahili.',
      'switched_to_english':
          'Language switched to English. You can now speak to me in English.',
      'default_programs': 'Here are the available programs at DIT.',
      'default_fees':
          'Here are the fee structures for DIT programs. Payment can be made in installments throughout the academic year.',
      'default_admissions':
          'For admissions to DIT, you need to meet the following requirements: For Bachelor programs, you need Form 6 certificate with at least 2 principal passes, or a relevant diploma. For diploma programs, you need Form 4 certificate with division 1, 2, or 3. Applications are submitted online through the DIT website.',
    },
    'sw': {
      'welcome':
          'Karibu VIAS, Msaidizi wako wa Prospectus ya DIT. Naweza kukusaidia kuchunguza programu, kuona ada, kupata taarifa za kujiunga, au kujibu maswali. Tumia amri za sauti au bonyeza vitufe kuanza.',
      'help':
          'Hizi ndizo amri za sauti unazoweza kutumia: Sema "angalia programu" kujua kozi zinazopatikana. Sema "angalia ada" kusikia kuhusu gharama za masomo. Sema "sifa za kujiunga" kupata vigezo vya kujiunga. Sema "uliza swali" kwa msaada zaidi. Unaweza pia kusema "nyamaza" kusitisha kusoma, au "rudia" kusikia tena.',
      'not_understood':
          'Sikuelewa "{command}". Unaweza kusema: angalia programu, angalia ada, sifa za kujiunga, au uliza swali.',
      'exploring_programs': 'Unachunguza Programu',
      'viewing_fees': 'Unaangalia Ada',
      'admissions_info': 'Taarifa za Kujiunga',
      'ask_questions_mode': 'Hali ya Kuuliza Maswali',
      'ask_questions':
          'Unaweza kuniuliza maswali kuhusu programu za DIT, ada, kujiunga, au taarifa nyingine yoyote. Kwa mfano, unaweza kuuliza: Muda wa programu ya kompyuta ni upi? Au: Vigezo vya kujiunga na uhandisi ni vipi?',
      'stopped': 'Imesitishwa',
      'switched_to_swahili':
          'Umebadilisha lugha kuwa Kiswahili. Sasa unaweza kuzungumza na mimi kwa Kiswahili.',
      'switched_to_english':
          'Umebadilisha lugha kuwa Kiingereza. Sasa unaweza kuzungumza na mimi kwa Kiingereza.',
      'default_programs': 'Hizi ndizo programu zinazopatikana DIT.',
      'default_fees':
          'Hizi ndizo ada za programu za DIT. Malipo yanaweza kufanyika kwa awamu wakati wa mwaka wa masomo.',
      'default_admissions':
          'Kwa kujiunga na DIT, unahitaji kutimiza vigezo vifuatavyo: Kwa shahada, unahitaji cheti cha kidato cha sita na alama mbili kuu, au diploma husika. Kwa diploma, unahitaji cheti cha kidato cha nne na daraja la 1, 2, au 3. Maombi yanawasilishwa mtandaoni kupitia tovuti ya DIT.',
    },
  };

  /// Utility to get current language code ('en' or 'sw')
  String get languageCode => _language.startsWith('sw') ? 'sw' : 'en';

  /// Initialize the TTS service
  Future<bool> initialize() async {
    try {
      _flutterTts = FlutterTts();

      // Set up TTS handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        if (kDebugMode) print('TTS: Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        if (kDebugMode) print('TTS: Completed speaking');

        // Complete the speech completer if it exists
        if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
          _speechCompleter!.complete();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        if (kDebugMode) print('TTS Error: $msg');

        // Complete the speech completer on error too
        if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
          _speechCompleter!.completeError(Exception('TTS Error: $msg'));
        }
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        if (kDebugMode) print('TTS: Paused');
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        if (kDebugMode) print('TTS: Continued');
      });

      // Wait for TTS engine to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if TTS engines are available (skip on web)
      if (!kIsWeb) {
        try {
          final engines = await _flutterTts.getEngines;
          if (engines.isEmpty) {
            if (kDebugMode) print('No TTS engines available');
            return false;
          }
        } catch (e) {
          if (kDebugMode) {
            print('TTS engines check failed (may be web platform): $e');
          }
          // Continue anyway for web platform
        }
      }

      // Set default settings with error handling
      try {
        await _flutterTts.setSpeechRate(_speechRate);
        await _flutterTts.setVolume(_volume);
        await _flutterTts.setPitch(_pitch);
        await _flutterTts.setLanguage(_language);
      } catch (settingsError) {
        if (kDebugMode) print('TTS settings error: $settingsError');
        // Continue with initialization even if some settings fail
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('TTS Service initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('TTS initialization error: $e');
      return false;
    }
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('TTS not initialized, attempting to reinitialize...');
      }
      // Try to reinitialize if not ready
      final success = await initialize();
      if (!success) {
        if (kDebugMode) print('TTS reinitialization failed');
        return;
      }
    }

    if (text.trim().isEmpty) {
      if (kDebugMode) print('Empty text provided to TTS');
      return;
    }

    try {
      // Stop any current speech
      await stop();

      // Wait a bit to ensure TTS engine is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Create a new completer for this speech
      _speechCompleter = Completer<void>();

      // Speak the text
      await _flutterTts.speak(text);
      if (kDebugMode) {
        print(
          'TTS: Speaking - ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
        );
      }

      // Wait for speech to complete
      try {
        await _speechCompleter!.future.timeout(
          Duration(seconds: text.length ~/ 10 + 10), // Estimate completion time
        );
        if (kDebugMode) print('TTS: Speech completed successfully');
      } catch (timeoutError) {
        if (kDebugMode) print('TTS: Speech timeout or error: $timeoutError');
        // Continue anyway - don't block the app
      }
    } catch (e) {
      if (kDebugMode) print('TTS speak error: $e');
      // Complete the completer on error
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.completeError(e);
      }
      // Try to reinitialize on error
      _isInitialized = false;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;

      // Complete any pending speech completer
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    } catch (e) {
      if (kDebugMode) print('TTS stop error: $e');
      // Reset state even if stop fails
      _isSpeaking = false;
      _isPaused = false;

      // Complete completer on error too
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.completeError(e);
      }
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;

    try {
      await _flutterTts.pause();
    } catch (e) {
      if (kDebugMode) print('TTS pause error: $e');
    }
  }

  /// Resume speaking (Note: resume is not available in flutter_tts, use speak instead)
  Future<void> resume() async {
    if (!_isInitialized || !_isPaused) return;

    try {
      // flutter_tts doesn't have resume, so we'll just continue speaking
      // This is a limitation of the current flutter_tts package
      _isPaused = false;
      if (kDebugMode) {
        print('TTS: Resume requested (not supported by flutter_tts)');
      }
    } catch (e) {
      if (kDebugMode) print('TTS resume error: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      if (kDebugMode) print('TTS: Speech rate set to $_speechRate');
    } catch (e) {
      if (kDebugMode) print('TTS setSpeechRate error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double vol) async {
    if (!_isInitialized) return;

    try {
      _volume = vol.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      if (kDebugMode) print('TTS: Volume set to $_volume');
    } catch (e) {
      if (kDebugMode) print('TTS setVolume error: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double p) async {
    if (!_isInitialized) return;

    try {
      _pitch = p.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
      if (kDebugMode) print('TTS: Pitch set to $_pitch');
    } catch (e) {
      if (kDebugMode) print('TTS setPitch error: $e');
    }
  }

  /// Set language
  Future<void> setLanguage(String lang) async {
    if (!_isInitialized) return;
    try {
      _language = lang;
      await _flutterTts.setLanguage(_language);
      if (kDebugMode) print('TTS: Language set to \'$_language\'');
    } catch (e) {
      if (kDebugMode) print('TTS setLanguage error: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) return [];
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      if (kDebugMode) print('TTS getLanguages error: $e');
      return [];
    }
  }

  /// Switch to Swahili if available, else fallback to English
  Future<void> switchToSwahili() async {
    final langs = await getLanguages();
    if (langs.contains('sw-TZ')) {
      await setLanguage('sw-TZ');
    } else {
      await setLanguage('en-US');
    }
  }

  /// Switch to English
  Future<void> switchToEnglish() async {
    await setLanguage('en-US');
  }

  /// Announce important information (with higher priority)
  Future<void> announce(String message) async {
    if (kDebugMode) print('TTS Announcement: $message');
    await speak(message);
  }

  /// Dispose of the service
  void dispose() {
    stop();
    _isInitialized = false;
  }
}
