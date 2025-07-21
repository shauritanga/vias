import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service to connect to Vercel backend functions
class VercelBackendService {
  static final VercelBackendService _instance =
      VercelBackendService._internal();
  factory VercelBackendService() => _instance;
  VercelBackendService._internal();

  // Backend URL - Multiple free options available:
  // 1. Vercel (FREE - 100GB-hours/month): 'https://your-app.vercel.app'
  // 2. Netlify (FREE - 125K requests/month): 'https://your-app.netlify.app'
  // 3. Railway (FREE - $5 credit monthly): 'https://your-app.railway.app'
  // 4. Local development: 'http://localhost:3001'

  // Backend URL configuration for different platforms
  static const String baseUrl = kIsWeb
      ? 'http://localhost:10000' // Web can access localhost for development
      : 'https://your-app-name.onrender.com'; // Replace with your Render URL

  // Fallback URLs for network issues
  static const List<String> fallbackUrls = [
    'https://your-app-name.onrender.com', // Primary cloud URL
    'http://10.0.2.2:10000', // Local development on emulator
    'http://localhost:10000', // Local development
  ];

  /// Try multiple URLs to handle Android emulator network issues
  Future<http.Response> _makeRequestWithFallback(
    String endpoint,
    Map<String, String> headers,
    String body,
  ) async {
    // Try primary URL first
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      if (kDebugMode) print('🌐 Trying primary URL: $uri');

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) print('✅ Primary URL successful: ${response.statusCode}');
      return response;
    } catch (e) {
      if (kDebugMode) print('❌ Primary URL failed: $e');
    }

    // Try fallback URLs
    for (final fallbackUrl in fallbackUrls) {
      if (fallbackUrl == baseUrl) continue; // Skip if same as primary

      try {
        final uri = Uri.parse('$fallbackUrl$endpoint');
        if (kDebugMode) print('🔄 Trying fallback URL: $uri');

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 10));

        if (kDebugMode)
          print('✅ Fallback URL successful: ${response.statusCode}');
        return response;
      } catch (e) {
        if (kDebugMode) print('❌ Fallback URL failed ($fallbackUrl): $e');
      }
    }

    throw Exception(
      'All backend URLs failed. Please check network connection.',
    );
  }

  /// Process PDF file and extract content
  Future<Map<String, dynamic>> processPDF(File pdfFile) async {
    try {
      final uri = Uri.parse('$baseUrl/api/process-pdf');
      final request = http.MultipartRequest('POST', uri);

      // Add PDF file
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          pdfFile.path,
          filename: pdfFile.path.split('/').last,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ PDF processed successfully: ${data['message']}');
          print('📄 Total pages: ${data['totalPages']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('PDF processing failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ PDF processing error: $e');
      rethrow;
    }
  }

  /// Ask question and get AI-powered answer
  Future<Map<String, dynamic>> answerQuestion(
    String question, {
    required List<Map<String, dynamic>> contentChunks,
    List<Map<String, String>>? history,
  }) async {
    try {
      final body = {'question': question, 'contentChunks': contentChunks};

      if (history != null && history.isNotEmpty) {
        body['history'] = history;
      }

      if (kDebugMode) {
        print(
          '📤 Request: question="$question", chunks=${contentChunks.length}',
        );
      }

      // Use fallback mechanism for better connectivity
      final response = await _makeRequestWithFallback('/api/answer-question', {
        'Content-Type': 'application/json',
      }, json.encode(body));

      if (kDebugMode) {
        print('📥 Response status: ${response.statusCode}');
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('📥 Response body: $preview...');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Question answered successfully');
          print('❓ Question: ${data['question']}');
          print('💡 Answer: ${data['answer'].substring(0, 100)}...');
          print('📚 Relevant chunks: ${data['relevantChunks']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('Question answering failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Question answering error: $e');
      rethrow;
    }
  }

  /// Test backend connectivity
  Future<bool> testConnection() async {
    try {
      if (kDebugMode) print('🔍 Testing connection to: $baseUrl');

      final uri = Uri.parse(
        '$baseUrl/',
      ); // Test root endpoint instead of /api/health
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Backend connection successful');
          print('📊 Platform: ${kIsWeb ? "Web" : "Mobile"}');
          print('🌐 URL: $baseUrl');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ Backend returned status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Backend connection failed: $e');
      return false;
    }
  }

  /// Convert PDF bytes to base64 for Netlify functions
  Future<Map<String, dynamic>> processPDFBytes(
    List<int> pdfBytes,
    String filename,
  ) async {
    try {
      final base64Data = base64Encode(pdfBytes);

      final uri = Uri.parse('$baseUrl/api/process-pdf');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pdfData': base64Data, 'filename': filename}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ PDF bytes processed successfully: ${data['message']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('PDF processing failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ PDF bytes processing error: $e');
      rethrow;
    }
  }

  /// Summarize PDF content
  Future<Map<String, dynamic>> summarizePDF({
    String type = 'full', // 'full' or 'section'
    String? section,
  }) async {
    try {
      final body = {'type': type};

      if (section != null && section.isNotEmpty) {
        body['section'] = section;
      }

      if (kDebugMode) {
        print('📤 Summarize request: type="$type", section="$section"');
      }

      // Use fallback mechanism for better connectivity
      final response = await _makeRequestWithFallback('/api/summarize-pdf', {
        'Content-Type': 'application/json',
      }, json.encode(body));

      if (kDebugMode) {
        print('📥 Summarize response status: ${response.statusCode}');
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('📥 Summarize response body: $preview...');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ PDF summary generated');
          print('📋 Type: ${data['type']}');
          print(
            '📄 Summary length: ${data['summary']?.length ?? 0} characters',
          );
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('PDF summarization failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ PDF summarization error: $e');
      rethrow;
    }
  }

  /// Sync content from Firestore to backend memory
  Future<Map<String, dynamic>> syncFromFirestore(List<dynamic> chunks) async {
    try {
      final body = {'chunks': chunks};

      if (kDebugMode) {
        print('📤 Sync request: ${chunks.length} chunks');
      }

      // Use fallback mechanism for better connectivity
      final response = await _makeRequestWithFallback(
        '/api/sync-from-firestore',
        {'Content-Type': 'application/json'},
        json.encode(body),
      );

      if (kDebugMode) {
        print('📥 Sync response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Backend sync successful');
          print('📋 Total chunks in backend: ${data['totalChunks']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('Backend sync failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Backend sync error: $e');
      rethrow;
    }
  }

  /// Change language on the backend
  Future<Map<String, dynamic>> changeLanguage(String language) async {
    try {
      final body = {'language': language};

      if (kDebugMode) {
        print('🌍 Language change request: $language');
      }

      // Use fallback mechanism for better connectivity
      final response = await _makeRequestWithFallback('/api/language', {
        'Content-Type': 'application/json',
      }, json.encode(body));

      if (kDebugMode) {
        print('📥 Language change response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Backend language changed to: $language');
          print('📋 Message: ${data['message']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('Language change failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Language change error: $e');
      rethrow;
    }
  }

  /// Get current language from backend
  Future<Map<String, dynamic>> getCurrentLanguage() async {
    try {
      if (kDebugMode) {
        print('🌍 Getting current language from backend');
      }

      final uri = Uri.parse('$baseUrl/api/language');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('📥 Get language response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Current backend language: ${data['currentLanguage']}');
        }
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception('Get language failed: ${error['error']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Get language error: $e');
      rethrow;
    }
  }
}
