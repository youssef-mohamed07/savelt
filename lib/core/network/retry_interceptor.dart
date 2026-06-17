import 'dart:math';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../error/error_handler.dart';
import '../services/performance_service.dart';

class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);
  final PerformanceService _performance = PerformanceService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Track network request start
    _performance.startOperation('network_${options.method}_${options.path}');
    options.extra['request_start_time'] = DateTime.now();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Track network request completion
    final startTime = response.requestOptions.extra['request_start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _performance.trackNetworkRequest(
        endpoint: response.requestOptions.path,
        method: response.requestOptions.method,
        duration: duration,
        statusCode: response.statusCode ?? 0,
        responseSize: response.data?.toString().length,
      );
    }
    
    _performance.endOperation('network_${response.requestOptions.method}_${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Track network request error
    final startTime = err.requestOptions.extra['request_start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _performance.trackNetworkRequest(
        endpoint: err.requestOptions.path,
        method: err.requestOptions.method,
        duration: duration,
        statusCode: err.response?.statusCode ?? 0,
      );
    }
    
    _performance.endOperation('network_${err.requestOptions.method}_${err.requestOptions.path}');

    final appError = AppError.fromDioError(err);
    
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      
      if (retryCount < maxRetries) {
        // Check connectivity before retrying
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.none)) {
          final offlineError = AppError(
            message: 'No internet connection',
            type: ErrorType.offline,
            originalError: err,
          );
          await ErrorHandler().handleError(offlineError);
          return handler.next(err);
        }

        err.requestOptions.extra['retryCount'] = retryCount + 1;
        
        // Exponential backoff
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * pow(2, retryCount).toInt(),
        );
        
        await Future.delayed(delay);
        
        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Continue with original error if retry fails
        }
      }
    }

    // Handle error and report to monitoring
    await ErrorHandler().handleError(appError);
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors, timeouts, and 5xx server errors
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode != null && 
            err.response!.statusCode! >= 500);
  }
}