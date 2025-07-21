import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/prospectus_models.dart';
import 'pdf_processing_service.dart';
import '../utils/db_helper.dart';
import 'vercel_backend_service.dart';

/// Service for managing prospectus content and data
class ContentManagementService {
  static final ContentManagementService _instance =
      ContentManagementService._internal();
  factory ContentManagementService() => _instance;
  bool _offlineMode = false;
  ContentManagementService._internal() {
    _loadDataWithCache(); // Load from cache first, then Firestore
  }

  final PDFProcessingService _pdfService = PDFProcessingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory storage (will be replaced with Firebase later)
  final List<Program> _programs = [];
  final List<FeeStructure> _feeStructures = [];
  final List<AdmissionInfo> _admissionInfo = [];
  final List<ProspectusContent> _generalContent = [];

  // Getters for accessing data
  List<Program> get programs => List.unmodifiable(_programs);
  List<FeeStructure> get feeStructures => List.unmodifiable(_feeStructures);
  List<AdmissionInfo> get admissionInfo => List.unmodifiable(_admissionInfo);
  List<ProspectusContent> get generalContent =>
      List.unmodifiable(_generalContent);

  bool get isOffline => _offlineMode;

  /// Process PDF using Hugging Face AI-powered server
  Future<ProcessingResult> processPDFContent(
    dynamic pdfData,
    String fileName,
  ) async {
    try {
      if (kDebugMode)
        print('🤖 Processing PDF with Hugging Face AI: $fileName');

      // Use the backend service to process PDF with Hugging Face AI
      final backendService = VercelBackendService();
      Map<String, dynamic> result;

      if (pdfData is List<int>) {
        // Process PDF bytes
        result = await backendService.processPDFBytes(pdfData, fileName);
      } else {
        throw Exception(
          'Unsupported PDF data format. Expected List<int> bytes.',
        );
      }

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'PDF processing failed');
      }

      final chunks = result['chunks'] as List<dynamic>? ?? [];

      if (chunks.isEmpty) {
        throw Exception('No content could be extracted from the PDF');
      }

      if (kDebugMode) {
        print('✅ PDF processed successfully with Hugging Face AI');
        print('📄 Total chunks: ${chunks.length}');
        print('🤖 AI processing completed for intelligent search');
      }

      // Store chunks in Firestore for the Q&A system
      await _storeProcessedChunks(chunks, fileName);

      // IMPORTANT: Sync chunks back to backend memory for summarization
      await _syncChunksToBackend(chunks);

      // Create a legacy-compatible result for the UI
      final processingResult = ProcessingResult(
        success: true,
        message:
            'PDF processed successfully with AI integration. ${chunks.length} content chunks created.',
        extractedText: chunks.map((c) => c['text'] ?? '').join('\n\n'),
        parseResult: null, // Not used with Hugging Face AI approach
        structuredData: null, // Not used with Hugging Face AI approach
        aiProcessed: true,
        totalChunks: chunks.length,
      );

      return processingResult;
    } catch (e) {
      if (kDebugMode) print('❌ Error processing PDF with Hugging Face AI: $e');
      return ProcessingResult(
        success: false,
        message: 'Failed to process PDF: $e',
        error: e.toString(),
      );
    }
  }

  /// Store processed chunks in Firestore for Q&A system
  Future<void> _storeProcessedChunks(
    List<dynamic> chunks,
    String fileName,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final chunk in chunks) {
        final docRef = firestore
            .collection('prospectus_chunks')
            .doc(chunk['id']);
        batch.set(docRef, {
          'id': chunk['id'],
          'page': chunk['page'],
          'text': chunk['text'],
          'status': 'approved', // Auto-approve for local server
          'tag': chunk['tag'] ?? 'General',
          'filename': fileName,
          'timestamp': FieldValue.serverTimestamp(),
          'processedAt': DateTime.now().toIso8601String(),
          'aiProcessed': true,
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ Stored ${chunks.length} chunks in Firestore');
        print('🔍 Content is now available for AI-powered Q&A');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error storing chunks in Firestore: $e');
      rethrow;
    }
  }

  /// Sync processed chunks back to backend memory for summarization
  Future<void> _syncChunksToBackend(List<dynamic> chunks) async {
    try {
      if (kDebugMode)
        print('🔄 Syncing ${chunks.length} chunks to backend memory...');

      final backendService = VercelBackendService();
      final result = await backendService.syncFromFirestore(chunks);

      if (result['success'] == true) {
        if (kDebugMode) {
          print(
            '✅ Successfully synced ${chunks.length} chunks to backend memory',
          );
          print(
            '📋 Backend now has ${result['totalChunks']} chunks for summarization',
          );
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to sync to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing chunks to backend: $e');
        print('⚠️ Summarization may not work until backend is synced');
      }
      // Don't rethrow - this is not critical for the upload process
      // The content is still stored in Firestore for Q&A
    }
  }

  /// Convert parsed data to structured models
  Future<StructuredProspectusData> _convertToStructuredData(
    ProspectusParseResult parseResult,
    String sourceFileName,
  ) async {
    final structuredData = StructuredProspectusData();

    // Convert programs using the rich extracted data
    for (int i = 0; i < parseResult.programs.length; i++) {
      final programData = parseResult.programs[i];

      // Use the extracted data directly from the advanced parsing
      final program = Program(
        id:
            programData['id'] ??
            'prog_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: programData['name'] ?? 'Unknown Program',
        description:
            programData['description'] ??
            'Program description from $sourceFileName',
        duration: programData['duration'] ?? '3 years',
        requirements: List<String>.from(programData['requirements'] ?? []),
        category: programData['category'] ?? 'Unknown',
        faculty: programData['faculty'] ?? 'General Studies',
        fee: (programData['fee'] as num?)?.toDouble(),
        careerOpportunities: List<String>.from(
          programData['careerOpportunities'] ?? [],
        ),
      );

      structuredData.programs.add(program);

      if (kDebugMode) {
        print('✅ Converted program: ${program.name}');
        print('   Category: ${program.category}, Faculty: ${program.faculty}');
        print('   Duration: ${program.duration}, Fee: ${program.fee}');
        print('   Requirements: ${program.requirements.length}');
        print('   Career opportunities: ${program.careerOpportunities.length}');
      }
    }

    // Convert fee structures
    for (int i = 0; i < parseResult.feeStructures.length; i++) {
      final feeData = parseResult.feeStructures[i];
      final feeStructure = FeeStructure(
        id: 'fee_${DateTime.now().millisecondsSinceEpoch}_$i',
        programId: structuredData.programs.isNotEmpty
            ? structuredData.programs[0].id
            : '',
        programName: structuredData.programs.isNotEmpty
            ? structuredData.programs[0].name
            : 'General',
        tuitionFee: feeData['amount']?.toDouble() ?? 0.0,
        registrationFee: 0.0, // Will be enhanced with better parsing
        examinationFee: 0.0,
        otherFees: 0.0,
        currency: feeData['currency'] ?? 'TZS',
      );
      structuredData.feeStructures.add(feeStructure);
    }

    // Convert admission info
    for (int i = 0; i < parseResult.admissionInfo.length; i++) {
      final admissionData = parseResult.admissionInfo[i];
      final admission = AdmissionInfo(
        id: 'adm_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: 'Admission Requirements',
        description:
            admissionData['requirement'] ??
            'Admission requirement from $sourceFileName',
        generalRequirements: [admissionData['requirement'] ?? ''],
      );
      structuredData.admissionInfo.add(admission);
    }

    // Convert general content
    for (int i = 0; i < parseResult.generalContent.length; i++) {
      final content = parseResult.generalContent[i];
      final prospectusContent = ProspectusContent(
        id: 'content_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: 'General Information ${i + 1}',
        content: content,
        category: 'general',
        lastUpdated: DateTime.now(),
        tags: ['prospectus', 'general', sourceFileName.replaceAll('.pdf', '')],
      );
      structuredData.generalContent.add(prospectusContent);
    }

    return structuredData;
  }

  /// Store structured data in Firebase Firestore
  Future<void> _storeStructuredData(StructuredProspectusData data) async {
    try {
      // Store in Firebase Firestore
      final batch = _firestore.batch();

      // Clear existing data in Firestore
      await _clearFirestoreCollections();

      // Store programs
      for (final program in data.programs) {
        final docRef = _firestore.collection('programs').doc(program.id);
        batch.set(docRef, program.toMap());
      }

      // Store fee structures
      for (final fee in data.feeStructures) {
        final docRef = _firestore.collection('fee_structures').doc(fee.id);
        batch.set(docRef, fee.toMap());
      }

      // Store admission info
      for (final admission in data.admissionInfo) {
        final docRef = _firestore
            .collection('admission_info')
            .doc(admission.id);
        batch.set(docRef, admission.toMap());
      }

      // Store general content
      for (final content in data.generalContent) {
        final docRef = _firestore.collection('general_content').doc(content.id);
        batch.set(docRef, content.toMap());
      }

      // Store metadata
      final metadataRef = _firestore.collection('metadata').doc('content_info');
      batch.set(metadataRef, {
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalPrograms': data.programs.length,
        'totalFeeStructures': data.feeStructures.length,
        'totalAdmissionInfo': data.admissionInfo.length,
        'totalGeneralContent': data.generalContent.length,
      });

      // Commit the batch
      await batch.commit();

      // Update in-memory data
      _programs.clear();
      _feeStructures.clear();
      _admissionInfo.clear();
      _generalContent.clear();

      _programs.addAll(data.programs);
      _feeStructures.addAll(data.feeStructures);
      _admissionInfo.addAll(data.admissionInfo);
      _generalContent.addAll(data.generalContent);

      if (kDebugMode) {
        print('✅ Stored structured data in Firebase:');
        print('- Programs: ${data.programs.length}');
        print('- Fee structures: ${data.feeStructures.length}');
        print('- Admission info: ${data.admissionInfo.length}');
        print('- General content: ${data.generalContent.length}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error storing data in Firebase: $e');

      // Fallback to in-memory storage
      _programs.clear();
      _feeStructures.clear();
      _admissionInfo.clear();
      _generalContent.clear();

      _programs.addAll(data.programs);
      _feeStructures.addAll(data.feeStructures);
      _admissionInfo.addAll(data.admissionInfo);
      _generalContent.addAll(data.generalContent);

      if (kDebugMode) print('⚠️ Fallback: Stored data in memory only');
    }
  }

  /// Clear existing Firestore collections
  Future<void> _clearFirestoreCollections() async {
    try {
      final collections = [
        'programs',
        'fee_structures',
        'admission_info',
        'general_content',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      if (kDebugMode) print('🗑️ Cleared existing Firestore collections');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing Firestore collections: $e');
    }
  }

  /// Load data from Firestore on initialization
  Future<void> _loadDataFromFirestore() async {
    try {
      // Load programs
      final programsSnapshot = await _firestore.collection('programs').get();
      _programs.clear();
      for (final doc in programsSnapshot.docs) {
        _programs.add(Program.fromMap(doc.data()));
      }

      // Load fee structures
      final feesSnapshot = await _firestore.collection('fee_structures').get();
      _feeStructures.clear();
      for (final doc in feesSnapshot.docs) {
        _feeStructures.add(FeeStructure.fromMap(doc.data()));
      }

      // Load admission info
      final admissionSnapshot = await _firestore
          .collection('admission_info')
          .get();
      _admissionInfo.clear();
      for (final doc in admissionSnapshot.docs) {
        _admissionInfo.add(AdmissionInfo.fromMap(doc.data()));
      }

      // Load general content
      final contentSnapshot = await _firestore
          .collection('general_content')
          .get();
      _generalContent.clear();
      for (final doc in contentSnapshot.docs) {
        _generalContent.add(ProspectusContent.fromMap(doc.data()));
      }

      if (kDebugMode) {
        print('📥 Loaded data from Firebase:');
        print('- Programs: ${_programs.length}');
        print('- Fee structures: ${_feeStructures.length}');
        print('- Admission info: ${_admissionInfo.length}');
        print('- General content: ${_generalContent.length}');
      }
      // After loading, update local cache
      final db = DBHelper();
      await db.savePrograms(_programs);
      await db.saveFeeStructures(_feeStructures);
      await db.saveAdmissionInfo(_admissionInfo);
      await db.saveGeneralContent(_generalContent);
      if (kDebugMode) print('💾 Synced data to local cache');
      _offlineMode = false;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading data from Firebase: $e');
      _offlineMode = true;
    }
  }

  /// Load data from cache on initialization
  Future<void> _loadDataWithCache() async {
    try {
      // Load from local cache first
      final db = DBHelper();
      _programs.clear();
      _feeStructures.clear();
      _admissionInfo.clear();
      _generalContent.clear();
      _programs.addAll(await db.loadPrograms());
      _feeStructures.addAll(await db.loadFeeStructures());
      _admissionInfo.addAll(await db.loadAdmissionInfo());
      _generalContent.addAll(await db.loadGeneralContent());
      if (kDebugMode) print('📦 Loaded data from local cache');
      // Try to update from Firestore
      await _loadDataFromFirestore();
      _offlineMode = false;
    } catch (e) {
      if (kDebugMode)
        print('⚠️ Failed to load from Firestore, using cached data: $e');
      _offlineMode = true;
    }
  }

  /// Get file from path (placeholder for actual file handling)
  Future<dynamic> _getFileFromPath(String path) async {
    // This would be implemented based on the platform
    throw UnimplementedError('File path handling not implemented yet');
  }

  /// Search content by query
  List<dynamic> searchContent(String query) {
    final results = <dynamic>[];
    final lowerQuery = query.toLowerCase();

    // Search programs
    for (final program in _programs) {
      if (program.name.toLowerCase().contains(lowerQuery) ||
          program.description.toLowerCase().contains(lowerQuery)) {
        results.add(program);
      }
    }

    // Search general content
    for (final content in _generalContent) {
      if (content.title.toLowerCase().contains(lowerQuery) ||
          content.content.toLowerCase().contains(lowerQuery)) {
        results.add(content);
      }
    }

    return results;
  }

  /// Get content for voice reading
  String getContentForVoiceReading(String category) {
    switch (category.toLowerCase()) {
      case 'programs':
        return _programs.map((p) => p.toSpeechText()).join(' ');
      case 'fees':
        return _feeStructures.map((f) => f.toSpeechText()).join(' ');
      case 'admissions':
        return _admissionInfo.map((a) => a.toSpeechText()).join(' ');
      default:
        return _generalContent.map((c) => c.toSpeechText()).join(' ');
    }
  }
}

/// Result of PDF processing operation
class ProcessingResult {
  final bool success;
  final String message;
  final String? extractedText;
  final ProspectusParseResult? parseResult;
  final StructuredProspectusData? structuredData;
  final String? error;
  final bool aiProcessed;
  final int? totalChunks;

  ProcessingResult({
    required this.success,
    required this.message,
    this.extractedText,
    this.parseResult,
    this.structuredData,
    this.error,
    this.aiProcessed = false,
    this.totalChunks,
  });
}

/// Container for structured prospectus data
class StructuredProspectusData {
  final List<Program> programs = [];
  final List<FeeStructure> feeStructures = [];
  final List<AdmissionInfo> admissionInfo = [];
  final List<ProspectusContent> generalContent = [];

  bool get hasData {
    return programs.isNotEmpty ||
        feeStructures.isNotEmpty ||
        admissionInfo.isNotEmpty ||
        generalContent.isNotEmpty;
  }
}

class QnAService {
  // Use the same backend service as PDF processing
  static final _backendService = VercelBackendService();

  // Store conversation history for better context
  static final List<Map<String, String>> _conversationHistory = [];

  static Future<String> askQuestion(
    String question, {
    List<Map<String, String>>? history,
  }) async {
    try {
      // Use provided history or internal conversation history
      final conversationHistory = history ?? _conversationHistory;

      // Get all approved content chunks from Firestore
      final contentChunks = await _getAllContentChunks();

      // Use the Hugging Face AI-powered backend Q&A service
      final response = await _backendService.answerQuestion(
        question,
        contentChunks: contentChunks,
        history: conversationHistory,
      );

      final answer = response['answer'] ?? 'No answer found.';

      // Add to conversation history for context
      _conversationHistory.add({'question': question, 'answer': answer});

      // Keep only last 3 exchanges to manage memory
      if (_conversationHistory.length > 3) {
        _conversationHistory.removeAt(0);
      }

      return answer;
    } catch (e) {
      print('❌ Q&A Service error: $e');
      return 'Sorry, I encountered an error while processing your question. Please try again.';
    }
  }

  /// Clear conversation history
  static void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get current conversation history
  static List<Map<String, String>> getHistory() {
    return List.from(_conversationHistory);
  }

  /// Change language on the backend
  static Future<String> changeLanguage(String language) async {
    try {
      final response = await _backendService.changeLanguage(language);
      return response['message'] ?? 'Language changed successfully';
    } catch (e) {
      if (kDebugMode) print('❌ Change language error: $e');
      throw Exception('Unable to change language: $e');
    }
  }

  /// Get current language from backend
  static Future<String> getCurrentLanguage() async {
    try {
      final response = await _backendService.getCurrentLanguage();
      return response['currentLanguage'] ?? 'english';
    } catch (e) {
      if (kDebugMode) print('❌ Get language error: $e');
      return 'english'; // Default fallback
    }
  }

  /// Health check to wake up server
  static Future<bool> healthCheck() async {
    try {
      return await _backendService.healthCheck();
    } catch (e) {
      if (kDebugMode) print('❌ Health check error: $e');
      return false;
    }
  }

  /// Log command usage to backend for tracking
  static Future<void> logCommand(String command) async {
    try {
      await _backendService.logCommand(command);
    } catch (e) {
      if (kDebugMode) print('❌ Log command error: $e');
      // Don't throw - logging is not critical
    }
  }

  /// Summarize the entire PDF with clear error messages
  static Future<String> summarizeFullPDF() async {
    try {
      final response = await _backendService.summarizePDF(type: 'full');

      // Check if server returned an error
      if (response['success'] == false) {
        final userMessage =
            response['userMessage'] ??
            response['error'] ??
            'Unable to generate summary.';
        throw Exception(userMessage);
      }

      return response['summary'] ?? 'Unable to generate summary.';
    } catch (e) {
      print('❌ Full PDF summarization error: $e');

      // Extract user-friendly message from server response
      String userMessage = e.toString().replaceFirst('Exception: ', '');

      // Provide specific guidance based on error type
      if (userMessage.contains('No PDF uploaded')) {
        userMessage =
            'No PDF has been uploaded yet. Please upload a prospectus PDF first through the admin dashboard to enable summary functionality.';
      } else if (userMessage.contains('network') ||
          userMessage.contains('connection')) {
        userMessage =
            'Network connection issue. Please check your internet connection and try again.';
      } else if (userMessage.contains('overloaded') ||
          userMessage.contains('rate limit')) {
        userMessage =
            'The AI service is temporarily overloaded. Please try again in a few minutes.';
      } else if (userMessage.contains('loading')) {
        userMessage =
            'The AI model is still loading. Please wait a moment and try again.';
      } else if (!userMessage.contains('PDF') &&
          !userMessage.contains('upload')) {
        userMessage =
            'Sorry, I encountered an error while generating the summary. Please try again or contact support if the issue persists.';
      }

      throw Exception(userMessage);
    }
  }

  /// Summarize a specific section of the PDF with clear error messages
  static Future<String> summarizeSection(String sectionName) async {
    try {
      final response = await _backendService.summarizePDF(
        type: 'section',
        section: sectionName,
      );

      // Check if server returned an error
      if (response['success'] == false) {
        final userMessage =
            response['userMessage'] ??
            response['error'] ??
            'Unable to generate section summary.';
        throw Exception(userMessage);
      }

      return response['summary'] ?? 'Unable to generate section summary.';
    } catch (e) {
      print('❌ Section summarization error: $e');

      // Extract user-friendly message from server response
      String userMessage = e.toString().replaceFirst('Exception: ', '');

      // Provide specific guidance based on error type
      if (userMessage.contains('No PDF uploaded')) {
        userMessage =
            'No PDF has been uploaded yet. Please upload a prospectus PDF first through the admin dashboard to enable section summary functionality.';
      } else if (userMessage.contains('network') ||
          userMessage.contains('connection')) {
        userMessage =
            'Network connection issue. Please check your internet connection and try again.';
      } else if (userMessage.contains('overloaded') ||
          userMessage.contains('rate limit')) {
        userMessage =
            'The AI service is temporarily overloaded. Please try again in a few minutes.';
      } else if (userMessage.contains('loading')) {
        userMessage =
            'The AI model is still loading. Please wait a moment and try again.';
      } else if (!userMessage.contains('PDF') &&
          !userMessage.contains('upload')) {
        userMessage =
            'Sorry, I encountered an error while generating the section summary. Please try again or contact support if the issue persists.';
      }

      throw Exception(userMessage);
    }
  }

  /// Get all content chunks from Firestore for Q&A
  static Future<List<Map<String, dynamic>>> _getAllContentChunks() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('prospectus_chunks').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'tag': data['tag'] ?? 'General',
          'page': data['page'] ?? 1,
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching content chunks: $e');
      return [];
    }
  }
}
