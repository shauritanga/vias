import 'package:flutter/foundation.dart';

/// Service for tracking and analyzing system usage
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // In-memory storage for analytics data
  final List<AnalyticsEvent> _events = [];
  final Map<String, int> _commandUsage = {};
  final Map<String, double> _responseTime = {};
  final List<PerformanceMetric> _performanceMetrics = [];

  // Getters
  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  Map<String, int> get commandUsage => Map.unmodifiable(_commandUsage);
  List<PerformanceMetric> get performanceMetrics => List.unmodifiable(_performanceMetrics);

  /// Initialize with sample analytics data
  void initializeSampleData() {
    if (_events.isNotEmpty) return; // Already initialized

    final now = DateTime.now();
    
    // Add sample events
    _events.addAll([
      AnalyticsEvent(
        id: 'event_1',
        userId: 'user_1',
        eventType: EventType.voiceCommand,
        eventName: 'explore_programs',
        timestamp: now.subtract(const Duration(minutes: 15)),
        properties: {'success': true, 'response_time': 1.2},
      ),
      AnalyticsEvent(
        id: 'event_2',
        userId: 'user_2',
        eventType: EventType.voiceCommand,
        eventName: 'view_fees',
        timestamp: now.subtract(const Duration(minutes: 10)),
        properties: {'success': true, 'response_time': 0.8},
      ),
      AnalyticsEvent(
        id: 'event_3',
        userId: 'user_1',
        eventType: EventType.ttsUsage,
        eventName: 'content_read',
        timestamp: now.subtract(const Duration(minutes: 8)),
        properties: {'content_type': 'programs', 'duration': 45.5},
      ),
      AnalyticsEvent(
        id: 'event_4',
        userId: 'user_2',
        eventType: EventType.settingsChange,
        eventName: 'speech_rate_changed',
        timestamp: now.subtract(const Duration(minutes: 5)),
        properties: {'old_value': 0.5, 'new_value': 0.6},
      ),
    ]);

    // Initialize command usage
    _commandUsage.addAll({
      'explore_programs': 25,
      'view_fees': 18,
      'admissions_info': 12,
      'ask_questions': 8,
      'stop': 15,
      'repeat': 6,
    });

    // Initialize response times
    _responseTime.addAll({
      'explore_programs': 1.2,
      'view_fees': 0.8,
      'admissions_info': 1.0,
      'ask_questions': 1.5,
    });

    // Add sample performance metrics
    _performanceMetrics.addAll([
      PerformanceMetric(
        id: 'perf_1',
        metricType: MetricType.responseTime,
        value: 1.1,
        timestamp: now.subtract(const Duration(minutes: 30)),
        context: 'voice_command_processing',
      ),
      PerformanceMetric(
        id: 'perf_2',
        metricType: MetricType.memoryUsage,
        value: 85.5,
        timestamp: now.subtract(const Duration(minutes: 25)),
        context: 'app_memory_usage_mb',
      ),
      PerformanceMetric(
        id: 'perf_3',
        metricType: MetricType.errorRate,
        value: 2.1,
        timestamp: now.subtract(const Duration(minutes: 20)),
        context: 'speech_recognition_errors_percent',
      ),
    ]);

    if (kDebugMode) {
      print('AnalyticsService initialized with sample data:');
      print('- Events: ${_events.length}');
      print('- Command usage entries: ${_commandUsage.length}');
      print('- Performance metrics: ${_performanceMetrics.length}');
    }
  }

  /// Track a new analytics event
  void trackEvent({
    required String userId,
    required EventType eventType,
    required String eventName,
    Map<String, dynamic>? properties,
  }) {
    try {
      final event = AnalyticsEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        eventType: eventType,
        eventName: eventName,
        timestamp: DateTime.now(),
        properties: properties ?? {},
      );

      _events.add(event);

      // Update command usage if it's a voice command
      if (eventType == EventType.voiceCommand) {
        _commandUsage[eventName] = (_commandUsage[eventName] ?? 0) + 1;
      }

      // Keep only last 10000 events to prevent memory issues
      if (_events.length > 10000) {
        _events.removeRange(0, _events.length - 10000);
      }

      if (kDebugMode) print('Tracked event: $eventName for user: $userId');
    } catch (e) {
      if (kDebugMode) print('Error tracking event: $e');
    }
  }

  /// Track performance metric
  void trackPerformanceMetric({
    required MetricType metricType,
    required double value,
    required String context,
  }) {
    try {
      final metric = PerformanceMetric(
        id: 'perf_${DateTime.now().millisecondsSinceEpoch}',
        metricType: metricType,
        value: value,
        timestamp: DateTime.now(),
        context: context,
      );

      _performanceMetrics.add(metric);

      // Keep only last 1000 metrics
      if (_performanceMetrics.length > 1000) {
        _performanceMetrics.removeRange(0, _performanceMetrics.length - 1000);
      }

      if (kDebugMode) print('Tracked performance metric: $metricType = $value');
    } catch (e) {
      if (kDebugMode) print('Error tracking performance metric: $e');
    }
  }

  /// Get usage statistics for a time period
  Map<String, dynamic> getUsageStatistics({Duration? period}) {
    final cutoffTime = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.now().subtract(const Duration(days: 7)); // Default to last week

    final relevantEvents = _events.where((event) => 
        event.timestamp.isAfter(cutoffTime)).toList();

    final voiceCommands = relevantEvents.where((event) => 
        event.eventType == EventType.voiceCommand).toList();

    final ttsUsage = relevantEvents.where((event) => 
        event.eventType == EventType.ttsUsage).toList();

    return {
      'total_events': relevantEvents.length,
      'voice_commands': voiceCommands.length,
      'tts_usage': ttsUsage.length,
      'unique_users': relevantEvents.map((e) => e.userId).toSet().length,
      'most_used_commands': _getMostUsedCommands(voiceCommands),
      'average_response_time': _getAverageResponseTime(voiceCommands),
      'success_rate': _getSuccessRate(voiceCommands),
    };
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStatistics({Duration? period}) {
    final cutoffTime = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.now().subtract(const Duration(hours: 24)); // Default to last 24 hours

    final relevantMetrics = _performanceMetrics.where((metric) => 
        metric.timestamp.isAfter(cutoffTime)).toList();

    final responseTimeMetrics = relevantMetrics.where((metric) => 
        metric.metricType == MetricType.responseTime).toList();

    final memoryMetrics = relevantMetrics.where((metric) => 
        metric.metricType == MetricType.memoryUsage).toList();

    final errorMetrics = relevantMetrics.where((metric) => 
        metric.metricType == MetricType.errorRate).toList();

    return {
      'average_response_time': responseTimeMetrics.isNotEmpty 
          ? responseTimeMetrics.map((m) => m.value).reduce((a, b) => a + b) / responseTimeMetrics.length
          : 0.0,
      'average_memory_usage': memoryMetrics.isNotEmpty 
          ? memoryMetrics.map((m) => m.value).reduce((a, b) => a + b) / memoryMetrics.length
          : 0.0,
      'average_error_rate': errorMetrics.isNotEmpty 
          ? errorMetrics.map((m) => m.value).reduce((a, b) => a + b) / errorMetrics.length
          : 0.0,
      'total_metrics': relevantMetrics.length,
    };
  }

  /// Get user engagement statistics
  Map<String, dynamic> getUserEngagementStatistics({Duration? period}) {
    final cutoffTime = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.now().subtract(const Duration(days: 7));

    final relevantEvents = _events.where((event) => 
        event.timestamp.isAfter(cutoffTime)).toList();

    final userSessions = <String, List<AnalyticsEvent>>{};
    for (final event in relevantEvents) {
      userSessions.putIfAbsent(event.userId, () => []).add(event);
    }

    final sessionDurations = <double>[];
    for (final userEvents in userSessions.values) {
      if (userEvents.length > 1) {
        userEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final duration = userEvents.last.timestamp.difference(userEvents.first.timestamp).inMinutes.toDouble();
        sessionDurations.add(duration);
      }
    }

    return {
      'active_users': userSessions.length,
      'total_sessions': userSessions.length,
      'average_session_duration': sessionDurations.isNotEmpty 
          ? sessionDurations.reduce((a, b) => a + b) / sessionDurations.length
          : 0.0,
      'events_per_user': relevantEvents.length / (userSessions.length > 0 ? userSessions.length : 1),
    };
  }

  List<Map<String, dynamic>> _getMostUsedCommands(List<AnalyticsEvent> voiceCommands) {
    final commandCounts = <String, int>{};
    
    for (final command in voiceCommands) {
      commandCounts[command.eventName] = (commandCounts[command.eventName] ?? 0) + 1;
    }
    
    final sortedCommands = commandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCommands.take(5).map((entry) => {
      'command': entry.key,
      'count': entry.value,
    }).toList();
  }

  double _getAverageResponseTime(List<AnalyticsEvent> voiceCommands) {
    final responseTimes = voiceCommands
        .where((event) => event.properties.containsKey('response_time'))
        .map((event) => event.properties['response_time'] as double)
        .toList();

    return responseTimes.isNotEmpty 
        ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
        : 0.0;
  }

  double _getSuccessRate(List<AnalyticsEvent> voiceCommands) {
    if (voiceCommands.isEmpty) return 0.0;

    final successfulCommands = voiceCommands
        .where((event) => event.properties['success'] == true)
        .length;

    return (successfulCommands / voiceCommands.length) * 100;
  }

  /// Get real-time dashboard data
  Map<String, dynamic> getDashboardData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(const Duration(days: 7));

    final todayEvents = _events.where((event) => event.timestamp.isAfter(today)).toList();
    final weekEvents = _events.where((event) => event.timestamp.isAfter(thisWeek)).toList();

    return {
      'events_today': todayEvents.length,
      'events_this_week': weekEvents.length,
      'total_events': _events.length,
      'top_commands': _commandUsage.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(3)
          .map((e) => {'command': e.key, 'count': e.value})
          .toList(),
      'current_performance': getPerformanceStatistics(period: const Duration(hours: 1)),
    };
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String id;
  final String userId;
  final EventType eventType;
  final String eventName;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventName,
    required this.timestamp,
    required this.properties,
  });
}

/// Event type enumeration
enum EventType {
  voiceCommand,
  ttsUsage,
  settingsChange,
  contentAccess,
  error,
  performance,
}

/// Performance metric model
class PerformanceMetric {
  final String id;
  final MetricType metricType;
  final double value;
  final DateTime timestamp;
  final String context;

  PerformanceMetric({
    required this.id,
    required this.metricType,
    required this.value,
    required this.timestamp,
    required this.context,
  });
}

/// Metric type enumeration
enum MetricType {
  responseTime,
  memoryUsage,
  errorRate,
  cpuUsage,
  networkLatency,
}
