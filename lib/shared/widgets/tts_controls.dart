import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/tts_service.dart';

/// Widget for controlling Text-to-Speech settings and playback
class TTSControls extends StatefulWidget {
  const TTSControls({super.key});

  @override
  State<TTSControls> createState() => _TTSControlsState();
}

class _TTSControlsState extends State<TTSControls> {
  late TTSService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = context.read<TTSService>();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          // Main TTS Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Stop Button
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.stop,
                    label: 'Stop',
                    onPressed: _ttsService.isSpeaking
                        ? () => _ttsService.stop()
                        : null,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 8),

                // Pause Button
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.pause,
                    label: 'Pause',
                    onPressed: _ttsService.isSpeaking && !_ttsService.isPaused
                        ? () => _ttsService.pause()
                        : null,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 8),

                // Settings Button
                Expanded(
                  child: _buildControlButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onPressed: () => _showSettingsBottomSheet(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show TTS settings in a bottom sheet
  void _showSettingsBottomSheet() {
    // Announce to screen readers
    _ttsService.speak(
      'Opening speech settings. You can adjust speech rate, volume, and pitch.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsBottomSheet(ttsService: _ttsService),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    String semanticLabel;
    String semanticHint;

    switch (label.toLowerCase()) {
      case 'stop':
        semanticLabel =
            'Stop speech. Stop the current text-to-speech playback.';
        semanticHint = 'Double tap to stop speaking';
        break;
      case 'pause':
        semanticLabel =
            'Pause speech. Pause the current text-to-speech playback.';
        semanticHint = 'Double tap to pause speaking';
        break;
      case 'settings':
        semanticLabel =
            'Speech settings. Open text-to-speech configuration options.';
        semanticHint = 'Double tap to open speech settings';
        break;
      default:
        semanticLabel = '$label button';
        semanticHint = 'Double tap to $label';
    }

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed != null ? color : Colors.grey,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: Icon(icon, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet widget for TTS settings
class _SettingsBottomSheet extends StatefulWidget {
  final TTSService ttsService;

  const _SettingsBottomSheet({required this.ttsService});

  @override
  State<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<_SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Speech Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Speech Rate Slider
          _buildSlider(
            label: 'Speech Rate',
            value: widget.ttsService.speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) {
              widget.ttsService.setSpeechRate(value);
              setState(() {});
            },
            valueLabel: '${(widget.ttsService.speechRate * 100).round()}%',
          ),

          // Volume Slider
          _buildSlider(
            label: 'Volume',
            value: widget.ttsService.volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              widget.ttsService.setVolume(value);
              setState(() {});
            },
            valueLabel: '${(widget.ttsService.volume * 100).round()}%',
          ),

          // Pitch Slider
          _buildSlider(
            label: 'Pitch',
            value: widget.ttsService.pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              widget.ttsService.setPitch(value);
              setState(() {});
            },
            valueLabel: '${widget.ttsService.pitch.toStringAsFixed(1)}x',
          ),

          const SizedBox(height: 24),

          // Test Speech Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.ttsService.speak(
                  'This is a test of your speech settings. '
                  'Speech rate is ${(widget.ttsService.speechRate * 100).round()} percent, '
                  'volume is ${(widget.ttsService.volume * 100).round()} percent, '
                  'and pitch is ${widget.ttsService.pitch.toStringAsFixed(1)} times normal.',
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Speech Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.ttsService.speak(
                  'Speech settings closed. Settings have been saved.',
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
