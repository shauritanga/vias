import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/content_management_service.dart';

/// Widget for uploading and processing PDF files
class PDFUploadWidget extends StatefulWidget {
  final Function(ProcessingResult)? onProcessingComplete;
  final bool enabled;

  const PDFUploadWidget({
    super.key,
    this.onProcessingComplete,
    this.enabled = true,
  });

  @override
  State<PDFUploadWidget> createState() => _PDFUploadWidgetState();
}

class _PDFUploadWidgetState extends State<PDFUploadWidget> {
  final ContentManagementService _contentService = ContentManagementService();

  bool _isProcessing = false;
  String _status = 'Ready to upload PDF';
  double _progress = 0.0;
  ProcessingResult? _lastResult;

  Future<void> _pickAndProcessPDF() async {
    if (!widget.enabled || _isProcessing) return;

    try {
      setState(() {
        _status = 'Selecting PDF file...';
        _progress = 0.1;
      });

      if (kDebugMode) print('🔍 Starting PDF file selection...');

      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Important for web compatibility
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _status = 'No file selected';
          _progress = 0.0;
        });
        if (kDebugMode) print('❌ No file selected by user');
        return;
      }

      final file = result.files.first;
      if (kDebugMode) {
        print('✅ File selected: ${file.name}');
        print('📊 File size: ${file.size} bytes');
        print('📄 File extension: ${file.extension}');
        print('🔍 Has bytes: ${file.bytes != null}');
      }

      if (file.bytes == null) {
        throw Exception(
          'Could not read file data. This may be a web platform limitation.',
        );
      }

      if (file.size > 10 * 1024 * 1024) {
        throw Exception('File too large. Maximum size is 10MB.');
      }

      setState(() {
        _status =
            'Uploading to server: ${file.name} (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB)';
        _progress = 0.3;
        _isProcessing = true;
      });

      if (kDebugMode) {
        print('🤖 Starting AI processing with Hugging Face (free service)...');
      }

      // Wake up the server first (Render cold start fix)
      try {
        setState(() {
          _status = 'Waking up server (this may take 30-60 seconds)...';
          _progress = 0.4;
        });

        await QnAService.healthCheck(); // Wake up the server

        setState(() {
          _status = 'Server ready, processing PDF...';
          _progress = 0.5;
        });
      } catch (e) {
        if (kDebugMode) print('⚠️ Health check failed, continuing anyway: $e');
      }

      // Update status during processing
      Future.delayed(const Duration(seconds: 10), () {
        if (_isProcessing) {
          setState(() {
            _status =
                'Server is processing PDF with AI (this may take 1-2 minutes)...';
            _progress = 0.6;
          });
        }
      });

      Future.delayed(const Duration(seconds: 30), () {
        if (_isProcessing) {
          setState(() {
            _status = 'Still processing... Render server may be starting up...';
            _progress = 0.8;
          });
        }
      });

      // Process the PDF
      final processingResult = await _contentService.processPDFContent(
        file.bytes!,
        file.name,
      );

      setState(() {
        _progress = 1.0;
        _lastResult = processingResult;
        _status = processingResult.success
            ? 'PDF processed successfully!'
            : 'Processing failed: ${processingResult.message}';
        _isProcessing = false;
      });

      // Notify parent widget
      widget.onProcessingComplete?.call(processingResult);
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _progress = 0.0;
        _isProcessing = false;
        _lastResult = ProcessingResult(
          success: false,
          message: 'Upload failed: $e',
          error: e.toString(),
        );
      });

      widget.onProcessingComplete?.call(_lastResult!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Prospectus Upload',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Upload a PDF file to automatically extract and organize content',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status and Progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor()),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isProcessing) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.enabled && !_isProcessing
                    ? _pickAndProcessPDF
                    : null,
                icon: Icon(
                  _isProcessing ? Icons.hourglass_empty : Icons.upload_file,
                ),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Select PDF File',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Results Summary
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultsSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    if (_lastResult == null) return const SizedBox.shrink();

    final result = _lastResult!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: result.success ? Colors.green : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.success ? 'Processing Complete' : 'Processing Failed',
                style: TextStyle(
                  color: result.success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (result.success && result.structuredData != null) ...[
            const SizedBox(height: 8),
            Text(
              'Extracted Content:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            _buildContentSummary(result.structuredData!),
          ],

          if (!result.success) ...[
            const SizedBox(height: 8),
            Text(result.message, style: TextStyle(color: Colors.red[700])),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSummary(StructuredProspectusData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem(
          Icons.school,
          'Programs',
          data.programs.length,
          Colors.blue,
        ),
        _buildSummaryItem(
          Icons.attach_money,
          'Fee Structures',
          data.feeStructures.length,
          Colors.green,
        ),
        _buildSummaryItem(
          Icons.info,
          'Admission Info',
          data.admissionInfo.length,
          Colors.orange,
        ),
        _buildSummaryItem(
          Icons.description,
          'General Content',
          data.generalContent.length,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    int count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            '$count items',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_isProcessing) return Colors.blue;
    if (_lastResult?.success == true) return Colors.green;
    if (_lastResult?.success == false) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isProcessing) return Icons.hourglass_empty;
    if (_lastResult?.success == true) return Icons.check_circle;
    if (_lastResult?.success == false) return Icons.error;
    return Icons.info;
  }
}
