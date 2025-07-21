import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/content_management_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/analytics_service.dart';
import '../../shared/widgets/voice_command_widget.dart';
import '../../shared/widgets/tts_controls.dart';
import '../../shared/models/prospectus_models.dart';
import '../../main.dart' show notificationHistory;

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  late TTSService _ttsService;
  late ContentManagementService _contentService;
  late SpeechService _speechService;
  String _currentStatus = 'Welcome to VIAS - DIT Prospectus Assistant';
  bool _isInQAMode = false;
  bool _isInSectionSummaryMode = false;
  bool _announcedOffline = false;
  final String _userId = 'anonymous'; // Replace with real user ID if available
  String? _pendingFeedback;
  final List<String> _feedbackHistory = [];
  List<Map<String, String>> _qaHistory = [];
  String _lastSpokenAnswer = '';
  double _ttsRate = 0.5;
  String _currentLanguage = 'en'; // 'en' or 'sw'

  // Sample data - will be replaced with real data from Firebase later
  final List<Program> _samplePrograms = [
    Program(
      id: '1',
      name: 'Bachelor of Computer Science',
      description:
          'A comprehensive program covering software development, algorithms, and computer systems.',
      duration: '3 years',
      requirements: [
        'Form 6 with 2 principal passes',
        'Mathematics and Physics',
      ],
      category: 'Bachelor',
      faculty: 'Engineering and Technology',
      fee: 2500000,
      careerOpportunities: [
        'Software Developer',
        'System Analyst',
        'IT Consultant',
      ],
    ),
    Program(
      id: '2',
      name: 'Bachelor of Information Technology',
      description:
          'Focus on practical IT skills, networking, and system administration.',
      duration: '3 years',
      requirements: ['Form 6 with 2 principal passes', 'Mathematics'],
      category: 'Bachelor',
      faculty: 'Engineering and Technology',
      fee: 2300000,
      careerOpportunities: [
        'Network Administrator',
        'IT Support Specialist',
        'Database Administrator',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ttsService = context.read<TTSService>();
    _speechService = context.read<SpeechService>();
    _contentService = ContentManagementService();

    // Welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_contentService.isOffline && !_announcedOffline) {
        _announcedOffline = true;
        final lang = _ttsService.languageCode;
        final msg = lang == 'sw'
            ? 'Upo kwenye hali ya nje ya mtandao. Unatumia data iliyohifadhiwa.'
            : 'You are in offline mode. Using cached data.';
        await _ttsService.speak(msg);
      }
      _speakWelcomeMessage();
    });
  }

  void _speakWelcomeMessage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lang = _ttsService.languageCode;
    await _ttsService.speak(TTSService.translations[lang]!['welcome']!);
  }

  void _handleVoiceCommand(String command) async {
    final lang = _ttsService.languageCode;
    final analytics = AnalyticsService();

    // Convert raw speech to command key
    final processedCommand = _processVoiceInput(command.toLowerCase().trim());

    if (kDebugMode) {
      print('🎤 Raw voice input: "$command"');
      print('🔄 Processed command: "$processedCommand"');
    }

    if (_isInQAMode) {
      _isInQAMode = false;
      analytics.trackEvent(
        userId: _userId,
        eventType: EventType.voiceCommand,
        eventName: 'q_and_a',
        properties: {'query': command},
      );
      await _handleUserQuestion(command);
      return;
    }

    if (_isInSectionSummaryMode) {
      _isInSectionSummaryMode = false;
      await _handleSectionSummaryRequest(command);
      return;
    }
    if (_pendingFeedback != null) {
      // Save feedback
      _feedbackHistory.add(command);
      analytics.trackEvent(
        userId: _userId,
        eventType: EventType.contentAccess,
        eventName: 'user_feedback',
        properties: {'feedback': command},
      );
      _pendingFeedback = null;
      final msg = lang == 'sw'
          ? 'Asante kwa maoni yako.'
          : 'Thank you for your feedback.';
      await _ttsService.speak(msg);
      _updateStatus(msg);
      return;
    }
    switch (processedCommand) {
      case 'explore_programs':
        _handleExplorePrograms();
        break;
      case 'view_fees':
        _handleViewFees();
        break;
      case 'admissions_info':
        _handleAdmissionsInfo();
        break;
      case 'ask_questions':
        _handleAskQuestions();
        _isInQAMode = true;
        break;
      case 'summarize_pdf':
      case 'summarize_document':
      case 'full_summary':
        _handleFullSummary();
        break;
      case 'summarize_section':
        _handleSectionSummary();
        break;
      case 'stop':
        await _ttsService.stop();
        _updateStatus(TTSService.translations[lang]!['stopped']!);
        break;
      case 'repeat':
        if (_lastSpokenAnswer.isNotEmpty) {
          await _ttsService.speak(_lastSpokenAnswer);
        }
        break;
      case 'slower':
        _ttsRate = (_ttsRate - 0.1).clamp(0.2, 1.0);
        await _ttsService.setSpeechRate(_ttsRate);
        if (_lastSpokenAnswer.isNotEmpty) {
          await _ttsService.speak(_lastSpokenAnswer);
        }
        _updateStatus(
          lang == 'sw'
              ? 'Kasi ya kusoma imepunguzwa.'
              : 'Speech rate decreased.',
        );
        break;
      case 'faster':
        _ttsRate = (_ttsRate + 0.1).clamp(0.2, 1.0);
        await _ttsService.setSpeechRate(_ttsRate);
        if (_lastSpokenAnswer.isNotEmpty) {
          await _ttsService.speak(_lastSpokenAnswer);
        }
        _updateStatus(
          lang == 'sw'
              ? 'Kasi ya kusoma imeongezeka.'
              : 'Speech rate increased.',
        );
        break;
      case 'switch_to_swahili':
        await _ttsService.switchToSwahili();
        await _speechService.switchToSwahili();
        setState(() {
          _currentLanguage = 'sw';
        });
        _updateStatus(TTSService.translations['sw']!['switched_to_swahili']!);
        await _ttsService.speak(
          TTSService.translations['sw']!['switched_to_swahili']!,
        );
        break;
      case 'switch_to_english':
        await _ttsService.switchToEnglish();
        await _speechService.switchToEnglish();
        setState(() {
          _currentLanguage = 'en';
        });
        _updateStatus(TTSService.translations['en']!['switched_to_english']!);
        await _ttsService.speak(
          TTSService.translations['en']!['switched_to_english']!,
        );
        break;
      case 'read_notifications':
      case 'soma_taarifa':
        await _handleReadNotifications();
        break;
      case 'send_feedback':
      case 'tuma_maoni':
        _pendingFeedback = '';
        final prompt = lang == 'sw'
            ? 'Tafadhali sema maoni yako baada ya beep.'
            : 'Please speak your feedback after the beep.';
        await _ttsService.speak(prompt);
        _updateStatus(prompt);
        // (Optional) Play beep sound here
        return;
      default:
        // If command not recognized, treat as potential question
        if (processedCommand == 'unknown_command') {
          // Check if it sounds like a question
          if (_isLikelyQuestion(command)) {
            await _ttsService.speak(
              'Let me try to answer that question for you.',
            );
            await _handleUserQuestion(command);
          } else {
            analytics.trackEvent(
              userId: _userId,
              eventType: EventType.error,
              eventName: 'unknown_command',
              properties: {'command': command},
            );
            final helpMsg = lang == 'sw'
                ? 'Samahani, sijaelewa. Unaweza kusema "summarize PDF", "ask questions", au "view fees".'
                : 'Sorry, I did not understand. You can say "summarize PDF", "ask questions", or "view fees".';
            _updateStatus(helpMsg);
            await _ttsService.speak(helpMsg);
          }
        }
        break;
    }
  }

  /// Process raw voice input and map to command keys
  String _processVoiceInput(String rawInput) {
    // Remove common filler words and normalize
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
      // PDF Summary commands
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

      // Section Summary commands
      'summarize_section': [
        'summarize section',
        'section summary',
        'summarize a section',
        'tell me about section',
        'specific section',
        'part of document',
      ],

      // Q&A commands
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

      // Program exploration
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

      // Fee information
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
      ],

      // Admissions information
      'admissions_info': [
        'admissions info',
        'admission information',
        'how to apply',
        'application',
        'requirements',
        'admission requirements',
        'apply',
      ],

      // Control commands
      'stop': ['stop', 'pause', 'halt', 'quiet', 'silence', 'shut up'],

      'repeat': [
        'repeat',
        'say again',
        'repeat that',
        'again',
        'one more time',
      ],

      'slower': ['slower', 'speak slower', 'slow down', 'too fast'],

      'faster': ['faster', 'speak faster', 'speed up', 'too slow'],
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

    // If no command found, return original for Q&A processing
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

    // Require at least 70% word match
    return matches >= (targetWords.length * 0.7).ceil();
  }

  /// Check if input sounds like a question
  bool _isLikelyQuestion(String input) {
    final lowerInput = input.toLowerCase();

    // Question words
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

    // Question patterns
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

    // Check for question words at the beginning
    final words = lowerInput.split(' ');
    if (words.isNotEmpty && questionWords.contains(words.first)) {
      return true;
    }

    // Check for question patterns
    for (final pattern in questionPatterns) {
      if (lowerInput.contains(pattern)) {
        return true;
      }
    }

    // Check if it ends with question mark (unlikely in speech but possible)
    if (lowerInput.endsWith('?')) {
      return true;
    }

    // Check if it's longer than typical commands (likely descriptive question)
    if (words.length > 4) {
      return true;
    }

    return false;
  }

  Future<void> _handleReadNotifications() async {
    final lang = _ttsService.languageCode;
    if (notificationHistory.isEmpty) {
      final msg = lang == 'sw'
          ? 'Huna taarifa zozote mpya.'
          : 'You have no new notifications.';
      await _ttsService.speak(msg);
      _updateStatus(msg);
      return;
    }
    for (final message in notificationHistory.reversed) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      final msg = lang == 'sw'
          ? 'Taarifa: $title. $body'
          : 'Notification: $title. $body';
      await _ttsService.speak(msg);
    }
    _updateStatus(
      lang == 'sw'
          ? 'Taarifa zote zimesomwa.'
          : 'All notifications have been read.',
    );
  }

  void _handleExplorePrograms() async {
    final lang = _ttsService.languageCode;
    _updateStatus(TTSService.translations[lang]!['exploring_programs']!);

    // Get content from content management service
    String contentText = _contentService.getContentForVoiceReading('programs');

    // Check how many programs are loaded from Firebase
    final programCount = _contentService.programs.length;
    print('🔍 Programs loaded from Firebase: $programCount');

    // If no content from PDF, use sample data
    if (contentText.trim().isEmpty) {
      print('📋 Using sample data - no Firebase content available');
      final programsText = StringBuffer();
      programsText.write(
        '${TTSService.translations[lang]!['default_programs']!} ',
      );

      for (final program in _samplePrograms) {
        programsText.write(program.toSpeechText());
        programsText.write(' ');
      }
      contentText = programsText.toString();
    } else {
      print('🔥 Using Firebase data - $programCount programs loaded');
      contentText = (lang == 'sw')
          ? 'Hizi ndizo programu kutoka prospectus iliyopakiwa. $contentText'
          : 'Here are the programs from the uploaded prospectus. $contentText';
    }

    await _ttsService.speak(contentText);
  }

  void _handleViewFees() async {
    final lang = _ttsService.languageCode;
    _updateStatus(TTSService.translations[lang]!['viewing_fees']!);

    // Get content from content management service
    String contentText = _contentService.getContentForVoiceReading('fees');

    // Check how many fee structures are loaded from Firebase
    final feeCount = _contentService.feeStructures.length;
    print('💰 Fee structures loaded from Firebase: $feeCount');

    // If no content from PDF, use sample data
    if (contentText.trim().isEmpty) {
      print('📋 Using sample fee data - no Firebase content available');
      final feesText = StringBuffer();
      feesText.write('${TTSService.translations[lang]!['default_fees']!} ');

      for (final program in _samplePrograms) {
        if (program.fee != null) {
          feesText.write(
            (lang == 'sw')
                ? '${program.name} gharama yake ni shilingi ${program.fee!.toStringAsFixed(0)} kwa mwaka. '
                : '${program.name} costs ${program.fee!.toStringAsFixed(0)} Tanzanian Shillings per year. ',
          );
        }
      }

      feesText.write(
        (lang == 'sw')
            ? 'Kupata kwa kuweka kwa kila mwaka kwa mwaka.'
            : 'Payment can be made in installments throughout the academic year.',
      );
      contentText = feesText.toString();
    } else {
      print('🔥 Using Firebase fee data - $feeCount fee structures loaded');
      contentText = (lang == 'sw')
          ? 'Hizi ndizo ada kutoka prospectus iliyopakiwa. $contentText'
          : 'Here are the fees from the uploaded prospectus. $contentText';
    }

    await _ttsService.speak(contentText);
  }

  void _handleAdmissionsInfo() async {
    final lang = _ttsService.languageCode;
    _updateStatus(TTSService.translations[lang]!['admissions_info']!);

    // Get content from content management service
    String contentText = _contentService.getContentForVoiceReading(
      'admissions',
    );

    // If no content from PDF, use default information
    if (contentText.trim().isEmpty) {
      contentText = TTSService.translations[lang]!['default_admissions']!;
    } else {
      contentText = (lang == 'sw')
          ? 'Hizi ndizo taarifa za kujiunga kutoka prospectus iliyopakiwa. $contentText'
          : 'Here is the admission information from the uploaded prospectus. $contentText';
    }

    await _ttsService.speak(contentText);
  }

  void _handleAskQuestions() async {
    final lang = _ttsService.languageCode;
    _updateStatus(TTSService.translations[lang]!['ask_questions_mode']!);
    await _ttsService.speak(TTSService.translations[lang]!['ask_questions']!);
  }

  /// Handle full PDF summary request
  void _handleFullSummary() async {
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
      final errorMsg =
          'Sorry, I could not generate a summary. Please make sure a PDF has been uploaded first.';
      await _ttsService.speak(errorMsg);
      _updateStatus(errorMsg);
    }
  }

  /// Handle section summary request
  void _handleSectionSummary() async {
    _updateStatus('Which section would you like me to summarize?');

    await _ttsService.speak(
      'Which section would you like me to summarize? For example, say "admission requirements", "fee structure", or "computer science program".',
    );

    // Set a flag to capture the next voice input as section name
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
      final errorMsg =
          'Sorry, I could not find information about $sectionName in the uploaded prospectus.';
      await _ttsService.speak(errorMsg);
      _updateStatus(errorMsg);
    }
  }

  Future<void> _handleUserQuestion(String question) async {
    final lang = _ttsService.languageCode;
    _updateStatus(
      lang == 'sw'
          ? 'Natafuta jibu, tafadhali subiri...'
          : 'Searching for an answer, please wait...',
    );
    try {
      final answer = await QnAService.askQuestion(
        question,
        history: _qaHistory,
      );
      _qaHistory.add({'question': question, 'answer': answer});
      if (_qaHistory.length > 3) {
        _qaHistory = _qaHistory.sublist(_qaHistory.length - 3);
      }
      _lastSpokenAnswer = answer;
      _updateStatus(answer);
      await _ttsService.speak(answer);
    } catch (e) {
      final errorMsg = lang == 'sw'
          ? 'Samahani, imeshindikana kupata jibu.'
          : 'Sorry, I could not get an answer.';
      _lastSpokenAnswer = errorMsg;
      _updateStatus(errorMsg);
      await _ttsService.speak(errorMsg);
    }
  }

  void _updateStatus(String status) {
    setState(() {
      _currentStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = _ttsService.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VIAS - DIT Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Language Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentLanguage == 'sw'
                      ? 'Lugha: Kiswahili'
                      : 'Language: English',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Offline Indicator
            if (_contentService.isOffline)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'sw' ? 'Hali: Nje ya mtandao' : 'Status: Offline',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Status Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.assistant,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentStatus,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Enhanced Voice Command Widget
            VoiceCommandWidget(onCommand: _handleVoiceCommand, enabled: true),

            const SizedBox(height: 16),

            // TTS Controls
            const TTSControls(),

            const SizedBox(height: 16),

            // Quick Command Buttons
            // Expanded(
            //   child: GridView.count(
            //     crossAxisCount: 2,
            //     crossAxisSpacing: 16,
            //     mainAxisSpacing: 16,
            //     children: [
            //       _buildCommandButton(
            //         'Explore Programs',
            //         Icons.school,
            //         () => _handleExplorePrograms(),
            //       ),
            //       _buildCommandButton(
            //         'View Fees',
            //         Icons.attach_money,
            //         () => _handleViewFees(),
            //       ),
            //       _buildCommandButton(
            //         'Admissions Info',
            //         Icons.info,
            //         () => _handleAdmissionsInfo(),
            //       ),
            //       _buildCommandButton(
            //         'Ask Questions',
            //         Icons.help,
            //         () => _handleAskQuestions(),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandButton(
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
