import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/content_management_service.dart';
import '../../shared/providers/language_provider.dart';
import '../../shared/widgets/language_indicator.dart';

/// Voice-First Home Screen - Inspired by Alexa/Google Assistant
/// Minimal UI, Maximum Voice Interaction
class VoiceFirstHome extends StatefulWidget {
  const VoiceFirstHome({super.key});

  @override
  State<VoiceFirstHome> createState() => _VoiceFirstHomeState();
}

class _VoiceFirstHomeState extends State<VoiceFirstHome>
    with TickerProviderStateMixin {
  late TTSService _ttsService;
  late SpeechService _speechService;
  late LanguageProvider _languageProvider;

  // App State
  String _currentStatus = 'Starting...';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInQAMode = false;
  String _lastResponse = '';

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _ttsService = context.read<TTSService>();
    _speechService = context.read<SpeechService>();
    _languageProvider = context.read<LanguageProvider>();

    _setupAnimations();
    _initializeVoiceAssistant();
  }

  void _setupAnimations() {
    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for processing
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVoiceAssistant() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _updateStatus('Welcome to VIAS');

    // Use language-aware welcome message
    final welcomeMessage = _languageProvider.getWelcomeMessage();
    await _ttsService.speak(welcomeMessage);

    await Future.delayed(const Duration(milliseconds: 1000));
    _startListening();
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _currentStatus = status;
      });
    }
  }

  Future<void> _startListening() async {
    if (!mounted) return;

    setState(() {
      _isListening = true;
      _isProcessing = false;
    });

    _pulseController.repeat(reverse: true);
    _updateStatus('Listening...');

    try {
      await _speechService.startListening(
        onResult: _handleVoiceInput,
        onError: _handleVoiceError,
      );
    } catch (e) {
      _handleVoiceError('Failed to start listening: $e');
    }
  }

  void _stopListening() {
    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    _pulseController.stop();
    _speechService.stopListening();
  }

  Future<void> _handleVoiceInput(String input) async {
    if (!mounted || input.trim().isEmpty) return;

    // Filter out TTS feedback
    if (_isTTSFeedback(input)) {
      if (kDebugMode) print('🔇 Filtered TTS feedback: $input');
      return;
    }

    _stopListening();

    setState(() {
      _isProcessing = true;
    });

    _waveController.repeat();
    _updateStatus('Processing...');

    if (kDebugMode) print('🎤 Voice input: $input');

    try {
      await _processVoiceCommand(input);
    } catch (e) {
      await _ttsService.speak(
        'Sorry, I encountered an error. Please try again.',
      );
      if (kDebugMode) print('❌ Error processing command: $e');
    }

    _waveController.stop();
    setState(() {
      _isProcessing = false;
    });

    // Auto-restart listening after 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) _startListening();
  }

  void _handleVoiceError(String error) {
    if (kDebugMode) print('❌ Voice error: $error');
    _stopListening();
    _updateStatus('Voice error occurred');

    // Restart listening after error
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _startListening();
    });
  }

  bool _isTTSFeedback(String input) {
    final lowerInput = input.toLowerCase();
    final feedbackPhrases = [
      'welcome to vias',
      'say help for commands',
      'ask me anything',
      'question mode',
      'here is',
      'here are',
      'the answer is',
      'according to',
      'based on',
      'processing',
      'listening',
      'sorry',
      'please try again',
      'i found',
      'available programs',
      'fee structure',
      'admission requirements',
    ];

    return feedbackPhrases.any((phrase) => lowerInput.contains(phrase)) ||
        lowerInput.length < 3;
  }

  Future<void> _processVoiceCommand(String input) async {
    final command = input.toLowerCase().trim();

    if (kDebugMode) {
      print('🔍 Processing voice command:');
      print('   Raw input: "$input"');
      print('   Cleaned command: "$command"');
      print('   Command length: ${command.length}');
      print('   Contains "summarize": ${command.contains('summarize')}');
      print('   Contains "summary": ${command.contains('summary')}');
    }

    // Handle Q&A mode
    if (_isInQAMode) {
      if (command.contains('exit') ||
          command.contains('stop') ||
          command.contains('back')) {
        _isInQAMode = false;
        await _ttsService.speak(
          'Exiting question mode. What else can I help you with?',
        );
        _updateStatus('Ready for commands');
        return;
      }

      await _handleQuestion(input);
      return;
    }

    // Check for language commands FIRST
    final languageCommand = _languageProvider.detectLanguageCommand(input);
    if (languageCommand != null) {
      await _handleLanguageChange(languageCommand);
      return;
    }

    // Process main commands - QUESTION DETECTION FIRST!
    if (_isQuestion(input)) {
      // Auto-detect questions BEFORE keyword matching
      await _handleQuestion(input);
    } else if (input.startsWith('unknown_command:')) {
      // Handle unknown commands with prefix
      final actualInput = input.substring('unknown_command:'.length);
      if (_isQuestion(actualInput)) {
        await _handleQuestion(actualInput);
      } else {
        await _handleUnknownCommand(actualInput);
      }
    } else if (command.contains('help') ||
        command.contains('what can you do')) {
      await _handleHelp();
    } else if (command.contains('summarize') || command.contains('summary')) {
      await _handleSummarize();
    } else if (command.contains('question') || command.contains('ask')) {
      await _handleEnterQAMode();
    } else if (command.contains('program') || command.contains('course')) {
      await _handlePrograms();
    } else if (command.contains('fee') ||
        command.contains('cost') ||
        command.contains('price')) {
      await _handleFees();
    } else if (command.contains('repeat') || command.contains('again')) {
      await _handleRepeat();
    } else if (command.contains('stop') || command.contains('quiet')) {
      await _ttsService.stop();
      _updateStatus('Stopped');
    } else {
      await _handleUnknownCommand(input);
    }
  }

  bool _isQuestion(String input) {
    final lowerInput = input.toLowerCase();
    final questionWords = [
      'what',
      'how',
      'when',
      'where',
      'why',
      'who',
      'which',
      'can',
      'is',
      'are',
      'do',
      'does',
    ];
    final words = lowerInput.split(' ');

    return words.isNotEmpty && questionWords.contains(words.first) ||
        lowerInput.contains('tell me') ||
        lowerInput.contains('explain') ||
        lowerInput.endsWith('?') ||
        words.length > 5;
  }

  Future<void> _handleLanguageChange(String targetLanguage) async {
    _updateStatus('Changing language...');

    try {
      if (kDebugMode) print('🌍 Changing language to: $targetLanguage');

      final message = await _languageProvider.changeLanguage(targetLanguage);

      _updateStatus('Language changed');
      await _ttsService.speak(message);

      if (kDebugMode) print('✅ Language changed successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Language change error: $e');

      final errorMessage = _languageProvider.isSwahili
          ? 'Kuna tatizo la kubadilisha lugha. Jaribu tena.'
          : 'There was an error changing the language. Please try again.';

      await _ttsService.speak(errorMessage);
      _updateStatus('Language change failed');
    }
  }

  Future<void> _handleHelp() async {
    _updateStatus('Providing help');

    // Use language-aware help message
    final helpMessage = _languageProvider.getHelpMessage();

    _lastResponse = helpMessage;
    await _ttsService.speak(helpMessage);
  }

  Future<void> _handleSummarize() async {
    _updateStatus('Generating summary...');

    try {
      if (kDebugMode) print('🔄 Starting PDF summarization...');
      await _ttsService.speak(
        'Generating a comprehensive summary. Please wait.',
      );

      final summary = await QnAService.summarizeFullPDF();
      if (kDebugMode) {
        final preview = summary.length > 100
            ? summary.substring(0, 100)
            : summary;
        print('✅ Summary received: $preview...');
      }

      _lastResponse = summary;
      await _ttsService.speak(summary);
      _updateStatus('Summary completed');
    } catch (e) {
      if (kDebugMode) print('❌ Summary error: $e');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      await _ttsService.speak(errorMsg);
      _updateStatus('Summary failed');
    }
  }

  Future<void> _handleEnterQAMode() async {
    _isInQAMode = true;
    _updateStatus('Question mode active');
    await _ttsService.speak(
      'Question mode activated. Ask me anything about the university. Say "exit" to leave question mode.',
    );
  }

  Future<void> _handleQuestion(String question) async {
    _updateStatus('Finding answer...');

    try {
      if (kDebugMode) {
        print('🔄 Processing question: $question');
        print('🔍 Q&A Mode active: $_isInQAMode');
      }
      await _ttsService.speak('Let me find that information for you.');

      final answer = await QnAService.askQuestion(question);
      if (kDebugMode) {
        final preview = answer.length > 100 ? answer.substring(0, 100) : answer;
        print('✅ Answer received: $preview');
        print('📏 Answer length: ${answer.length} characters');
      }

      // Check for very short or empty answers
      if (answer.trim().length < 10) {
        if (kDebugMode) print('⚠️ Warning: Very short answer received');
        final fallbackAnswer =
            'I found some information, but the answer seems incomplete. Could you try rephrasing your question or ask about specific topics like programs, fees, or admission requirements?';
        _lastResponse = fallbackAnswer;
        await _ttsService.speak(fallbackAnswer);
      } else {
        _lastResponse = answer;
        await _ttsService.speak(answer);
      }

      if (_isInQAMode) {
        _updateStatus('Question mode - Ask another');
        // Wait a bit longer to ensure the answer is fully processed
        await Future.delayed(const Duration(milliseconds: 2000));
        // Check if still in Q&A mode (user might have exited)
        if (_isInQAMode) {
          await _ttsService.speak('Any other questions?');
        }
      } else {
        _updateStatus('Answer provided - Ready for commands');
        // Don't prompt for more questions when not in Q&A mode
      }
    } catch (e) {
      if (kDebugMode) print('❌ Question error: $e');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      await _ttsService.speak(errorMsg);
      _updateStatus('Answer failed');
    }
  }

  Future<void> _handlePrograms() async {
    _updateStatus('Loading programs...');
    const programsInfo = '''
Available programs at the university:

Bachelor of Computer Science - 4 years, focuses on programming and software development
Bachelor of Information Technology - 4 years, focuses on IT infrastructure and networks  
Diploma in Computer Studies - 2 years, foundation computing course

You can ask specific questions like "What are the requirements for computer science?" for more details.
''';

    _lastResponse = programsInfo;
    await _ttsService.speak(programsInfo);
    _updateStatus('Programs information provided');
  }

  Future<void> _handleFees() async {
    _updateStatus('Loading fees...');
    const feesInfo = '''
University fee structure:

Bachelor programs: 120,000 Kenya Shillings per year
Diploma programs: 80,000 Kenya Shillings per year

Payment is split: 60% first semester, 40% second semester
Payment methods: Bank transfer, M-Pesa, or cash at campus

Ask me about specific programs or payment plans for more details.
''';

    _lastResponse = feesInfo;
    await _ttsService.speak(feesInfo);
    _updateStatus('Fee information provided');
  }

  Future<void> _handleRepeat() async {
    if (_lastResponse.isNotEmpty) {
      _updateStatus('Repeating...');
      await _ttsService.speak(_lastResponse);
    } else {
      await _ttsService.speak('Nothing to repeat. Ask me a question first.');
    }
  }

  Future<void> _handleUnknownCommand(String input) async {
    if (kDebugMode) {
      print('❓ Unknown command received: "$input"');
      print('   Will provide help message instead of treating as question');
    }

    await _ttsService.speak(
      'I didn\'t understand that command. Say "help" for available commands, "summarize PDF" for a summary, or "ask questions" to enter question mode.',
    );
    _updateStatus('Command not recognized - say "help"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Language indicator in top-right corner
            Positioned(top: 16, right: 16, child: const LanguageIndicator()),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Voice Indicator
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _isListening
                              ? _pulseAnimation
                              : _waveAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isListening
                                  ? _pulseAnimation.value
                                  : (_isProcessing
                                        ? 1.0 + (_waveAnimation.value * 0.2)
                                        : 1.0),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getIndicatorColor(),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getIndicatorColor().withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getIndicatorIcon(),
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Status Text
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_isInQAMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Q&A MODE',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Emergency Stop Button (Hidden but accessible)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: GestureDetector(
                        onLongPress: () async {
                          await _ttsService.stop();
                          _stopListening();
                          await _ttsService.speak(
                            'Voice assistant stopped. Tap the circle to restart.',
                          );
                          _updateStatus('Stopped - Tap circle to restart');
                        },
                        child: Container(
                          width: 100,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'HOLD TO STOP',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIndicatorColor() {
    if (_isProcessing) return Colors.orange;
    if (_isListening) return Colors.blue;
    return Colors.grey[700]!;
  }

  IconData _getIndicatorIcon() {
    if (_isProcessing) return Icons.psychology;
    if (_isListening) return Icons.mic;
    return Icons.mic_none;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speechService.stopListening();
    super.dispose();
  }
}
