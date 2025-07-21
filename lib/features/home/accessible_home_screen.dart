import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/content_management_service.dart';
import '../../shared/widgets/voice_command_widget.dart';

/// Accessible home screen designed specifically for visually impaired users
class AccessibleHomeScreen extends StatefulWidget {
  const AccessibleHomeScreen({super.key});

  @override
  State<AccessibleHomeScreen> createState() => _AccessibleHomeScreenState();
}

class _AccessibleHomeScreenState extends State<AccessibleHomeScreen> {
  late TTSService _ttsService;
  late SpeechService _speechService;
  late ContentManagementService _contentService;

  String _currentStatus =
      'Welcome! Tap the large blue button or say a command to get started.';
  bool _isListening = false;
  bool _isInQAMode = false;
  bool _isInSectionSummaryMode = false;
  String _lastSpokenAnswer = '';

  @override
  void initState() {
    super.initState();
    _ttsService = context.read<TTSService>();
    _speechService = context.read<SpeechService>();
    _contentService = ContentManagementService();

    // Auto-start with welcome message and instructions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _speakWelcomeMessage();
      // Auto-start voice listening after welcome message
      await Future.delayed(const Duration(milliseconds: 2000));
      _startVoiceListening();
    });
  }

  /// Start voice listening automatically
  void _startVoiceListening() {
    setState(() {
      _isListening = true;
    });
    _updateStatus(
      'Voice listening is active. Speak your command now or tap any button.',
    );
  }

  Future<void> _speakWelcomeMessage() async {
    const welcomeMessage = '''
Welcome to VIAS, your voice assistant for university information.

Voice commands are now active. You can say:
- "Summarize PDF" for a full summary
- "Ask questions" to ask anything
- "View programs" for program information
- "Check fees" for cost information
- "Help" to repeat these instructions

You can also tap the large colored buttons on screen.

Voice listening is starting now. What would you like to know?
''';

    await _ttsService.speak(welcomeMessage);
    _updateStatus('Voice listening active. Say a command or tap a button.');
  }

  void _updateStatus(String status) {
    setState(() {
      _currentStatus = status;
    });
  }

  Future<void> _toggleVoiceListening() async {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      await _ttsService.speak('Listening for your command now.');
      _updateStatus('Listening... Speak your command now.');
      // The VoiceCommandWidget will handle the actual listening
    } else {
      await _ttsService.speak('Voice listening stopped.');
      _updateStatus('Voice listening stopped. Tap to start again.');
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (kDebugMode) {
      print('🎤 Voice command received: "$command"');
    }

    // Convert raw speech to command key
    final processedCommand = _processVoiceInput(command.toLowerCase().trim());

    if (kDebugMode) {
      print('🔄 Processed command: "$processedCommand"');
    }

    // Handle different modes
    if (_isInQAMode) {
      _isInQAMode = false;
      await _handleUserQuestion(command);
      return;
    }

    if (_isInSectionSummaryMode) {
      _isInSectionSummaryMode = false;
      await _handleSectionSummaryRequest(command);
      return;
    }

    // Process main commands
    switch (processedCommand) {
      case 'summarize_pdf':
      case 'summarize_document':
      case 'full_summary':
        await _handleFullSummary();
        break;

      case 'summarize_section':
        await _handleSectionSummary();
        break;

      case 'ask_questions':
        await _handleAskQuestions();
        break;

      case 'explore_programs':
      case 'view_programs':
        await _handleExplorePrograms();
        break;

      case 'view_fees':
      case 'check_fees':
        await _handleViewFees();
        break;

      case 'help':
        await _speakWelcomeMessage();
        break;

      case 'repeat':
        if (_lastSpokenAnswer.isNotEmpty) {
          await _ttsService.speak(_lastSpokenAnswer);
        } else {
          await _ttsService.speak(
            'Nothing to repeat. Please ask a question first.',
          );
        }
        break;

      case 'stop':
        await _ttsService.stop();
        _updateStatus('Speech stopped.');
        break;

      default:
        // Check if it sounds like a question
        if (_isLikelyQuestion(command)) {
          await _ttsService.speak(
            'Let me try to answer that question for you.',
          );
          await _handleUserQuestion(command);
        } else {
          await _ttsService.speak(
            'I did not understand that command. Say "help" to hear available commands, or try saying "summarize PDF", "ask questions", or "view programs".',
          );
          _updateStatus('Command not recognized. Say "help" for instructions.');
        }
        break;
    }
  }

  /// Process raw voice input and map to command keys
  String _processVoiceInput(String rawInput) {
    String cleaned = rawInput
        .replaceAll(
          RegExp(
            r'\b(please|can you|could you|i want to|i would like to|help me)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Command mapping with multiple variations
    final commandMappings = {
      'summarize_pdf': [
        'summarize pdf',
        'summarize document',
        'summarize the pdf',
        'summarize the document',
        'full summary',
        'complete summary',
        'give me a summary',
        'summary of pdf',
        'tell me about the pdf',
        'what is in the pdf',
        'overview of document',
      ],
      'summarize_section': [
        'summarize section',
        'section summary',
        'summarize a section',
        'tell me about section',
        'specific section',
        'part of document',
      ],
      'ask_questions': [
        'ask questions',
        'ask question',
        'i have a question',
        'question mode',
        'questions',
        'q and a',
        'qa mode',
        'answer questions',
        'help with questions',
      ],
      'explore_programs': [
        'explore programs',
        'show programs',
        'view programs',
        'list programs',
        'what programs',
        'available programs',
        'courses',
        'degrees',
      ],
      'view_fees': [
        'view fees',
        'show fees',
        'fee structure',
        'cost',
        'price',
        'tuition',
        'how much',
        'fees',
        'payment',
        'charges',
        'check fees',
      ],
      'help': [
        'help',
        'instructions',
        'how to use',
        'commands',
        'what can you do',
      ],
      'stop': ['stop', 'pause', 'halt', 'quiet', 'silence'],
      'repeat': [
        'repeat',
        'say again',
        'repeat that',
        'again',
        'one more time',
      ],
    };

    // Find matching command
    for (final entry in commandMappings.entries) {
      final commandKey = entry.key;
      final variations = entry.value;

      for (final variation in variations) {
        if (cleaned.contains(variation) || _fuzzyMatch(cleaned, variation)) {
          return commandKey;
        }
      }
    }

    return 'unknown_command';
  }

  /// Simple fuzzy matching for voice commands
  bool _fuzzyMatch(String input, String target) {
    final inputWords = input.split(' ');
    final targetWords = target.split(' ');

    int matches = 0;
    for (final targetWord in targetWords) {
      for (final inputWord in inputWords) {
        if (inputWord.contains(targetWord) || targetWord.contains(inputWord)) {
          matches++;
          break;
        }
      }
    }

    return matches >= (targetWords.length * 0.7).ceil();
  }

  /// Check if input sounds like a question
  bool _isLikelyQuestion(String input) {
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
      'could',
      'would',
      'should',
      'is',
      'are',
      'do',
      'does',
      'did',
      'will',
      'was',
      'were',
    ];

    final questionPatterns = [
      'tell me about',
      'explain',
      'describe',
      'information about',
      'details about',
      'cost of',
      'price of',
      'requirements for',
      'how to',
      'when is',
      'where is',
    ];

    final words = lowerInput.split(' ');
    if (words.isNotEmpty && questionWords.contains(words.first)) {
      return true;
    }

    for (final pattern in questionPatterns) {
      if (lowerInput.contains(pattern)) {
        return true;
      }
    }

    return lowerInput.endsWith('?') || words.length > 4;
  }

  /// Handle full PDF summary request
  Future<void> _handleFullSummary() async {
    _updateStatus('Generating full PDF summary...');

    try {
      await _ttsService.speak(
        'Generating a comprehensive summary of the uploaded prospectus. Please wait...',
      );

      final summary = await QnAService.summarizeFullPDF();
      _lastSpokenAnswer = summary;

      await _ttsService.speak(summary);
      _updateStatus('Full PDF summary completed');
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      await _ttsService.speak(errorMsg);
      _updateStatus(errorMsg);
    }
  }

  /// Handle section summary request
  Future<void> _handleSectionSummary() async {
    _updateStatus('Which section would you like me to summarize?');

    await _ttsService.speak(
      'Which section would you like me to summarize? For example, say "admission requirements", "fee structure", or "computer science program".',
    );

    _isInSectionSummaryMode = true;
  }

  /// Handle section summary with specific section name
  Future<void> _handleSectionSummaryRequest(String sectionName) async {
    _updateStatus('Generating summary for: $sectionName');

    try {
      await _ttsService.speak(
        'Generating summary for $sectionName. Please wait...',
      );

      final summary = await QnAService.summarizeSection(sectionName);
      _lastSpokenAnswer = summary;

      await _ttsService.speak(summary);
      _updateStatus('Section summary completed');
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      await _ttsService.speak(errorMsg);
      _updateStatus(errorMsg);
    }
  }

  /// Handle ask questions mode
  Future<void> _handleAskQuestions() async {
    _isInQAMode = true;
    _updateStatus('Question mode activated. Ask your question now.');
    await _ttsService.speak(
      'Question mode activated. Ask me anything about the prospectus.',
    );
  }

  /// Handle user question
  Future<void> _handleUserQuestion(String question) async {
    _updateStatus('Processing your question...');

    try {
      await _ttsService.speak('Let me find the answer to your question.');

      final answer = await QnAService.askQuestion(question);
      _lastSpokenAnswer = answer;

      await _ttsService.speak(answer);
      _updateStatus(
        'Question answered. Ask another question or say a new command.',
      );
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      await _ttsService.speak(errorMsg);
      _updateStatus(errorMsg);
    }
  }

  /// Handle explore programs
  Future<void> _handleExplorePrograms() async {
    _updateStatus('Loading program information...');
    await _ttsService.speak(
      'Here are the available programs. You can ask questions about any specific program for more details.',
    );

    const programsInfo = '''
Available Programs:

1. Bachelor of Computer Science - 4 years
   Focus on programming, software development, and computer systems

2. Bachelor of Information Technology - 4 years  
   Focus on IT infrastructure, networks, and system administration

3. Diploma in Computer Studies - 2 years
   Foundation course covering basic computing skills

You can ask questions like "What are the requirements for computer science?" or "How much does the IT program cost?" for more specific information.
''';

    _lastSpokenAnswer = programsInfo;
    await _ttsService.speak(programsInfo);
    _updateStatus(
      'Program information provided. Ask questions for more details.',
    );
  }

  /// Handle view fees
  Future<void> _handleViewFees() async {
    _updateStatus('Loading fee information...');
    await _ttsService.speak('Here is the fee structure information.');

    const feesInfo = '''
Fee Structure:

Bachelor Programs: 120,000 Kenya Shillings per year
Diploma Programs: 80,000 Kenya Shillings per year

Payment Schedule:
- 60% due at beginning of first semester
- 40% due at beginning of second semester

Payment Methods:
- Bank transfer
- M-Pesa mobile money
- Cash payment at campus

You can ask questions like "Are there payment plans available?" or "What about scholarships?" for more information.
''';

    _lastSpokenAnswer = feesInfo;
    await _ttsService.speak(feesInfo);
    _updateStatus('Fee information provided. Ask questions for more details.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // High contrast for accessibility
      appBar: AppBar(
        title: const Text(
          'VIAS - Voice Assistant',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Larger app bar
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Larger padding
          child: Column(
            children: [
              // Large Status Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[400]!, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 80, // Much larger icon
                      color: Colors.blue[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _currentStatus,
                      style: const TextStyle(
                        fontSize: 20, // Larger text
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Large Voice Activation Button
              SizedBox(
                width: double.infinity,
                height: 120, // Very large button
                child: ElevatedButton(
                  onPressed: _toggleVoiceListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isListening ? Icons.mic : Icons.mic_none, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _isListening ? 'LISTENING...' : 'TAP TO SPEAK',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Voice Command Widget (Always active)
              VoiceCommandWidget(onCommand: _handleVoiceCommand, enabled: true),

              // Large Accessible Action Buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLargeAccessibleButton(
                      'SUMMARIZE PDF',
                      Icons.description,
                      Colors.purple[600]!,
                      () => _handleVoiceCommand('summarize_pdf'),
                    ),
                    _buildLargeAccessibleButton(
                      'ASK QUESTIONS',
                      Icons.help_outline,
                      Colors.orange[600]!,
                      () => _handleVoiceCommand('ask_questions'),
                    ),
                    _buildLargeAccessibleButton(
                      'VIEW PROGRAMS',
                      Icons.school,
                      Colors.green[600]!,
                      () => _handleVoiceCommand('explore_programs'),
                    ),
                    _buildLargeAccessibleButton(
                      'CHECK FEES',
                      Icons.attach_money,
                      Colors.red[600]!,
                      () => _handleVoiceCommand('view_fees'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build large, accessible button for visually impaired users
  Widget _buildLargeAccessibleButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 80, // Large button height
      child: ElevatedButton.icon(
        onPressed: () async {
          // Provide audio feedback when button is pressed
          await _ttsService.speak('$text selected');
          onPressed();
        },
        icon: Icon(icon, size: 32),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
      ),
    );
  }
}
