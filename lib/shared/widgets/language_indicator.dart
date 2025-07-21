import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Language indicator widget showing current language
/// Accessible for visually impaired users with voice feedback
class LanguageIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;
  
  const LanguageIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: languageProvider.isSwahili 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: languageProvider.isSwahili 
                  ? Colors.green 
                  : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: iconSize,
                color: languageProvider.isSwahili 
                    ? Colors.green 
                    : Colors.blue,
              ),
              if (showText) ...[
                const SizedBox(width: 8),
                Text(
                  languageProvider.isSwahili ? 'Kiswahili' : 'English',
                  style: TextStyle(
                    color: languageProvider.isSwahili 
                        ? Colors.green 
                        : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Voice command help overlay for language switching
class LanguageHelpOverlay extends StatelessWidget {
  final VoidCallback onClose;
  
  const LanguageHelpOverlay({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final commands = languageProvider.getVoiceCommands();
        
        return Container(
          color: Colors.black.withValues(alpha: 0.8),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    languageProvider.isSwahili 
                        ? 'Amri za Sauti' 
                        : 'Voice Commands',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Commands list
                  Expanded(
                    child: ListView.builder(
                      itemCount: commands.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            commands[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Close button
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      languageProvider.isSwahili ? 'Funga' : 'Close',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
