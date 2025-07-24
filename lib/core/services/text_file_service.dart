import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for reading text files from the lib directory
class TextFileService {
  /// Read content from a text file in the assets
  static Future<String> readTextFile(String filename) async {
    try {
      if (kDebugMode) {
        print('📖 Reading text file: $filename');
      }

      // Read from assets (bundled with app)
      final content = await rootBundle.loadString('lib/$filename');
      if (kDebugMode) {
        print('✅ Successfully read from assets: ${content.length} characters');
      }
      return content;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading text file $filename: $e');
      }
      throw Exception('Could not find or read file: $filename. Error: $e');
    }
  }

  /// Get introduction content
  static Future<String> getIntroduction() async {
    try {
      return await readTextFile('intro.txt');
    } catch (e) {
      return 'Welcome to the Dar es Salaam Institute of Technology. I apologize, but the detailed introduction information is currently unavailable. Please contact the admissions office for more information.';
    }
  }

  /// Get academic programs content
  static Future<String> getAcademicPrograms() async {
    try {
      return await readTextFile('academic.txt');
    } catch (e) {
      return 'DIT offers various academic programs including Engineering, Technology, and Business programs. I apologize, but the detailed program information is currently unavailable. Please contact the academic office for more information.';
    }
  }

  /// Get admission regulations content
  static Future<String> getAdmissionRegulations() async {
    try {
      return await readTextFile('admission.txt');
    } catch (e) {
      return 'DIT has specific admission requirements for different programs. I apologize, but the detailed admission regulation information is currently unavailable. Please contact the admissions office for more information.';
    }
  }

  /// Get exam regulations content
  static Future<String> getExamRegulations() async {
    try {
      return await readTextFile('exam.txt');
    } catch (e) {
      return 'DIT has comprehensive examination regulations and procedures. I apologize, but the detailed exam regulation information is currently unavailable. Please contact the academic office for more information.';
    }
  }

  /// Get fees and financial requirements content
  static Future<String> getFeesAndFinancial() async {
    try {
      return await readTextFile('fees.txt');
    } catch (e) {
      return 'DIT has various fee structures for different programs and financial assistance options. I apologize, but the detailed fee information is currently unavailable. Please contact the finance office for more information.';
    }
  }

  /// Get profile and academic departments content
  static Future<String> getProfileAndDepartments() async {
    try {
      return await readTextFile('profile.txt');
    } catch (e) {
      return 'DIT has multiple academic departments offering specialized programs. I apologize, but the detailed department profile information is currently unavailable. Please contact the respective departments for more information.';
    }
  }

  /// Get programs content
  static Future<String> getPrograms() async {
    try {
      return await readTextFile('programs.txt');
    } catch (e) {
      return 'DIT offers various programs including Engineering, Technology, and Business programs at different levels. I apologize, but the detailed program information is currently unavailable. Please contact the academic office for more information.';
    }
  }

  /// Get content based on command keyword
  static Future<String> getContentByCommand(String command) async {
    final lowerCommand = command.toLowerCase().trim();

    if (kDebugMode) {
      print('🔍 Processing command: "$command" -> "$lowerCommand"');
    }

    if (lowerCommand.contains('introduction') ||
        lowerCommand.contains('utangulizi')) {
      if (kDebugMode) print('📖 Matched: introduction');
      return await getIntroduction();
    } else if ((lowerCommand.contains('academic') &&
            lowerCommand.contains('program')) ||
        (lowerCommand.contains('programu') &&
            lowerCommand.contains('kitaaluma'))) {
      if (kDebugMode) print('📖 Matched: academic programs');
      return await getAcademicPrograms();
    } else if ((lowerCommand.contains('list') &&
            lowerCommand.contains('program')) ||
        (lowerCommand.contains('orodha') &&
            lowerCommand.contains('programu')) ||
        lowerCommand.contains('programs') ||
        lowerCommand.contains('programu')) {
      if (kDebugMode) print('📖 Matched: list of programs');
      return await getPrograms();
    } else if (lowerCommand.contains('admission') &&
            lowerCommand.contains('regulation') ||
        lowerCommand.contains('kanuni') && lowerCommand.contains('kujiunga')) {
      if (kDebugMode) print('📖 Matched: admission regulation');
      return await getAdmissionRegulations();
    } else if (lowerCommand.contains('exam') &&
            lowerCommand.contains('regulation') ||
        lowerCommand.contains('kanuni') && lowerCommand.contains('mitihani')) {
      if (kDebugMode) print('📖 Matched: exam regulation');
      return await getExamRegulations();
    } else if (lowerCommand.contains('fees') &&
            lowerCommand.contains('financial') ||
        lowerCommand.contains('ada') && lowerCommand.contains('fedha')) {
      if (kDebugMode) print('📖 Matched: fees and financial');
      return await getFeesAndFinancial();
    } else if (lowerCommand.contains('profile') &&
            lowerCommand.contains('department') ||
        lowerCommand.contains('wasifu') && lowerCommand.contains('idara')) {
      if (kDebugMode) print('📖 Matched: profile and departments');
      return await getProfileAndDepartments();
    }

    if (kDebugMode) print('❌ No command match found for: "$command"');
    throw Exception('Unknown command: $command');
  }
}
