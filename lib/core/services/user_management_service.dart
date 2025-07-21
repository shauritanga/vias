import 'package:flutter/foundation.dart';

/// Service for managing users and their preferences
class UserManagementService {
  static final UserManagementService _instance = UserManagementService._internal();
  factory UserManagementService() => _instance;
  UserManagementService._internal();

  // In-memory storage (will be replaced with Firebase later)
  final List<AppUser> _users = [];
  final List<UserSession> _activeSessions = [];
  final List<SupportRequest> _supportRequests = [];
  final List<AccessLog> _accessLogs = [];

  // Getters
  List<AppUser> get users => List.unmodifiable(_users);
  List<UserSession> get activeSessions => List.unmodifiable(_activeSessions);
  List<SupportRequest> get supportRequests => List.unmodifiable(_supportRequests);
  List<AccessLog> get accessLogs => List.unmodifiable(_accessLogs);

  /// Initialize with sample data
  void initializeSampleData() {
    if (_users.isNotEmpty) return; // Already initialized

    // Add sample users
    _users.addAll([
      AppUser(
        id: 'user_1',
        name: 'John Mwalimu',
        email: 'john.mwalimu@example.com',
        role: UserRole.student,
        preferences: UserPreferences(
          speechRate: 0.6,
          volume: 0.8,
          preferredLanguage: 'en-US',
          highContrastMode: true,
        ),
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppUser(
        id: 'user_2',
        name: 'Mary Kiprotich',
        email: 'mary.kiprotich@example.com',
        role: UserRole.student,
        preferences: UserPreferences(
          speechRate: 0.5,
          volume: 1.0,
          preferredLanguage: 'en-US',
          highContrastMode: false,
        ),
        registrationDate: DateTime.now().subtract(const Duration(days: 15)),
        lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AppUser(
        id: 'admin_1',
        name: 'Dr. James Mwangi',
        email: 'james.mwangi@dit.ac.tz',
        role: UserRole.admin,
        preferences: UserPreferences(),
        registrationDate: DateTime.now().subtract(const Duration(days: 90)),
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);

    // Add sample sessions
    _activeSessions.addAll([
      UserSession(
        id: 'session_1',
        userId: 'user_1',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
        deviceInfo: 'Android 12, Samsung Galaxy',
        ipAddress: '192.168.1.100',
      ),
      UserSession(
        id: 'session_2',
        userId: 'user_2',
        startTime: DateTime.now().subtract(const Duration(minutes: 45)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        deviceInfo: 'iOS 16, iPhone 13',
        ipAddress: '192.168.1.101',
      ),
    ]);

    // Add sample support requests
    _supportRequests.addAll([
      SupportRequest(
        id: 'support_1',
        userId: 'user_1',
        subject: 'Voice commands not working properly',
        description: 'The app sometimes doesn\'t recognize my voice commands, especially "explore programs".',
        status: SupportStatus.open,
        priority: SupportPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SupportRequest(
        id: 'support_2',
        userId: 'user_2',
        subject: 'Request for Swahili language support',
        description: 'It would be great if the app could support Swahili language for better accessibility.',
        status: SupportStatus.inProgress,
        priority: SupportPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    // Add sample access logs
    _accessLogs.addAll([
      AccessLog(
        id: 'log_1',
        userId: 'user_1',
        action: 'voice_command',
        details: 'Executed: explore_programs',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        success: true,
      ),
      AccessLog(
        id: 'log_2',
        userId: 'user_2',
        action: 'voice_command',
        details: 'Executed: view_fees',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        success: true,
      ),
      AccessLog(
        id: 'log_3',
        userId: 'user_1',
        action: 'tts_settings',
        details: 'Changed speech rate to 0.6',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        success: true,
      ),
    ]);

    if (kDebugMode) {
      print('UserManagementService initialized with sample data:');
      print('- Users: ${_users.length}');
      print('- Active sessions: ${_activeSessions.length}');
      print('- Support requests: ${_supportRequests.length}');
      print('- Access logs: ${_accessLogs.length}');
    }
  }

  /// Get user by ID
  AppUser? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get active users (active in last 24 hours)
  List<AppUser> getActiveUsers() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _users.where((user) => user.lastActive.isAfter(yesterday)).toList();
  }

  /// Get users by role
  List<AppUser> getUsersByRole(UserRole role) {
    return _users.where((user) => user.role == role).toList();
  }

  /// Update user preferences
  Future<bool> updateUserPreferences(String userId, UserPreferences preferences) async {
    try {
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(preferences: preferences);
        
        // Log the change
        _accessLogs.add(AccessLog(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          action: 'preferences_updated',
          details: 'Updated user preferences',
          timestamp: DateTime.now(),
          success: true,
        ));
        
        if (kDebugMode) print('Updated preferences for user: $userId');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error updating user preferences: $e');
      return false;
    }
  }

  /// Create support request
  Future<String> createSupportRequest({
    required String userId,
    required String subject,
    required String description,
    SupportPriority priority = SupportPriority.medium,
  }) async {
    try {
      final request = SupportRequest(
        id: 'support_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        subject: subject,
        description: description,
        status: SupportStatus.open,
        priority: priority,
        createdAt: DateTime.now(),
      );
      
      _supportRequests.add(request);
      
      if (kDebugMode) print('Created support request: ${request.id}');
      return request.id;
    } catch (e) {
      if (kDebugMode) print('Error creating support request: $e');
      throw Exception('Failed to create support request: $e');
    }
  }

  /// Update support request status
  Future<bool> updateSupportRequestStatus(String requestId, SupportStatus status) async {
    try {
      final requestIndex = _supportRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex != -1) {
        _supportRequests[requestIndex] = _supportRequests[requestIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        
        if (kDebugMode) print('Updated support request $requestId status to $status');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error updating support request status: $e');
      return false;
    }
  }

  /// Log user action
  void logUserAction({
    required String userId,
    required String action,
    required String details,
    bool success = true,
  }) {
    try {
      final log = AccessLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        action: action,
        details: details,
        timestamp: DateTime.now(),
        success: success,
      );
      
      _accessLogs.add(log);
      
      // Keep only last 1000 logs to prevent memory issues
      if (_accessLogs.length > 1000) {
        _accessLogs.removeRange(0, _accessLogs.length - 1000);
      }
      
      if (kDebugMode) print('Logged action: $action for user: $userId');
    } catch (e) {
      if (kDebugMode) print('Error logging user action: $e');
    }
  }

  /// Get usage statistics
  Map<String, dynamic> getUsageStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(const Duration(days: 7));
    
    final todayLogs = _accessLogs.where((log) => log.timestamp.isAfter(today)).toList();
    final weekLogs = _accessLogs.where((log) => log.timestamp.isAfter(thisWeek)).toList();
    
    return {
      'total_users': _users.length,
      'active_users_today': getActiveUsers().length,
      'active_sessions': _activeSessions.length,
      'actions_today': todayLogs.length,
      'actions_this_week': weekLogs.length,
      'open_support_requests': _supportRequests.where((req) => req.status == SupportStatus.open).length,
      'most_used_commands': _getMostUsedCommands(weekLogs),
    };
  }

  List<Map<String, dynamic>> _getMostUsedCommands(List<AccessLog> logs) {
    final commandCounts = <String, int>{};
    
    for (final log in logs) {
      if (log.action == 'voice_command') {
        final command = log.details.replaceAll('Executed: ', '');
        commandCounts[command] = (commandCounts[command] ?? 0) + 1;
      }
    }
    
    final sortedCommands = commandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCommands.take(5).map((entry) => {
      'command': entry.key,
      'count': entry.value,
    }).toList();
  }
}

/// User model
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserPreferences preferences;
  final DateTime registrationDate;
  final DateTime lastActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.preferences,
    required this.registrationDate,
    required this.lastActive,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserPreferences? preferences,
    DateTime? registrationDate,
    DateTime? lastActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      registrationDate: registrationDate ?? this.registrationDate,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

/// User role enumeration
enum UserRole { student, admin, staff }

/// User preferences model
class UserPreferences {
  final double speechRate;
  final double volume;
  final double pitch;
  final String preferredLanguage;
  final bool highContrastMode;
  final bool hapticFeedback;

  UserPreferences({
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.preferredLanguage = 'en-US',
    this.highContrastMode = false,
    this.hapticFeedback = true,
  });
}

/// User session model
class UserSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime lastActivity;
  final String deviceInfo;
  final String ipAddress;

  UserSession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.lastActivity,
    required this.deviceInfo,
    required this.ipAddress,
  });
}

/// Support request model
class SupportRequest {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final SupportStatus status;
  final SupportPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  SupportRequest copyWith({
    String? id,
    String? userId,
    String? subject,
    String? description,
    SupportStatus? status,
    SupportPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Support request status
enum SupportStatus { open, inProgress, resolved, closed }

/// Support request priority
enum SupportPriority { low, medium, high, urgent }

/// Access log model
class AccessLog {
  final String id;
  final String userId;
  final String action;
  final String details;
  final DateTime timestamp;
  final bool success;

  AccessLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.success,
  });
}
