import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/voice_first_home.dart';
import 'core/services/tts_service.dart';
import 'core/services/speech_service.dart';
import 'shared/providers/language_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// VIAS Mobile App - EXCLUSIVELY FOR VISUALLY IMPAIRED END USERS
/// This app provides voice-controlled access to DIT prospectus information
/// NO ADMIN FEATURES - Admin portal is separate (admin_main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging
  await _initFirebaseMessaging();

  // Initialize services with retry logic
  final ttsService = TTSService();
  final speechService = SpeechService();

  // Initialize TTS with retry
  bool ttsInitialized = false;
  for (int i = 0; i < 3; i++) {
    ttsInitialized = await ttsService.initialize();
    if (ttsInitialized) break;

    print('TTS initialization attempt ${i + 1} failed, retrying...');
    await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
  }

  if (!ttsInitialized) {
    print('Warning: TTS service failed to initialize after 3 attempts');
  }

  // Initialize Speech Recognition
  await speechService.initialize();

  // Initialize Language Provider
  final languageProvider = LanguageProvider();
  await languageProvider.initialize(ttsService, speechService);

  runApp(
    ViasApp(
      ttsService: ttsService,
      speechService: speechService,
      languageProvider: languageProvider,
    ),
  );
}

final List<RemoteMessage> notificationHistory = [];

Future<void> _initFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    notificationHistory.add(message);
    final ttsService = TTSService();
    await ttsService.initialize();
    final lang = ttsService.languageCode;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final msg = lang == 'sw'
        ? 'Taarifa mpya: $title. $body'
        : 'New notification: $title. $body';
    await ttsService.speak(msg);
  });
}

class ViasApp extends StatelessWidget {
  final TTSService ttsService;
  final SpeechService speechService;
  final LanguageProvider languageProvider;

  const ViasApp({
    super.key,
    required this.ttsService,
    required this.speechService,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TTSService>.value(value: ttsService),
        Provider<SpeechService>.value(value: speechService),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
      child: MaterialApp(
        title: 'VIAS - Voice Assistant for Visually Impaired Students',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Accessibility-first theme with high contrast
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ).copyWith(
                // High contrast colors for better accessibility
                primary: Colors.blue.shade700,
                secondary: Colors.orange.shade600,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
          // Large text for better readability
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 20),
            bodyMedium: TextStyle(fontSize: 18),
            labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          // Accessible button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 60), // Large touch targets
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const VoiceFirstHome(),
      ),
    );
  }
}
