import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/content_management_service.dart';

/// Language Provider for managing app language state
/// Supports English and Swahili with voice command integration
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  String _currentLanguage = 'english'; // 'english' or 'swahili'
  bool _isChangingLanguage = false;

  // Services
  TTSService? _ttsService;
  SpeechService? _speechService;

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isSwahili => _currentLanguage == 'swahili';
  bool get isEnglish => _currentLanguage == 'english';
  bool get isChangingLanguage => _isChangingLanguage;

  // TTS and Speech locale codes
  String get ttsLocale => isSwahili ? 'sw-TZ' : 'en-US';
  String get speechLocale => isSwahili ? 'sw_TZ' : 'en_US';

  /// Initialize the language provider
  Future<void> initialize(
    TTSService ttsService,
    SpeechService speechService,
  ) async {
    _ttsService = ttsService;
    _speechService = speechService;

    // Load saved language preference
    await _loadLanguagePreference();

    // Apply language to services
    await _applyLanguageToServices();
  }

  /// Load language preference from storage
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null &&
          ['english', 'swahili'].contains(savedLanguage)) {
        _currentLanguage = savedLanguage;
        if (kDebugMode)
          print('🌍 Loaded language preference: $_currentLanguage');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading language preference: $e');
      // Default to English on error
      _currentLanguage = 'english';
    }
  }

  /// Save language preference to storage
  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLanguage);
      if (kDebugMode) print('💾 Saved language preference: $_currentLanguage');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving language preference: $e');
    }
  }

  /// Apply current language to TTS and Speech services
  Future<void> _applyLanguageToServices() async {
    if (_ttsService == null || _speechService == null) return;

    try {
      // Update TTS language
      await _ttsService!.setLanguage(ttsLocale);

      // Update Speech recognition language
      await _speechService!.setLocale(speechLocale);

      if (kDebugMode) {
        print('🔧 Applied language to services:');
        print('   TTS: $ttsLocale');
        print('   Speech: $speechLocale');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error applying language to services: $e');
    }
  }

  /// Change language and update backend
  Future<String> changeLanguage(String newLanguage) async {
    if (!['english', 'swahili'].contains(newLanguage)) {
      throw ArgumentError('Invalid language: $newLanguage');
    }

    if (_currentLanguage == newLanguage) {
      return getTranslation('languageAlreadySet');
    }

    _isChangingLanguage = true;
    notifyListeners();

    try {
      final oldLanguage = _currentLanguage;
      _currentLanguage = newLanguage;

      // Save preference
      await _saveLanguagePreference();

      // Apply to services
      await _applyLanguageToServices();

      // Update backend language
      await _updateBackendLanguage();

      _isChangingLanguage = false;
      notifyListeners();

      if (kDebugMode) {
        print('🌍 Language changed: $oldLanguage → $_currentLanguage');
      }

      return getTranslation('languageChanged');
    } catch (e) {
      _isChangingLanguage = false;
      notifyListeners();

      if (kDebugMode) print('❌ Error changing language: $e');
      return getTranslation('languageChangeError');
    }
  }

  /// Update backend language via API
  Future<void> _updateBackendLanguage() async {
    try {
      await QnAService.changeLanguage(_currentLanguage);
      if (kDebugMode) print('✅ Backend language updated to $_currentLanguage');
    } catch (e) {
      if (kDebugMode) print('⚠️ Backend language update failed: $e');
      // Don't throw error - app can still work with local language change
    }
  }

  /// Switch to Swahili
  Future<String> switchToSwahili() async {
    return await changeLanguage('swahili');
  }

  /// Switch to English
  Future<String> switchToEnglish() async {
    return await changeLanguage('english');
  }

  /// Detect language command from voice input
  String? detectLanguageCommand(String input) {
    final lowerInput = input.toLowerCase().trim();

    // English to Swahili commands
    if (lowerInput.contains('change language to swahili') ||
        lowerInput.contains('switch to swahili') ||
        lowerInput.contains('speak swahili') ||
        lowerInput.contains('use swahili') ||
        lowerInput.contains('badilisha lugha kuwa kiswahili')) {
      return 'swahili';
    }

    // Swahili to English commands
    if (lowerInput.contains('badilisha lugha kuwa kiingereza') ||
        lowerInput.contains('badilisha lugha kuwa kingereza') ||
        lowerInput.contains('change language to english') ||
        lowerInput.contains('switch to english') ||
        lowerInput.contains('tumia kiingereza') ||
        lowerInput.contains('use english')) {
      return 'english';
    }

    return null;
  }

  /// Get translation for current language
  String getTranslation(String key) {
    return TTSService.translations[isSwahili ? 'sw' : 'en']?[key] ?? key;
  }

  /// Get voice commands for current language
  List<String> getVoiceCommands() {
    if (isSwahili) {
      return [
        'Msaada - Kupata msaada',
        'Muhtasari - Kupata muhtasari wa prospektasi',
        'Mipango - Kujua mipango yanayopatikana',
        'Ada - Kujua ada za masomo',
        'Uliza swali - Kuingia katika hali ya maswali',
        'Rudia - Kurudia jibu la mwisho',
        'Nyamaza - Kusitisha kusoma',
        'Acha kusikiliza - Kuzima sauti',
        'Amka - Kuwasha sauti',
        'Badilisha lugha kuwa Kiingereza - Kubadili lugha',
      ];
    } else {
      return [
        'Help - Get assistance',
        'Summarize - Get prospectus summary',
        'Programs - Learn about available programs',
        'Fees - Get fee information',
        'Ask questions - Enter Q&A mode',
        'Repeat - Repeat last response',
        'Stop - Stop speaking',
        'Stop listening - Disable voice',
        'Wake up - Enable voice',
        'Change language to Swahili - Switch language',
      ];
    }
  }

  /// Get welcome message for current language
  String getWelcomeMessage() {
    return getTranslation('welcome');
  }

  /// Get help message for current language
  String getHelpMessage() {
    return getTranslation('help');
  }
}
