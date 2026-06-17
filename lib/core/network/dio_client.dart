import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'connectivity_interceptor.dart';
import 'retry_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio _dio;
  final SecureStorage _storage = SecureStorage();

  Dio get dio => _dio;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,   // dynamic — emulator vs real device
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    print('🌐 [DioClient] baseUrl = ${ApiConfig.baseUrl}');

    // Add interceptors in order
    _dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(_storage),
      RetryInterceptor(),
      if (!kReleaseMode) PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        filter: (options, args) {
          // Don't log sensitive endpoints
          return !options.path.contains('/auth/');
        },
      ),
    ]);

    // Certificate pinning for production - commented out due to compatibility
    // if (kReleaseMode) {
    //   // Add certificate pinning in production
    // }
  }

  bool _verifyCertificate(cert, String host) {
    // Implement your certificate pinning logic here
    // For now, return true for development
    return true;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}