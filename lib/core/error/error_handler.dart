import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ErrorType {
  network,
  server,
  authentication,
  validation,
  unknown,
  offline,
}

class AppError {
  final String message;
  final String? code;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  factory AppError.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please check your internet connection.',
          type: ErrorType.network,
          originalError: error,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return AppError(
            message: 'Authentication failed. Please login again.',
            code: '401',
            type: ErrorType.authentication,
            originalError: error,
          );
        } else if (statusCode == 422) {
          return AppError(
            message: 'Invalid data provided.',
            code: '422',
            type: ErrorType.validation,
            originalError: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return AppError(
            message: 'Server error. Please try again later.',
            code: statusCode.toString(),
            type: ErrorType.server,
            originalError: error,
          );
        }
        return AppError(
          message: error.response?.data?['message'] ?? 'Request failed',
          code: statusCode?.toString(),
          type: ErrorType.server,
          originalError: error,
        );
      
      case DioExceptionType.cancel:
        return AppError(
          message: 'Request was cancelled',
          type: ErrorType.network,
          originalError: error,
        );
      
      case DioExceptionType.connectionError:
        return AppError(
          message: 'No internet connection',
          type: ErrorType.offline,
          originalError: error,
        );
      
      default:
        return AppError(
          message: 'An unexpected error occurred',
          type: ErrorType.unknown,
          originalError: error,
        );
    }
  }

  factory AppError.fromException(dynamic error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return AppError.fromDioError(error);
    }
    
    return AppError(
      message: error.toString(),
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  Future<void> handleError(AppError error, {bool reportToSentry = true}) async {
    // Log error locally
    if (kDebugMode) {
      debugPrint('Error: ${error.message}');
      debugPrint('Type: ${error.type}');
      debugPrint('Code: ${error.code}');
      if (error.originalError != null) {
        debugPrint('Original: ${error.originalError}');
      }
    }

    // Report to Sentry in release mode
    if (reportToSentry && kReleaseMode && error.type != ErrorType.validation) {
      await _reportToSentry(error);
    }
  }

  Future<void> _reportToSentry(AppError error) async {
    try {
      await Sentry.captureException(
        error.originalError ?? error.message,
        stackTrace: error.stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', error.type.name);
          scope.level = _getSentryLevel(error.type);
          
          if (error.code != null) {
            scope.setTag('error_code', error.code!);
          }
          
          scope.setExtra('error_details', {
            'message': error.message,
            'type': error.type.name,
            'code': error.code,
          });
        },
      );
    } catch (e) {
      debugPrint('Failed to report error to Sentry: $e');
    }
  }

  SentryLevel _getSentryLevel(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
        return SentryLevel.warning;
      case ErrorType.validation:
        return SentryLevel.info;
      case ErrorType.network:
      case ErrorType.offline:
        return SentryLevel.warning;
      case ErrorType.server:
        return SentryLevel.error;
      case ErrorType.unknown:
        return SentryLevel.fatal;
    }
  }

  String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.server:
        return 'Server is temporarily unavailable. Please try again later.';
      case ErrorType.authentication:
        return 'Please login again to continue.';
      case ErrorType.validation:
        return error.message;
      case ErrorType.offline:
        return 'You are offline. Some features may not be available.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  bool shouldRetry(AppError error) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.server:
      case ErrorType.offline:
        return true;
      case ErrorType.authentication:
      case ErrorType.validation:
      case ErrorType.unknown:
        return false;
    }
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

// Retry mechanism with exponential backoff
class RetryHandler {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        final appError = AppError.fromException(error);
        final shouldRetry = retryIf?.call(error) ?? 
                           ErrorHandler().shouldRetry(appError);
        
        if (attempt >= maxRetries || !shouldRetry) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw StateError('Retry logic error'); // Should never reach here
  }
}