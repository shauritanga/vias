import 'package:flutter_test/flutter_test.dart';
import 'package:vias/core/services/user_management_service.dart';

void main() {
  group('UserManagementService Tests', () {
    late UserManagementService userService;

    setUp(() {
      userService = UserManagementService();
      userService.initializeSampleData();
    });

    test('should initialize with sample data', () {
      expect(userService.users.isNotEmpty, isTrue);
      expect(userService.activeSessions.isNotEmpty, isTrue);
      expect(userService.supportRequests.isNotEmpty, isTrue);
      expect(userService.accessLogs.isNotEmpty, isTrue);
    });

    test('should find user by ID', () {
      final users = userService.users;
      if (users.isNotEmpty) {
        final firstUser = users.first;
        final foundUser = userService.getUserById(firstUser.id);
        
        expect(foundUser, isNotNull);
        expect(foundUser!.id, equals(firstUser.id));
        expect(foundUser.name, equals(firstUser.name));
      }
    });

    test('should return null for non-existent user ID', () {
      final foundUser = userService.getUserById('non_existent_id');
      expect(foundUser, isNull);
    });

    test('should get active users correctly', () {
      final activeUsers = userService.getActiveUsers();
      expect(activeUsers, isA<List<AppUser>>());
      
      // All active users should have recent activity
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      for (final user in activeUsers) {
        expect(user.lastActive.isAfter(yesterday), isTrue);
      }
    });

    test('should filter users by role', () {
      final adminUsers = userService.getUsersByRole(UserRole.admin);
      final studentUsers = userService.getUsersByRole(UserRole.student);
      
      expect(adminUsers, isA<List<AppUser>>());
      expect(studentUsers, isA<List<AppUser>>());
      
      // Verify role filtering
      for (final user in adminUsers) {
        expect(user.role, equals(UserRole.admin));
      }
      
      for (final user in studentUsers) {
        expect(user.role, equals(UserRole.student));
      }
    });

    test('should update user preferences', () async {
      final users = userService.users;
      if (users.isNotEmpty) {
        final user = users.first;
        final newPreferences = UserPreferences(
          speechRate: 0.8,
          volume: 0.9,
          preferredLanguage: 'sw-TZ',
          highContrastMode: true,
        );
        
        final success = await userService.updateUserPreferences(user.id, newPreferences);
        expect(success, isTrue);
        
        final updatedUser = userService.getUserById(user.id);
        expect(updatedUser!.preferences.speechRate, equals(0.8));
        expect(updatedUser.preferences.volume, equals(0.9));
        expect(updatedUser.preferences.preferredLanguage, equals('sw-TZ'));
        expect(updatedUser.preferences.highContrastMode, isTrue);
      }
    });

    test('should fail to update preferences for non-existent user', () async {
      final newPreferences = UserPreferences();
      final success = await userService.updateUserPreferences('non_existent_id', newPreferences);
      expect(success, isFalse);
    });

    test('should create support request', () async {
      final users = userService.users;
      if (users.isNotEmpty) {
        final user = users.first;
        final initialRequestCount = userService.supportRequests.length;
        
        final requestId = await userService.createSupportRequest(
          userId: user.id,
          subject: 'Test Support Request',
          description: 'This is a test support request',
          priority: SupportPriority.high,
        );
        
        expect(requestId, isNotEmpty);
        expect(userService.supportRequests.length, equals(initialRequestCount + 1));
        
        // Find the created request
        final createdRequest = userService.supportRequests
            .firstWhere((req) => req.id == requestId);
        
        expect(createdRequest.userId, equals(user.id));
        expect(createdRequest.subject, equals('Test Support Request'));
        expect(createdRequest.priority, equals(SupportPriority.high));
        expect(createdRequest.status, equals(SupportStatus.open));
      }
    });

    test('should update support request status', () async {
      final requests = userService.supportRequests;
      if (requests.isNotEmpty) {
        final request = requests.first;
        final originalStatus = request.status;
        final newStatus = originalStatus == SupportStatus.open 
            ? SupportStatus.inProgress 
            : SupportStatus.open;
        
        final success = await userService.updateSupportRequestStatus(request.id, newStatus);
        expect(success, isTrue);
        
        final updatedRequest = userService.supportRequests
            .firstWhere((req) => req.id == request.id);
        expect(updatedRequest.status, equals(newStatus));
      }
    });

    test('should fail to update non-existent support request', () async {
      final success = await userService.updateSupportRequestStatus(
        'non_existent_id', 
        SupportStatus.resolved
      );
      expect(success, isFalse);
    });

    test('should log user actions', () {
      final users = userService.users;
      if (users.isNotEmpty) {
        final user = users.first;
        final initialLogCount = userService.accessLogs.length;
        
        userService.logUserAction(
          userId: user.id,
          action: 'test_action',
          details: 'Test action details',
          success: true,
        );
        
        expect(userService.accessLogs.length, equals(initialLogCount + 1));
        
        final latestLog = userService.accessLogs.last;
        expect(latestLog.userId, equals(user.id));
        expect(latestLog.action, equals('test_action'));
        expect(latestLog.details, equals('Test action details'));
        expect(latestLog.success, isTrue);
      }
    });

    test('should get usage statistics', () {
      final stats = userService.getUsageStatistics();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('total_users'), isTrue);
      expect(stats.containsKey('active_users_today'), isTrue);
      expect(stats.containsKey('active_sessions'), isTrue);
      expect(stats.containsKey('actions_today'), isTrue);
      expect(stats.containsKey('actions_this_week'), isTrue);
      expect(stats.containsKey('open_support_requests'), isTrue);
      expect(stats.containsKey('most_used_commands'), isTrue);
      
      expect(stats['total_users'], isA<int>());
      expect(stats['most_used_commands'], isA<List>());
    });
  });

  group('UserPreferences Tests', () {
    test('should create with default values', () {
      final preferences = UserPreferences();
      
      expect(preferences.speechRate, equals(0.5));
      expect(preferences.volume, equals(1.0));
      expect(preferences.pitch, equals(1.0));
      expect(preferences.preferredLanguage, equals('en-US'));
      expect(preferences.highContrastMode, isFalse);
      expect(preferences.hapticFeedback, isTrue);
    });

    test('should create with custom values', () {
      final preferences = UserPreferences(
        speechRate: 0.8,
        volume: 0.7,
        pitch: 1.2,
        preferredLanguage: 'sw-TZ',
        highContrastMode: true,
        hapticFeedback: false,
      );
      
      expect(preferences.speechRate, equals(0.8));
      expect(preferences.volume, equals(0.7));
      expect(preferences.pitch, equals(1.2));
      expect(preferences.preferredLanguage, equals('sw-TZ'));
      expect(preferences.highContrastMode, isTrue);
      expect(preferences.hapticFeedback, isFalse);
    });
  });

  group('AppUser Tests', () {
    test('should create user with required fields', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'test_user_1',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.student,
        preferences: UserPreferences(),
        registrationDate: now,
        lastActive: now,
      );
      
      expect(user.id, equals('test_user_1'));
      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals(UserRole.student));
      expect(user.registrationDate, equals(now));
      expect(user.lastActive, equals(now));
    });

    test('should copy user with updated fields', () {
      final now = DateTime.now();
      final originalUser = AppUser(
        id: 'test_user_1',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.student,
        preferences: UserPreferences(),
        registrationDate: now,
        lastActive: now,
      );
      
      final newPreferences = UserPreferences(speechRate: 0.8);
      final updatedUser = originalUser.copyWith(preferences: newPreferences);
      
      expect(updatedUser.id, equals(originalUser.id));
      expect(updatedUser.name, equals(originalUser.name));
      expect(updatedUser.preferences.speechRate, equals(0.8));
      expect(updatedUser.preferences.speechRate, isNot(equals(originalUser.preferences.speechRate)));
    });
  });

  group('SupportRequest Tests', () {
    test('should create support request', () {
      final now = DateTime.now();
      final request = SupportRequest(
        id: 'req_1',
        userId: 'user_1',
        subject: 'Test Subject',
        description: 'Test Description',
        status: SupportStatus.open,
        priority: SupportPriority.medium,
        createdAt: now,
      );
      
      expect(request.id, equals('req_1'));
      expect(request.userId, equals('user_1'));
      expect(request.subject, equals('Test Subject'));
      expect(request.description, equals('Test Description'));
      expect(request.status, equals(SupportStatus.open));
      expect(request.priority, equals(SupportPriority.medium));
      expect(request.createdAt, equals(now));
      expect(request.updatedAt, isNull);
    });

    test('should copy support request with updated fields', () {
      final now = DateTime.now();
      final originalRequest = SupportRequest(
        id: 'req_1',
        userId: 'user_1',
        subject: 'Test Subject',
        description: 'Test Description',
        status: SupportStatus.open,
        priority: SupportPriority.medium,
        createdAt: now,
      );
      
      final updatedRequest = originalRequest.copyWith(
        status: SupportStatus.resolved,
        updatedAt: now,
      );
      
      expect(updatedRequest.id, equals(originalRequest.id));
      expect(updatedRequest.status, equals(SupportStatus.resolved));
      expect(updatedRequest.updatedAt, equals(now));
      expect(originalRequest.status, equals(SupportStatus.open));
    });
  });

  group('UserManagementService Performance Tests', () {
    late UserManagementService userService;

    setUp(() {
      userService = UserManagementService();
      userService.initializeSampleData();
    });

    test('should handle multiple user lookups efficiently', () {
      final stopwatch = Stopwatch()..start();
      
      final users = userService.users;
      for (int i = 0; i < 100; i++) {
        if (users.isNotEmpty) {
          userService.getUserById(users.first.id);
        }
      }
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('should handle multiple log entries efficiently', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        userService.logUserAction(
          userId: 'test_user',
          action: 'test_action_$i',
          details: 'Test details $i',
        );
      }
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
