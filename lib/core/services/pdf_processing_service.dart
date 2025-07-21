import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for processing PDF files and extracting text content
class PDFProcessingService {
  static final PDFProcessingService _instance =
      PDFProcessingService._internal();
  factory PDFProcessingService() => _instance;
  PDFProcessingService._internal();

  /// Extract text from PDF file
  Future<String> extractTextFromPDF(File pdfFile) async {
    try {
      if (kDebugMode)
        print('Starting PDF text extraction from: ${pdfFile.path}');

      // Read PDF file as bytes
      final Uint8List pdfBytes = await pdfFile.readAsBytes();

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages
      final StringBuffer extractedText = StringBuffer();

      // Create text extractor
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.trim().isNotEmpty) {
          extractedText.writeln('--- Page ${i + 1} ---');
          extractedText.writeln(pageText);
          extractedText.writeln();
        }

        if (kDebugMode)
          print(
            'Extracted text from page ${i + 1}: ${pageText.length} characters',
          );
      }

      // Dispose the document
      document.dispose();

      final String fullText = extractedText.toString();
      if (kDebugMode)
        print('Total extracted text: ${fullText.length} characters');

      return fullText;
    } catch (e) {
      if (kDebugMode) print('Error extracting text from PDF: $e');
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from PDF bytes (for web uploads)
  Future<String> extractTextFromPDFBytes(Uint8List pdfBytes) async {
    try {
      if (kDebugMode)
        print(
          'Starting PDF text extraction from bytes: ${pdfBytes.length} bytes',
        );

      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages
      final StringBuffer extractedText = StringBuffer();

      // Create text extractor
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.trim().isNotEmpty) {
          extractedText.writeln('--- Page ${i + 1} ---');
          extractedText.writeln(pageText);
          extractedText.writeln();
        }

        if (kDebugMode)
          print(
            'Extracted text from page ${i + 1}: ${pageText.length} characters',
          );
      }

      // Dispose the document
      document.dispose();

      final String fullText = extractedText.toString();
      if (kDebugMode)
        print('Total extracted text: ${fullText.length} characters');

      return fullText;
    } catch (e) {
      if (kDebugMode) print('Error extracting text from PDF bytes: $e');
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Parse extracted text and categorize content
  ProspectusParseResult parseProspectusContent(String extractedText) {
    try {
      if (kDebugMode) print('Starting content parsing and categorization');

      final result = ProspectusParseResult();
      final lines = extractedText.split('\n');

      String currentSection = '';
      final StringBuffer currentContent = StringBuffer();

      for (String line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;

        // Skip page markers
        if (cleanLine.startsWith('--- Page ') && cleanLine.endsWith(' ---')) {
          continue;
        }

        // Detect section headers
        final sectionType = _detectSectionType(cleanLine);

        if (sectionType != null) {
          // Save previous section
          if (currentSection.isNotEmpty &&
              currentContent.toString().trim().isNotEmpty) {
            _addContentToResult(
              result,
              currentSection,
              currentContent.toString().trim(),
            );
          }

          // Start new section
          currentSection = sectionType;
          currentContent.clear();
          currentContent.writeln(cleanLine);
        } else {
          // Add to current section
          currentContent.writeln(cleanLine);
        }
      }

      // Add final section
      if (currentSection.isNotEmpty &&
          currentContent.toString().trim().isNotEmpty) {
        _addContentToResult(
          result,
          currentSection,
          currentContent.toString().trim(),
        );
      }

      // Extract specific information
      _extractPrograms(result, extractedText);
      _extractFees(result, extractedText);
      _extractAdmissions(result, extractedText);

      if (kDebugMode) {
        print('Parsing completed:');
        print('- Programs: ${result.programs.length}');
        print('- Fee structures: ${result.feeStructures.length}');
        print('- Admission info: ${result.admissionInfo.length}');
        print('- General content: ${result.generalContent.length}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('Error parsing prospectus content: $e');
      throw Exception('Failed to parse prospectus content: $e');
    }
  }

  /// Detect section type from line content
  String? _detectSectionType(String line) {
    final lowerLine = line.toLowerCase();

    // Program/Course sections
    if (lowerLine.contains('bachelor') ||
        lowerLine.contains('diploma') ||
        lowerLine.contains('certificate') ||
        lowerLine.contains('program') ||
        lowerLine.contains('course')) {
      return 'programs';
    }

    // Fee sections
    if (lowerLine.contains('fee') ||
        lowerLine.contains('cost') ||
        lowerLine.contains('tuition') ||
        lowerLine.contains('payment')) {
      return 'fees';
    }

    // Admission sections
    if (lowerLine.contains('admission') ||
        lowerLine.contains('entry') ||
        lowerLine.contains('requirement') ||
        lowerLine.contains('application')) {
      return 'admissions';
    }

    // General information
    if (lowerLine.contains('about') ||
        lowerLine.contains('introduction') ||
        lowerLine.contains('overview')) {
      return 'general';
    }

    return null;
  }

  /// Add content to appropriate result category
  void _addContentToResult(
    ProspectusParseResult result,
    String section,
    String content,
  ) {
    switch (section) {
      case 'programs':
        result.programsText.add(content);
        break;
      case 'fees':
        result.feesText.add(content);
        break;
      case 'admissions':
        result.admissionsText.add(content);
        break;
      case 'general':
      default:
        result.generalContent.add(content);
        break;
    }
  }

  /// Extract program information using advanced pattern matching
  void _extractPrograms(ProspectusParseResult result, String text) {
    if (kDebugMode) print('🔍 Starting advanced program extraction...');

    // Split text into lines for better analysis
    final lines = text.split('\n');
    final programs = <Map<String, dynamic>>[];

    // Enhanced program patterns with better name capture
    final programPatterns = [
      // Bachelor programs - improved to capture full names
      RegExp(
        r'Bachelor\s+of\s+([A-Za-z\s&\-]+?)(?:\s*\([^)]*\))?(?:\s*[-–]|\s*\n|\s*$)',
        caseSensitive: false,
      ),
      RegExp(r'Bachelor\s+of\s+([A-Za-z\s&\-]+)', caseSensitive: false),

      // Diploma programs
      RegExp(
        r'Diploma\s+in\s+([A-Za-z\s&\-]+?)(?:\s*\([^)]*\))?(?:\s*[-–]|\s*\n|\s*$)',
        caseSensitive: false,
      ),
      RegExp(r'Diploma\s+in\s+([A-Za-z\s&\-]+)', caseSensitive: false),

      // Certificate programs
      RegExp(
        r'Certificate\s+in\s+([A-Za-z\s&\-]+?)(?:\s*\([^)]*\))?(?:\s*[-–]|\s*\n|\s*$)',
        caseSensitive: false,
      ),
      RegExp(r'Certificate\s+in\s+([A-Za-z\s&\-]+)', caseSensitive: false),

      // Master's programs
      RegExp(
        r'Master\s+of\s+([A-Za-z\s&\-]+?)(?:\s*\([^)]*\))?(?:\s*[-–]|\s*\n|\s*$)',
        caseSensitive: false,
      ),
      RegExp(r'Master\s+of\s+([A-Za-z\s&\-]+)', caseSensitive: false),
    ];

    // Track processed programs to avoid duplicates
    final processedPrograms = <String>{};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      for (final pattern in programPatterns) {
        final matches = pattern.allMatches(line);

        for (final match in matches) {
          final fullMatch = match.group(0)?.trim();
          final programField = match.group(1)?.trim();

          if (fullMatch != null &&
              programField != null &&
              fullMatch.length > 5) {
            // Build complete program name
            String programName = _buildCompleteProgramName(
              fullMatch,
              programField,
            );

            // Skip if already processed or invalid
            if (processedPrograms.contains(programName.toLowerCase()) ||
                programName.length < 10)
              continue;
            processedPrograms.add(programName.toLowerCase());

            // Determine program type and category
            final programType = _determineProgramType(programName);
            final faculty = _extractFaculty(text, programName, i, lines);
            final duration = _extractDuration(text, programName, i, lines);
            final requirements = _extractRequirements(
              text,
              programName,
              i,
              lines,
            );
            final description = _extractDescription(
              text,
              programName,
              i,
              lines,
            );
            final fee = _extractProgramFee(text, programName);
            final careerOpportunities = _extractCareerOpportunities(
              text,
              programName,
              i,
              lines,
            );

            // Create structured program data
            final programData = {
              'id':
                  'prog_${DateTime.now().millisecondsSinceEpoch}_${programs.length}',
              'name': programName,
              'description': description.isNotEmpty
                  ? description
                  : _generateDefaultDescription(programName, programType),
              'duration': duration.isNotEmpty
                  ? duration
                  : _getDefaultDuration(programType),
              'requirements': requirements,
              'category': programType,
              'faculty': faculty.isNotEmpty
                  ? faculty
                  : _getDefaultFaculty(programName),
              'fee': fee,
              'careerOpportunities': careerOpportunities,
            };

            programs.add(programData);

            if (kDebugMode) {
              print('✅ Extracted program: $programName');
              print(
                '   Type: $programType, Faculty: ${programData['faculty']}',
              );
              print(
                '   Duration: ${programData['duration']}, Fee: ${programData['fee']}',
              );
            }
          }
        }
      }
    }

    // Add programs to result
    result.programs.addAll(programs);

    if (kDebugMode) {
      print(
        '🎓 Program extraction completed: ${programs.length} programs found',
      );
      for (final program in programs) {
        print('  - ${program['name']} (${program['category']})');
      }
    }
  }

  /// Build complete program name from extracted parts
  String _buildCompleteProgramName(String fullMatch, String programField) {
    // Clean the full match first
    String cleanMatch = fullMatch
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .replaceAll(RegExp(r'[^\w\s&\-\(\)]'), '') // Keep essential chars
        .trim();

    // If the match seems complete, use it
    if (cleanMatch.length > programField.length + 5) {
      return cleanMatch;
    }

    // Otherwise, build from the program field
    String cleanField = programField.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Determine the program type prefix
    String prefix = '';
    if (fullMatch.toLowerCase().contains('bachelor')) {
      prefix = 'Bachelor of ';
    } else if (fullMatch.toLowerCase().contains('diploma')) {
      prefix = 'Diploma in ';
    } else if (fullMatch.toLowerCase().contains('certificate')) {
      prefix = 'Certificate in ';
    } else if (fullMatch.toLowerCase().contains('master')) {
      prefix = 'Master of ';
    }

    return (prefix + cleanField).trim();
  }

  /// Generate a meaningful default description
  String _generateDefaultDescription(String programName, String programType) {
    final field = programName.toLowerCase();

    if (field.contains('computer') || field.contains('software')) {
      return 'A comprehensive program covering software development, computer systems, programming, and technology solutions. Students learn modern computing techniques and prepare for careers in the technology industry.';
    } else if (field.contains('engineering')) {
      return 'A rigorous engineering program that combines theoretical knowledge with practical application. Students develop problem-solving skills and technical expertise in their chosen engineering discipline.';
    } else if (field.contains('business') || field.contains('management')) {
      return 'A dynamic business program that covers management principles, entrepreneurship, and business strategy. Students develop leadership skills and business acumen for the modern marketplace.';
    } else if (field.contains('education') || field.contains('teaching')) {
      return 'A comprehensive education program that prepares future teachers and education professionals. Students learn pedagogical methods, curriculum development, and educational psychology.';
    } else if (field.contains('health') || field.contains('medical')) {
      return 'A healthcare-focused program that combines medical knowledge with practical skills. Students prepare for careers in health services and medical practice.';
    } else if (field.contains('agriculture') || field.contains('farming')) {
      return 'An agricultural program that covers modern farming techniques, crop management, and sustainable agriculture. Students learn to address food security and agricultural challenges.';
    }

    return 'A comprehensive $programType program that provides students with theoretical knowledge and practical skills in their chosen field of study.';
  }

  /// Determine program type from name
  String _determineProgramType(String programName) {
    final lower = programName.toLowerCase();
    if (lower.contains('bachelor') ||
        lower.startsWith('b.') ||
        lower.startsWith('b ')) {
      return 'Bachelor';
    } else if (lower.contains('master') ||
        lower.startsWith('m.') ||
        lower.startsWith('m ')) {
      return 'Master';
    } else if (lower.contains('diploma') || lower.startsWith('dip')) {
      return 'Diploma';
    } else if (lower.contains('certificate') || lower.startsWith('cert')) {
      return 'Certificate';
    } else if (lower.contains('phd') || lower.contains('doctorate')) {
      return 'PhD';
    }
    return 'Bachelor'; // Default
  }

  /// Extract faculty information for a program
  String _extractFaculty(
    String text,
    String programName,
    int lineIndex,
    List<String> lines,
  ) {
    // Look for faculty mentions near the program
    final facultyPatterns = [
      RegExp(r'faculty\s+of\s+([^.\n]+)', caseSensitive: false),
      RegExp(r'school\s+of\s+([^.\n]+)', caseSensitive: false),
      RegExp(r'department\s+of\s+([^.\n]+)', caseSensitive: false),
    ];

    // Search in nearby lines (±5 lines from program mention)
    final searchStart = (lineIndex - 5).clamp(0, lines.length - 1);
    final searchEnd = (lineIndex + 5).clamp(0, lines.length - 1);

    for (int i = searchStart; i <= searchEnd; i++) {
      final line = lines[i].toLowerCase();
      for (final pattern in facultyPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return _capitalizeWords(match.group(1)?.trim() ?? '');
        }
      }
    }

    return _getDefaultFaculty(programName);
  }

  /// Extract duration information
  String _extractDuration(
    String text,
    String programName,
    int lineIndex,
    List<String> lines,
  ) {
    // Look for duration patterns near the program
    final durationPatterns = [
      RegExp(r'(\d+)\s*years?', caseSensitive: false),
      RegExp(r'(\d+)\s*months?', caseSensitive: false),
      RegExp(r'duration[:\s]*(\d+\s*(?:years?|months?))', caseSensitive: false),
    ];

    // Search in nearby lines
    final searchStart = (lineIndex - 3).clamp(0, lines.length - 1);
    final searchEnd = (lineIndex + 10).clamp(0, lines.length - 1);

    for (int i = searchStart; i <= searchEnd; i++) {
      final line = lines[i].toLowerCase();
      for (final pattern in durationPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(0)?.trim() ?? '';
        }
      }
    }

    return _getDefaultDuration(_determineProgramType(programName));
  }

  /// Extract requirements for a program
  List<String> _extractRequirements(
    String text,
    String programName,
    int lineIndex,
    List<String> lines,
  ) {
    final requirements = <String>[];

    // Look for requirement patterns near the program
    final requirementPatterns = [
      RegExp(r'requirements?[:\s]*([^.\n]+)', caseSensitive: false),
      RegExp(r'entry\s+requirements?[:\s]*([^.\n]+)', caseSensitive: false),
      RegExp(r'admission\s+requirements?[:\s]*([^.\n]+)', caseSensitive: false),
      RegExp(r'form\s+(\d+)', caseSensitive: false),
      RegExp(r'([A-Z]+)\s+level', caseSensitive: false),
      RegExp(r'(\d+)\s+principal\s+passes?', caseSensitive: false),
    ];

    // Search in nearby lines (±10 lines from program mention)
    final searchStart = (lineIndex - 5).clamp(0, lines.length - 1);
    final searchEnd = (lineIndex + 15).clamp(0, lines.length - 1);

    for (int i = searchStart; i <= searchEnd; i++) {
      final line = lines[i];
      for (final pattern in requirementPatterns) {
        final matches = pattern.allMatches(line);
        for (final match in matches) {
          final requirement = match.group(0)?.trim();
          if (requirement != null && requirement.length > 3) {
            requirements.add(_capitalizeWords(requirement));
          }
        }
      }
    }

    // Add specific default requirements if none found
    if (requirements.isEmpty) {
      final programType = _determineProgramType(programName);
      requirements.addAll(_getDefaultRequirements(programType));
    } else if (requirements.length == 1 &&
        requirements[0].toLowerCase().contains('requirements as specified')) {
      // Replace generic requirement with specific ones
      requirements.clear();
      final programType = _determineProgramType(programName);
      requirements.addAll(_getDefaultRequirements(programType));
    }

    return requirements.take(5).toList(); // Limit to 5 requirements
  }

  /// Extract description for a program
  String _extractDescription(
    String text,
    String programName,
    int lineIndex,
    List<String> lines,
  ) {
    // Look for description patterns near the program
    final descriptionPatterns = [
      RegExp(r'description[:\s]*([^.\n]{20,})', caseSensitive: false),
      RegExp(r'overview[:\s]*([^.\n]{20,})', caseSensitive: false),
      RegExp(r'about[:\s]*([^.\n]{20,})', caseSensitive: false),
    ];

    // Search in nearby lines
    final searchStart = (lineIndex + 1).clamp(0, lines.length - 1);
    final searchEnd = (lineIndex + 10).clamp(0, lines.length - 1);

    for (int i = searchStart; i <= searchEnd; i++) {
      final line = lines[i];
      for (final pattern in descriptionPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final description = match.group(1)?.trim();
          if (description != null && description.length > 20) {
            return description;
          }
        }
      }

      // If line looks like a description (long sentence)
      if (line.length > 50 && line.contains(' ') && !line.contains(':')) {
        return line.trim();
      }
    }

    return '';
  }

  /// Extract program-specific fee
  double _extractProgramFee(String text, String programName) {
    // Look for fee patterns near the program name
    final feePatterns = [
      RegExp(
        r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:TZS|Tsh|shillings?)',
        caseSensitive: false,
      ),
      RegExp(r'fee[:\s]*(\d{1,3}(?:,\d{3})*)', caseSensitive: false),
      RegExp(r'cost[:\s]*(\d{1,3}(?:,\d{3})*)', caseSensitive: false),
    ];

    // Search for fees in context of this program
    final programContext = text.toLowerCase();
    final programIndex = programContext.indexOf(programName.toLowerCase());

    if (programIndex != -1) {
      // Look in 500 characters around the program mention
      final start = (programIndex - 250).clamp(0, text.length);
      final end = (programIndex + 250).clamp(0, text.length);
      final contextText = text.substring(start, end);

      for (final pattern in feePatterns) {
        final match = pattern.firstMatch(contextText);
        if (match != null) {
          final feeString = match.group(1)?.replaceAll(',', '');
          final fee = double.tryParse(feeString ?? '');
          if (fee != null && fee > 0) {
            return fee;
          }
        }
      }
    }

    // Return default fee based on program type
    final programType = _determineProgramType(programName);
    return _getDefaultFee(programType);
  }

  /// Extract career opportunities
  List<String> _extractCareerOpportunities(
    String text,
    String programName,
    int lineIndex,
    List<String> lines,
  ) {
    final careers = <String>[];

    // Look for career patterns
    final careerPatterns = [
      RegExp(r'career\s+opportunities?[:\s]*([^.\n]+)', caseSensitive: false),
      RegExp(
        r'employment\s+opportunities?[:\s]*([^.\n]+)',
        caseSensitive: false,
      ),
      RegExp(r'job\s+opportunities?[:\s]*([^.\n]+)', caseSensitive: false),
      RegExp(
        r'graduates\s+can\s+work\s+as[:\s]*([^.\n]+)',
        caseSensitive: false,
      ),
    ];

    // Search in nearby lines
    final searchStart = (lineIndex + 1).clamp(0, lines.length - 1);
    final searchEnd = (lineIndex + 20).clamp(0, lines.length - 1);

    for (int i = searchStart; i <= searchEnd; i++) {
      final line = lines[i];
      for (final pattern in careerPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final careerText = match.group(1)?.trim();
          if (careerText != null) {
            // Split by common separators
            final careerList = careerText.split(RegExp(r'[,;]|\sand\s'));
            for (final career in careerList) {
              final cleanCareer = career.trim();
              if (cleanCareer.length > 3) {
                careers.add(_capitalizeWords(cleanCareer));
              }
            }
          }
        }
      }
    }

    // Add default careers if none found
    if (careers.isEmpty) {
      careers.addAll(_getDefaultCareers(programName));
    }

    return careers.take(5).toList(); // Limit to 5 careers
  }

  /// Extract fee information using pattern matching
  void _extractFees(ProspectusParseResult result, String text) {
    // Pattern for fees (numbers with currency indicators)
    final feePattern = RegExp(
      r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:TZS|Tsh|shillings?)',
      caseSensitive: false,
    );
    final matches = feePattern.allMatches(text);

    for (final match in matches) {
      final feeAmount = match.group(1)?.replaceAll(',', '');
      if (feeAmount != null) {
        result.feeStructures.add({
          'amount': double.tryParse(feeAmount) ?? 0.0,
          'currency': 'TZS',
          'description': 'Fee extracted from prospectus',
        });
      }
    }
  }

  /// Extract admission information
  void _extractAdmissions(ProspectusParseResult result, String text) {
    // Look for admission requirements patterns
    final admissionPatterns = [
      RegExp(r'Form\s+[46]\s+[^.\n]*', caseSensitive: false),
      RegExp(r'[AB]?\s*Level\s+[^.\n]*', caseSensitive: false),
      RegExp(r'GPA\s+[^.\n]*', caseSensitive: false),
    ];

    for (final pattern in admissionPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final requirement = match.group(0)?.trim();
        if (requirement != null && requirement.isNotEmpty) {
          result.admissionInfo.add({
            'requirement': requirement,
            'type': 'general',
          });
        }
      }
    }
  }

  /// Helper method to capitalize words
  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Get default duration based on program type
  String _getDefaultDuration(String programType) {
    switch (programType.toLowerCase()) {
      case 'bachelor':
        return '3 years';
      case 'master':
        return '2 years';
      case 'diploma':
        return '2 years';
      case 'certificate':
        return '1 year';
      case 'phd':
        return '4 years';
      default:
        return '3 years';
    }
  }

  /// Get default faculty based on program name
  String _getDefaultFaculty(String programName) {
    final lower = programName.toLowerCase();

    if (lower.contains('computer') ||
        lower.contains('software') ||
        lower.contains('information')) {
      return 'Engineering and Technology';
    } else if (lower.contains('business') ||
        lower.contains('management') ||
        lower.contains('accounting')) {
      return 'Business and Management';
    } else if (lower.contains('education') || lower.contains('teaching')) {
      return 'Education';
    } else if (lower.contains('health') ||
        lower.contains('medical') ||
        lower.contains('nursing')) {
      return 'Health Sciences';
    } else if (lower.contains('law') || lower.contains('legal')) {
      return 'Law';
    } else if (lower.contains('agriculture') || lower.contains('farming')) {
      return 'Agriculture';
    } else if (lower.contains('engineering') ||
        lower.contains('mechanical') ||
        lower.contains('civil')) {
      return 'Engineering and Technology';
    }

    return 'General Studies';
  }

  /// Get default requirements based on program type
  List<String> _getDefaultRequirements(String programType) {
    switch (programType.toLowerCase()) {
      case 'bachelor':
        return [
          'Form 6 with 2 principal passes',
          'Mathematics and English',
          'Relevant A-level subjects',
        ];
      case 'master':
        return [
          'Bachelor\'s degree in relevant field',
          'Minimum GPA of 2.7',
          'Work experience preferred',
        ];
      case 'diploma':
        return [
          'Form 4 with Division I-III',
          'Mathematics and English',
          'Relevant O-level subjects',
        ];
      case 'certificate':
        return ['Form 4 completion', 'Basic literacy and numeracy'];
      default:
        return ['Form 6 completion', 'Relevant academic background'];
    }
  }

  /// Get default fee based on program type
  double _getDefaultFee(String programType) {
    switch (programType.toLowerCase()) {
      case 'bachelor':
        return 2500000.0; // 2.5M TZS
      case 'master':
        return 3500000.0; // 3.5M TZS
      case 'diploma':
        return 1800000.0; // 1.8M TZS
      case 'certificate':
        return 1200000.0; // 1.2M TZS
      case 'phd':
        return 5000000.0; // 5M TZS
      default:
        return 2500000.0;
    }
  }

  /// Get default career opportunities based on program name
  List<String> _getDefaultCareers(String programName) {
    final lower = programName.toLowerCase();

    if (lower.contains('computer') || lower.contains('software')) {
      return [
        'Software Developer',
        'System Analyst',
        'IT Consultant',
        'Database Administrator',
        'Web Developer',
      ];
    } else if (lower.contains('business') || lower.contains('management')) {
      return [
        'Business Manager',
        'Project Manager',
        'Business Analyst',
        'Entrepreneur',
        'Consultant',
      ];
    } else if (lower.contains('accounting')) {
      return [
        'Accountant',
        'Auditor',
        'Financial Analyst',
        'Tax Consultant',
        'Budget Analyst',
      ];
    } else if (lower.contains('education') || lower.contains('teaching')) {
      return [
        'Teacher',
        'Education Administrator',
        'Curriculum Developer',
        'Education Consultant',
        'Training Coordinator',
      ];
    } else if (lower.contains('engineering')) {
      return [
        'Engineer',
        'Project Engineer',
        'Technical Consultant',
        'Design Engineer',
        'Quality Assurance Engineer',
      ];
    }

    return [
      'Professional in the field',
      'Consultant',
      'Manager',
      'Specialist',
      'Researcher',
    ];
  }
}

/// Result class for parsed prospectus content
class ProspectusParseResult {
  final List<String> programsText = [];
  final List<String> feesText = [];
  final List<String> admissionsText = [];
  final List<String> generalContent = [];

  final List<Map<String, dynamic>> programs = [];
  final List<Map<String, dynamic>> feeStructures = [];
  final List<Map<String, dynamic>> admissionInfo = [];

  /// Get all extracted text as a single string
  String get allText {
    final buffer = StringBuffer();

    if (programsText.isNotEmpty) {
      buffer.writeln('=== PROGRAMS ===');
      buffer.writeln(programsText.join('\n\n'));
      buffer.writeln();
    }

    if (feesText.isNotEmpty) {
      buffer.writeln('=== FEES ===');
      buffer.writeln(feesText.join('\n\n'));
      buffer.writeln();
    }

    if (admissionsText.isNotEmpty) {
      buffer.writeln('=== ADMISSIONS ===');
      buffer.writeln(admissionsText.join('\n\n'));
      buffer.writeln();
    }

    if (generalContent.isNotEmpty) {
      buffer.writeln('=== GENERAL INFORMATION ===');
      buffer.writeln(generalContent.join('\n\n'));
    }

    return buffer.toString();
  }

  /// Check if parsing found any content
  bool get hasContent {
    return programsText.isNotEmpty ||
        feesText.isNotEmpty ||
        admissionsText.isNotEmpty ||
        generalContent.isNotEmpty;
  }
}
