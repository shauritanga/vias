import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Service to connect to Vercel backend functions
class VercelBackendService {
  static final VercelBackendService _instance =
      VercelBackendService._internal();
  factory VercelBackendService() => _instance;
  VercelBackendService._internal();

  // Backend URL - Multiple free options available:
  // 1. Render (FREE - 750 hours/month): 'https://your-app.onrender.com'
  // 2. Vercel (FREE - 100GB-hours/month): 'https://your-app.vercel.app'
  // 3. Netlify (FREE - 125K requests/month): 'https://your-app.netlify.app'
  // 4. Railway (FREE - $5 credit monthly): 'https://your-app.railway.app'
  // 5. Local development: 'http://localhost:10000'

  // Backend URL configuration - Uses AppConfig for environment-aware URLs
  // Automatically switches between production (Render) and development (local) based on build mode
  static String get baseUrl => AppConfig.serverUrl;

  // Fallback URLs for network resilience - configured in AppConfig
  static List<String> get fallbackUrls => AppConfig.fallbackUrls;

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

        if (kDebugMode) {
          print('✅ Fallback URL successful: ${response.statusCode}');
        }
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

  /// Process PDF bytes with Render backend
  Future<Map<String, dynamic>> processPDFBytes(
    List<int> pdfBytes,
    String filename,
  ) async {
    try {
      if (kDebugMode) {
        print('🔧 DEBUG: Current baseUrl = $baseUrl');
        print(
          '📤 Uploading PDF to Render: $filename (${pdfBytes.length} bytes)',
        );
        print('🌐 Full URL will be: $baseUrl/api/process-pdf');
      }

      final base64Data = base64Encode(pdfBytes);

      // Direct HTTP call to ensure correct URL usage
      final fullUrl = '$baseUrl/api/process-pdf';
      if (kDebugMode) print('🚀 Making direct request to: $fullUrl');

      final uri = Uri.parse(fullUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'pdfData': base64Data, 'filename': filename}),
          )
          .timeout(
            const Duration(seconds: 120),
          ); // Increased for Render cold starts

      if (kDebugMode) {
        print('📥 PDF upload response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ PDF processed successfully on Render');
          print('📊 Response: ${data['message'] ?? 'Success'}');
          print('📄 Chunks created: ${data['totalChunks'] ?? 'Unknown'}');
        }
        return data;
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          print('❌ PDF upload failed with status: ${response.statusCode}');
          print('❌ Error response: $errorBody');
        }

        try {
          final error = json.decode(errorBody);
          throw Exception(
            'PDF processing failed: ${error['error'] ?? 'Unknown error'}',
          );
        } catch (jsonError) {
          throw Exception(
            'PDF processing failed: HTTP ${response.statusCode} - $errorBody',
          );
        }
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

  /// Health check to wake up Render server
  Future<bool> healthCheck() async {
    try {
      if (kDebugMode) print('🏥 Performing health check to wake up server...');

      final uri = Uri.parse(baseUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (kDebugMode) {
        print('📥 Health check response: ${response.statusCode}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Log command usage for tracking
  Future<void> logCommand(String command) async {
    try {
      if (kDebugMode) print('📊 Logging command: $command');

      final body = {
        'command': command,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _makeRequestWithFallback('/api/log-command', {
        'Content-Type': 'application/json',
      }, json.encode(body));

      if (kDebugMode) {
        print('📥 Log command response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Log command failed: $e');
      // Don't throw - logging is not critical
    }
  }

  /// Get admission information from processed PDF
  Future<Map<String, dynamic>> getAdmissionInfo() async {
    try {
      if (kDebugMode) {
        print('📋 Requesting admission information...');
      }

      final response = await _makeRequestWithFallback('/api/admission-info', {
        'Content-Type': 'application/json',
      }, '{}');

      if (kDebugMode) {
        print('📥 Admission info response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('✅ Admission info retrieved successfully');
          print('📊 Response: ${data.toString().substring(0, 200)}...');
        }
        return data;
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          print('❌ Admission info failed with status: ${response.statusCode}');
          print('❌ Error response: $errorBody');
        }

        try {
          final error = json.decode(errorBody);
          throw Exception(
            'Admission info failed: ${error['error'] ?? 'Unknown error'}',
          );
        } catch (jsonError) {
          throw Exception(
            'Admission info failed: HTTP ${response.statusCode} - $errorBody',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Admission info error: $e');
      rethrow;
    }
  }
}
