import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for monitoring app performance and system health
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  Timer? _monitoringTimer;
  final List<PerformanceSnapshot> _snapshots = [];
  final Map<String, Stopwatch> _activeOperations = {};
  
  bool _isMonitoring = false;
  
  // Performance thresholds
  static const double _maxResponseTime = 3.0; // seconds
  static const double _maxMemoryUsage = 200.0; // MB
  static const double _maxErrorRate = 5.0; // percent

  // Getters
  bool get isMonitoring => _isMonitoring;
  List<PerformanceSnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Start performance monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) => _captureSnapshot());
    
    if (kDebugMode) print('Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    
    if (kDebugMode) print('Performance monitoring stopped');
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    _activeOperations[operationName] = Stopwatch()..start();
  }

  /// End timing an operation and return duration
  double? endOperation(String operationName) {
    final stopwatch = _activeOperations.remove(operationName);
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;
      
      // Log slow operations
      if (duration > _maxResponseTime) {
        if (kDebugMode) print('SLOW OPERATION: $operationName took ${duration.toStringAsFixed(2)}s');
      }
      
      return duration;
    }
    return null;
  }

  /// Capture a performance snapshot
  Future<void> _captureSnapshot() async {
    try {
      final snapshot = PerformanceSnapshot(
        timestamp: DateTime.now(),
        memoryUsage: await _getMemoryUsage(),
        activeOperations: _activeOperations.length,
        responseTime: _getAverageResponseTime(),
        errorRate: _calculateErrorRate(),
        systemInfo: await _getSystemInfo(),
      );

      _snapshots.add(snapshot);

      // Keep only last 100 snapshots to prevent memory issues
      if (_snapshots.length > 100) {
        _snapshots.removeAt(0);
      }

      // Check for performance issues
      _checkPerformanceThresholds(snapshot);

      if (kDebugMode) {
        print('Performance snapshot: Memory: ${snapshot.memoryUsage.toStringAsFixed(1)}MB, '
              'Operations: ${snapshot.activeOperations}, '
              'Response: ${snapshot.responseTime.toStringAsFixed(2)}s');
      }
    } catch (e) {
      if (kDebugMode) print('Error capturing performance snapshot: $e');
    }
  }

  /// Get current memory usage
  Future<double> _getMemoryUsage() async {
    try {
      // This is a simplified memory usage calculation
      // In a real app, you might use platform-specific methods
      return 85.0; // Placeholder value in MB
    } catch (e) {
      if (kDebugMode) print('Error getting memory usage: $e');
      return 0.0;
    }
  }

  /// Calculate average response time from recent operations
  double _getAverageResponseTime() {
    // This would calculate based on recent completed operations
    // For now, return a simulated value
    return 1.2; // seconds
  }

  /// Calculate error rate
  double _calculateErrorRate() {
    // This would calculate based on recent errors vs total operations
    // For now, return a simulated value
    return 2.1; // percent
  }

  /// Get system information
  Future<SystemInfo> _getSystemInfo() async {
    try {
      return SystemInfo(
        platform: Platform.operatingSystem,
        version: Platform.operatingSystemVersion,
        deviceModel: await _getDeviceModel(),
        availableMemory: await _getAvailableMemory(),
        batteryLevel: await _getBatteryLevel(),
      );
    } catch (e) {
      if (kDebugMode) print('Error getting system info: $e');
      return SystemInfo(
        platform: 'unknown',
        version: 'unknown',
        deviceModel: 'unknown',
        availableMemory: 0.0,
        batteryLevel: 0.0,
      );
    }
  }

  Future<String> _getDeviceModel() async {
    try {
      // This would use platform-specific methods to get device model
      return 'Generic Device';
    } catch (e) {
      return 'unknown';
    }
  }

  Future<double> _getAvailableMemory() async {
    try {
      // This would get actual available memory
      return 2048.0; // MB
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getBatteryLevel() async {
    try {
      // This would get actual battery level
      return 85.0; // percent
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if performance metrics exceed thresholds
  void _checkPerformanceThresholds(PerformanceSnapshot snapshot) {
    final issues = <String>[];

    if (snapshot.responseTime > _maxResponseTime) {
      issues.add('High response time: ${snapshot.responseTime.toStringAsFixed(2)}s');
    }

    if (snapshot.memoryUsage > _maxMemoryUsage) {
      issues.add('High memory usage: ${snapshot.memoryUsage.toStringAsFixed(1)}MB');
    }

    if (snapshot.errorRate > _maxErrorRate) {
      issues.add('High error rate: ${snapshot.errorRate.toStringAsFixed(1)}%');
    }

    if (issues.isNotEmpty) {
      if (kDebugMode) {
        print('PERFORMANCE ISSUES DETECTED:');
        for (final issue in issues) {
          print('  - $issue');
        }
      }
    }
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    if (_snapshots.isEmpty) {
      return {
        'status': 'no_data',
        'message': 'No performance data available',
      };
    }

    final recentSnapshots = _snapshots.length > 10 
        ? _snapshots.sublist(_snapshots.length - 10)
        : _snapshots;

    final avgMemory = recentSnapshots
        .map((s) => s.memoryUsage)
        .reduce((a, b) => a + b) / recentSnapshots.length;

    final avgResponseTime = recentSnapshots
        .map((s) => s.responseTime)
        .reduce((a, b) => a + b) / recentSnapshots.length;

    final avgErrorRate = recentSnapshots
        .map((s) => s.errorRate)
        .reduce((a, b) => a + b) / recentSnapshots.length;

    final status = _getOverallStatus(avgMemory, avgResponseTime, avgErrorRate);

    return {
      'status': status,
      'average_memory_usage': avgMemory,
      'average_response_time': avgResponseTime,
      'average_error_rate': avgErrorRate,
      'active_operations': _activeOperations.length,
      'snapshots_count': _snapshots.length,
      'monitoring_active': _isMonitoring,
      'last_snapshot': _snapshots.isNotEmpty 
          ? _snapshots.last.timestamp.toIso8601String()
          : null,
    };
  }

  String _getOverallStatus(double memory, double responseTime, double errorRate) {
    if (memory > _maxMemoryUsage || responseTime > _maxResponseTime || errorRate > _maxErrorRate) {
      return 'critical';
    } else if (memory > _maxMemoryUsage * 0.8 || 
               responseTime > _maxResponseTime * 0.8 || 
               errorRate > _maxErrorRate * 0.8) {
      return 'warning';
    } else {
      return 'good';
    }
  }

  /// Get performance trends
  Map<String, List<double>> getPerformanceTrends({int? lastN}) {
    final snapshots = lastN != null && _snapshots.length > lastN
        ? _snapshots.sublist(_snapshots.length - lastN)
        : _snapshots;

    return {
      'memory_usage': snapshots.map((s) => s.memoryUsage).toList(),
      'response_time': snapshots.map((s) => s.responseTime).toList(),
      'error_rate': snapshots.map((s) => s.errorRate).toList(),
      'active_operations': snapshots.map((s) => s.activeOperations.toDouble()).toList(),
    };
  }

  /// Dispose of the service
  void dispose() {
    stopMonitoring();
    _snapshots.clear();
    _activeOperations.clear();
  }
}

/// Performance snapshot model
class PerformanceSnapshot {
  final DateTime timestamp;
  final double memoryUsage; // MB
  final int activeOperations;
  final double responseTime; // seconds
  final double errorRate; // percent
  final SystemInfo systemInfo;

  PerformanceSnapshot({
    required this.timestamp,
    required this.memoryUsage,
    required this.activeOperations,
    required this.responseTime,
    required this.errorRate,
    required this.systemInfo,
  });
}

/// System information model
class SystemInfo {
  final String platform;
  final String version;
  final String deviceModel;
  final double availableMemory; // MB
  final double batteryLevel; // percent

  SystemInfo({
    required this.platform,
    required this.version,
    required this.deviceModel,
    required this.availableMemory,
    required this.batteryLevel,
  });
}
