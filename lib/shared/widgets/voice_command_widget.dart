import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/tts_service.dart';

/// Enhanced voice command widget with visual feedback and help
class VoiceCommandWidget extends StatefulWidget {
  final Function(String) onCommand;
  final bool enabled;

  const VoiceCommandWidget({
    super.key,
    required this.onCommand,
    this.enabled = true,
  });

  @override
  State<VoiceCommandWidget> createState() => _VoiceCommandWidgetState();
}

class _VoiceCommandWidgetState extends State<VoiceCommandWidget>
    with TickerProviderStateMixin {
  late SpeechService _speechService;
  late TTSService _ttsService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  String _lastRecognizedText = '';
  double _confidence = 0.0;
  String _status = 'Ready to listen';

  @override
  void initState() {
    super.initState();
    _speechService = context.read<SpeechService>();
    _ttsService = context.read<TTSService>();

    // Setup pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start listening after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(
        const Duration(milliseconds: 3000),
      ); // Wait for welcome message
      if (widget.enabled && mounted) {
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!widget.enabled || !_speechService.isAvailable) {
      _updateStatus('Speech recognition not available');
      await _ttsService.speak(
        'Speech recognition is not available on this device.',
      );
      return;
    }

    setState(() {
      _isListening = true;
      _status = 'Listening... Say a command';
      _lastRecognizedText = '';
      _confidence = 0.0;
    });

    _pulseController.repeat(reverse: true);
    await _ttsService.speak('I\'m listening. What would you like to know?');

    await _speechService.startListening(
      onResult: (command) {
        _handleVoiceResult(command);
      },
      onError: (error) {
        _handleError(error);
      },
      onListeningStart: () {
        setState(() {
          _isListening = true;
          _status = 'Listening...';
        });
      },
      onListeningStop: () {
        _stopListening();
      },
    );
  }

  void _stopListening() {
    _speechService.stopListening();
    _pulseController.stop();
    setState(() {
      _isListening = false;
      _status = _lastRecognizedText.isNotEmpty
          ? 'Processing: "$_lastRecognizedText"'
          : 'Ready to listen';
    });
  }

  void _handleVoiceResult(String command) {
    setState(() {
      _lastRecognizedText = _speechService.lastWords;
      _confidence = _speechService.confidence;
    });

    if (command.isNotEmpty) {
      // Filter out TTS feedback loops
      final cleanCommand = command.toLowerCase().trim();

      // Ignore TTS feedback and system messages
      if (_shouldIgnoreCommand(cleanCommand)) {
        if (kDebugMode) {
          print('🔇 Ignoring TTS feedback: "$command"');
        }
        return; // Don't process TTS feedback as commands
      }

      _stopListening();
      widget.onCommand(command);

      // Auto-restart listening after processing command (for continuous voice interaction)
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (widget.enabled && mounted && !_isListening) {
          _startListening();
        }
      });
    }
  }

  /// Check if command should be ignored (TTS feedback, system messages, etc.)
  bool _shouldIgnoreCommand(String command) {
    final ignorePhrases = [
      'i am ready to answer',
      'i\'m ready to answer',
      'what would you like to know',
      'command received',
      'generating',
      'please wait',
      'processing',
      'let me find',
      'here is',
      'here are',
      'available programs',
      'fee structure',
      'welcome to vias',
      'voice listening',
      'say a command',
      'tap a button',
      'listening for',
      'speak your command',
      'voice commands are',
      'you can say',
      'powered by',
      'source found',
      'hugging face',
      'question mode activated',
      'ask me anything',
      'about the prospectus',
      'voice listening active',
      'ready for your command',
      'selected',
      'summarize pdf selected',
      'ask questions selected',
      'view programs selected',
      'check fees selected',
    ];

    // Check if command contains any ignore phrases
    for (final phrase in ignorePhrases) {
      if (command.contains(phrase)) {
        return true;
      }
    }

    // Ignore very short commands (likely noise)
    if (command.length < 3) {
      return true;
    }

    // Ignore commands that are mostly numbers or single words that don't make sense
    final words = command.split(' ');
    if (words.length == 1 && !_isValidSingleWordCommand(words[0])) {
      return true;
    }

    return false;
  }

  /// Check if single word is a valid command
  bool _isValidSingleWordCommand(String word) {
    final validSingleWords = [
      'help',
      'stop',
      'repeat',
      'pause',
      'continue',
      'programs',
      'fees',
      'questions',
      'summary',
    ];
    return validSingleWords.contains(word.toLowerCase());
  }

  void _handleError(String error) {
    _stopListening();
    _updateStatus('Error: $error');
  }

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  void _showVoiceHelp() async {
    final lang = _ttsService.languageCode;
    await _ttsService.speak(TTSService.translations[lang]!['help']!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Voice Status Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isListening
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Microphone Icon with Animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 48,
                          color: _isListening
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Status Text
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Recognition Feedback
                  if (_lastRecognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Heard: "$_lastRecognizedText"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_confidence > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _confidence > 0.7
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start/Stop Listening Button
                Expanded(
                  child: Semantics(
                    label: _isListening
                        ? 'Stop voice recognition. Currently listening for commands.'
                        : 'Start voice recognition. Tap to begin listening for voice commands.',
                    hint: _isListening
                        ? 'Double tap to stop listening'
                        : 'Double tap to start listening for voice commands',
                    button: true,
                    enabled: widget.enabled,
                    child: ElevatedButton.icon(
                      onPressed: widget.enabled
                          ? (_isListening ? _stopListening : _startListening)
                          : null,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(
                        _isListening ? 'Stop Listening' : 'Start Voice Command',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Help Button
                Semantics(
                  label:
                      'Voice help. Get information about available voice commands.',
                  hint: 'Double tap to hear list of available voice commands',
                  button: true,
                  child: ElevatedButton(
                    onPressed: _showVoiceHelp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.help),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quick Command Hints
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildCommandChip('Explore Programs'),
                _buildCommandChip('View Fees'),
                _buildCommandChip('Admissions Info'),
                _buildCommandChip('Ask Questions'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String command) {
    return Semantics(
      label: 'Quick command: $command',
      hint: 'Double tap to execute $command voice command',
      button: true,
      child: ActionChip(
        label: Text(command, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          // Simulate voice command
          final commandKey = command.toLowerCase().replaceAll(' ', '_');
          widget.onCommand(commandKey);
        },
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
