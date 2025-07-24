import 'package:flutter/foundation.dart';

/// Application configuration for different environments
class AppConfig {
  // Environment detection
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;

  // Server configuration
  static const String _productionUrl = 'https://vias.onrender.com';
  static const String _developmentUrl = 'http://192.168.1.194:10000';
  static const String _localUrl = 'http://localhost:10000';
  static const String _emulatorUrl = 'http://10.0.2.2:10000';

  /// Get the appropriate server URL based on environment
  static String get serverUrl {
    if (isProduction) {
      return _productionUrl;
    } else {
      // For development, you can manually switch between these:
      return _productionUrl; // Use production server even in debug mode
      // return _developmentUrl; // Use local network server
      // return _localUrl; // Use localhost
      // return _emulatorUrl; // Use Android emulator
    }
  }

  /// Get fallback URLs for network resilience
  static List<String> get fallbackUrls => [
    _productionUrl, // Always try production first
    _developmentUrl, // Local network fallback
    _localUrl, // Localhost fallback
    _emulatorUrl, // Emulator fallback
  ];

  /// API endpoints
  static const String answerQuestionEndpoint = '/api/answer-question';
  static const String processPdfEndpoint = '/api/process-pdf';
  static const String summarizePdfEndpoint = '/api/summarize-pdf';
  static const String healthEndpoint = '/api/health';
  static const String languageEndpoint = '/api/language';
  static const String contentEndpoint = '/api/content';

  /// App metadata
  static const String appName = 'VIAS Q&A System';
  static const String appVersion = '2.0.0';
  static const String appDescription =
      'Enhanced Q&A system with Hugging Face AI';

  /// Feature flags
  static const bool enableVoiceFeatures = true;
  static const bool enableConversationHistory = true;
  static const bool enablePdfSummarization = true;
  static const bool enableMultiLanguage = true;
  static const bool enableOfflineMode = false; // Future feature

  /// Performance settings
  static const int requestTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const int maxConversationHistory = 10;
  static const int maxPdfSizeBytes = 50 * 1024 * 1024; // 50MB

  /// Debug settings
  static bool get enableDebugLogs => isDevelopment;
  static bool get enableNetworkLogs => isDevelopment;
  static bool get enablePerformanceLogs => isDevelopment;

  /// Get current configuration summary
  static Map<String, dynamic> get configSummary => {
    'environment': isProduction ? 'production' : 'development',
    'serverUrl': serverUrl,
    'appVersion': appVersion,
    'features': {
      'voice': enableVoiceFeatures,
      'conversation': enableConversationHistory,
      'summarization': enablePdfSummarization,
      'multiLanguage': enableMultiLanguage,
      'offline': enableOfflineMode,
    },
    'performance': {
      'timeout': requestTimeoutSeconds,
      'retries': maxRetryAttempts,
      'historyLimit': maxConversationHistory,
      'maxPdfSize': '${maxPdfSizeBytes ~/ (1024 * 1024)}MB',
    },
  };

  /// Print configuration for debugging
  static void printConfig() {
    if (enableDebugLogs) {
      print('🔧 App Configuration:');
      print('   Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}');
      print('   Server URL: $serverUrl');
      print('   App Version: $appVersion');
      print(
        '   Features: Voice=$enableVoiceFeatures, Conversation=$enableConversationHistory',
      );
      print(
        '   Performance: Timeout=${requestTimeoutSeconds}s, Retries=$maxRetryAttempts',
      );
    }
  }
}
