import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};

  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    _operationStartTimes.remove(operationName);

    // Store duration for analysis
    _operationDurations.putIfAbsent(operationName, () => []).add(duration);

    // Report to Sentry if operation is slow
    if (duration.inMilliseconds > 1000) {
      _reportSlowOperation(operationName, duration);
    }

    if (kDebugMode) {
      debugPrint('Operation $operationName took ${duration.inMilliseconds}ms');
    }
  }

  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (error) {
      endOperation(operationName);
      rethrow;
    }
  }

  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (error) {
      endOperation(operationName);
      rethrow;
    }
  }

  void _reportSlowOperation(String operationName, Duration duration) {
    if (kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Slow operation detected',
          category: 'performance',
          level: SentryLevel.warning,
          data: {
            'operation': operationName,
            'duration_ms': duration.inMilliseconds,
          },
        ),
      );
    }
  }

  Map<String, double> getAverageOperationTimes() {
    final averages = <String, double>{};
    
    for (final entry in _operationDurations.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        final totalMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b);
        averages[entry.key] = totalMs / durations.length;
      }
    }
    
    return averages;
  }

  void clearMetrics() {
    _operationStartTimes.clear();
    _operationDurations.clear();
  }

  // Memory monitoring
  Future<Map<String, dynamic>> getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('app.performance/memory');
        final result = await platform.invokeMethod('getMemoryInfo');
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Failed to get memory info: $e');
    }
    
    return {};
  }

  // Network performance tracking
  void trackNetworkRequest({
    required String endpoint,
    required String method,
    required Duration duration,
    required int statusCode,
    int? responseSize,
  }) {
    if (kDebugMode) {
      debugPrint(
        'Network: $method $endpoint - ${duration.inMilliseconds}ms - $statusCode'
      );
    }

    // Report slow network requests
    if (duration.inSeconds > 5) {
      if (kReleaseMode) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Slow network request',
            category: 'network',
            level: SentryLevel.warning,
            data: {
              'endpoint': endpoint,
              'method': method,
              'duration_ms': duration.inMilliseconds,
              'status_code': statusCode,
              'response_size': responseSize,
            },
          ),
        );
      }
    }
  }

  // App startup time tracking
  static DateTime? _appStartTime;
  static DateTime? _firstFrameTime;

  static void markAppStart() {
    _appStartTime = DateTime.now();
  }

  static void markFirstFrame() {
    _firstFrameTime = DateTime.now();
    
    if (_appStartTime != null && _firstFrameTime != null) {
      final startupTime = _firstFrameTime!.difference(_appStartTime!);
      
      if (kDebugMode) {
        debugPrint('App startup time: ${startupTime.inMilliseconds}ms');
      }

      // Report slow startup
      if (startupTime.inSeconds > 3) {
        if (kReleaseMode) {
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'Slow app startup',
              category: 'performance',
              level: SentryLevel.warning,
              data: {
                'startup_time_ms': startupTime.inMilliseconds,
              },
            ),
          );
        }
      }
    }
  }
}

// Performance monitoring mixin for widgets
mixin PerformanceMonitorMixin {
  final PerformanceService _performance = PerformanceService();

  void startPerformanceTracking(String operationName) {
    _performance.startOperation(operationName);
  }

  void endPerformanceTracking(String operationName) {
    _performance.endOperation(operationName);
  }

  Future<T> trackAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) {
    return _performance.measureOperation(operationName, operation);
  }

  T trackSyncOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    return _performance.measureSync(operationName, operation);
  }
}