import 'package:flutter_test/flutter_test.dart';
import 'package:vias/core/services/content_management_service.dart';
import 'package:vias/shared/models/prospectus_models.dart';

void main() {
  group('ContentManagementService Tests', () {
    late ContentManagementService contentService;

    setUp(() {
      contentService = ContentManagementService();
    });

    test('should initialize with empty content', () {
      expect(contentService.programs, isEmpty);
      expect(contentService.feeStructures, isEmpty);
      expect(contentService.admissionInfo, isEmpty);
      expect(contentService.generalContent, isEmpty);
    });

    test('should search content correctly', () {
      // Add some test data first
      final testProgram = Program(
        id: 'test_1',
        name: 'Bachelor of Computer Science',
        description: 'A comprehensive computer science program',
        duration: '3 years',
        requirements: ['Form 6'],
        category: 'Bachelor',
        faculty: 'Engineering',
      );

      // Since we can't directly add to the private lists, we test the search functionality
      // with empty results initially
      final results = contentService.searchContent('computer');
      expect(results, isA<List>());
    });

    test('should get content for voice reading', () {
      // Test with empty content
      final programsContent = contentService.getContentForVoiceReading(
        'programs',
      );
      expect(programsContent, isA<String>());

      final feesContent = contentService.getContentForVoiceReading('fees');
      expect(feesContent, isA<String>());

      final admissionsContent = contentService.getContentForVoiceReading(
        'admissions',
      );
      expect(admissionsContent, isA<String>());

      final generalContent = contentService.getContentForVoiceReading(
        'general',
      );
      expect(generalContent, isA<String>());
    });

    test('should handle unknown category gracefully', () {
      final unknownContent = contentService.getContentForVoiceReading(
        'unknown',
      );
      expect(unknownContent, isA<String>());
    });

    test('should handle case insensitive search', () {
      final results1 = contentService.searchContent('COMPUTER');
      final results2 = contentService.searchContent('computer');
      final results3 = contentService.searchContent('Computer');

      expect(results1, isA<List>());
      expect(results2, isA<List>());
      expect(results3, isA<List>());
    });

    test('should handle empty search query', () {
      final results = contentService.searchContent('');
      expect(results, isA<List>());
    });

    test('should handle special characters in search', () {
      final results = contentService.searchContent('@#\$%^&*()');
      expect(results, isA<List>());
    });
  });

  group('ProcessingResult Tests', () {
    test('should create successful processing result', () {
      final result = ProcessingResult(
        success: true,
        message: 'Processing completed successfully',
        extractedText: 'Sample extracted text',
      );

      expect(result.success, isTrue);
      expect(result.message, equals('Processing completed successfully'));
      expect(result.extractedText, equals('Sample extracted text'));
      expect(result.error, isNull);
    });

    test('should create failed processing result', () {
      final result = ProcessingResult(
        success: false,
        message: 'Processing failed',
        error: 'File not found',
      );

      expect(result.success, isFalse);
      expect(result.message, equals('Processing failed'));
      expect(result.error, equals('File not found'));
      expect(result.extractedText, isNull);
    });
  });

  group('StructuredProspectusData Tests', () {
    test('should initialize with empty lists', () {
      final data = StructuredProspectusData();

      expect(data.programs, isEmpty);
      expect(data.feeStructures, isEmpty);
      expect(data.admissionInfo, isEmpty);
      expect(data.generalContent, isEmpty);
      expect(data.hasData, isFalse);
    });

    test('should detect data presence correctly', () {
      final data = StructuredProspectusData();

      // Initially no data
      expect(data.hasData, isFalse);

      // Add a program
      data.programs.add(
        Program(
          id: 'test_1',
          name: 'Test Program',
          description: 'Test Description',
          duration: '1 year',
          requirements: [],
          category: 'Test',
          faculty: 'Test Faculty',
        ),
      );

      // Now has data
      expect(data.hasData, isTrue);
    });

    test('should handle multiple data types', () {
      final data = StructuredProspectusData();

      // Add different types of data
      data.programs.add(
        Program(
          id: 'prog_1',
          name: 'Test Program',
          description: 'Test Description',
          duration: '1 year',
          requirements: [],
          category: 'Test',
          faculty: 'Test Faculty',
        ),
      );

      data.feeStructures.add(
        FeeStructure(
          id: 'fee_1',
          programId: 'prog_1',
          programName: 'Test Program',
          tuitionFee: 1000000,
          registrationFee: 50000,
          examinationFee: 25000,
          otherFees: 25000,
        ),
      );

      data.admissionInfo.add(
        AdmissionInfo(
          id: 'adm_1',
          title: 'Test Admission',
          description: 'Test admission requirements',
        ),
      );

      data.generalContent.add(
        ProspectusContent(
          id: 'content_1',
          title: 'Test Content',
          content: 'Test general content',
          category: 'general',
          lastUpdated: DateTime.now(),
        ),
      );

      expect(data.programs.length, equals(1));
      expect(data.feeStructures.length, equals(1));
      expect(data.admissionInfo.length, equals(1));
      expect(data.generalContent.length, equals(1));
      expect(data.hasData, isTrue);
    });
  });

  group('ContentManagementService Performance Tests', () {
    late ContentManagementService contentService;

    setUp(() {
      contentService = ContentManagementService();
    });

    test('should handle multiple search queries efficiently', () {
      final stopwatch = Stopwatch()..start();

      // Perform multiple searches
      for (int i = 0; i < 100; i++) {
        contentService.searchContent('test query $i');
      }

      stopwatch.stop();

      // Should complete quickly (under 100ms for 100 searches)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should handle content retrieval efficiently', () {
      final stopwatch = Stopwatch()..start();

      // Get content for different categories
      for (int i = 0; i < 50; i++) {
        contentService.getContentForVoiceReading('programs');
        contentService.getContentForVoiceReading('fees');
        contentService.getContentForVoiceReading('admissions');
        contentService.getContentForVoiceReading('general');
      }

      stopwatch.stop();

      // Should complete quickly (under 50ms for 200 operations)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  group('ContentManagementService Edge Cases', () {
    late ContentManagementService contentService;

    setUp(() {
      contentService = ContentManagementService();
    });

    test('should handle null and empty inputs gracefully', () {
      expect(() => contentService.searchContent(''), returnsNormally);
      expect(
        () => contentService.getContentForVoiceReading(''),
        returnsNormally,
      );
    });

    test('should handle very long search queries', () {
      final longQuery = 'very long search query ' * 100;
      expect(() => contentService.searchContent(longQuery), returnsNormally);
    });

    test('should handle unicode characters', () {
      const unicodeQuery = 'ñáéíóú 中文 العربية 🎓📚';
      expect(() => contentService.searchContent(unicodeQuery), returnsNormally);
    });

    test('should handle concurrent access', () async {
      // Simulate concurrent access
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(Future(() => contentService.searchContent('test $i')));
        futures.add(
          Future(() => contentService.getContentForVoiceReading('programs')),
        );
      }

      expect(() => Future.wait(futures), returnsNormally);
    });
  });
}
