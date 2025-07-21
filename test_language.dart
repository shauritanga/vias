import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/shared/providers/language_provider.dart';
import 'lib/core/services/tts_service.dart';
import 'lib/core/services/speech_service.dart';

/// Simple test app to verify Swahili language functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final ttsService = TTSService();
  final speechService = SpeechService();
  final languageProvider = LanguageProvider();
  
  await ttsService.initialize();
  await speechService.initialize();
  await languageProvider.initialize(ttsService, speechService);
  
  runApp(LanguageTestApp(
    ttsService: ttsService,
    speechService: speechService,
    languageProvider: languageProvider,
  ));
}

class LanguageTestApp extends StatelessWidget {
  final TTSService ttsService;
  final SpeechService speechService;
  final LanguageProvider languageProvider;

  const LanguageTestApp({
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
        title: 'Language Test',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const LanguageTestScreen(),
      ),
    );
  }
}

class LanguageTestScreen extends StatefulWidget {
  const LanguageTestScreen({super.key});

  @override
  State<LanguageTestScreen> createState() => _LanguageTestScreenState();
}

class _LanguageTestScreenState extends State<LanguageTestScreen> {
  late TTSService _ttsService;
  late LanguageProvider _languageProvider;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _ttsService = context.read<TTSService>();
    _languageProvider = context.read<LanguageProvider>();
  }

  Future<void> _testLanguageCommands() async {
    setState(() {
      _testResult = 'Testing language commands...\n';
    });

    // Test English commands
    final englishCommands = [
      'change language to swahili',
      'switch to swahili',
      'use swahili',
    ];

    for (final command in englishCommands) {
      final detected = _languageProvider.detectLanguageCommand(command);
      setState(() {
        _testResult += 'Command: "$command" -> Detected: $detected\n';
      });
    }

    // Test Swahili commands
    final swahiliCommands = [
      'badilisha lugha kuwa kiingereza',
      'change language to english',
      'tumia kiingereza',
    ];

    for (final command in swahiliCommands) {
      final detected = _languageProvider.detectLanguageCommand(command);
      setState(() {
        _testResult += 'Command: "$command" -> Detected: $detected\n';
      });
    }

    setState(() {
      _testResult += '\n✅ Language command detection test completed!';
    });
  }

  Future<void> _testLanguageSwitch() async {
    setState(() {
      _testResult = 'Testing language switching...\n';
    });

    try {
      // Switch to Swahili
      final swahiliMessage = await _languageProvider.switchToSwahili();
      setState(() {
        _testResult += 'Switched to Swahili: $swahiliMessage\n';
        _testResult += 'Current language: ${_languageProvider.currentLanguage}\n';
      });

      await _ttsService.speak(swahiliMessage);
      await Future.delayed(const Duration(seconds: 2));

      // Switch to English
      final englishMessage = await _languageProvider.switchToEnglish();
      setState(() {
        _testResult += 'Switched to English: $englishMessage\n';
        _testResult += 'Current language: ${_languageProvider.currentLanguage}\n';
      });

      await _ttsService.speak(englishMessage);

      setState(() {
        _testResult += '\n✅ Language switching test completed!';
      });
    } catch (e) {
      setState(() {
        _testResult += '\n❌ Error: $e';
      });
    }
  }

  Future<void> _testTranslations() async {
    setState(() {
      _testResult = 'Testing translations...\n';
    });

    // Test English translations
    await _languageProvider.switchToEnglish();
    final englishWelcome = _languageProvider.getWelcomeMessage();
    final englishHelp = _languageProvider.getHelpMessage();

    setState(() {
      _testResult += 'English Welcome: ${englishWelcome.substring(0, 50)}...\n';
      _testResult += 'English Help: ${englishHelp.substring(0, 50)}...\n';
    });

    // Test Swahili translations
    await _languageProvider.switchToSwahili();
    final swahiliWelcome = _languageProvider.getWelcomeMessage();
    final swahiliHelp = _languageProvider.getHelpMessage();

    setState(() {
      _testResult += 'Swahili Welcome: ${swahiliWelcome.substring(0, 50)}...\n';
      _testResult += 'Swahili Help: ${swahiliHelp.substring(0, 50)}...\n';
    });

    setState(() {
      _testResult += '\n✅ Translation test completed!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Current Language: ${languageProvider.currentLanguage}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Is Swahili: ${languageProvider.isSwahili}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'TTS Locale: ${languageProvider.ttsLocale}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'Speech Locale: ${languageProvider.speechLocale}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _testLanguageCommands,
              child: const Text('Test Language Commands'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _testLanguageSwitch,
              child: const Text('Test Language Switching'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _testTranslations,
              child: const Text('Test Translations'),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResult.isEmpty ? 'Click a test button to start...' : _testResult,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
