import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'local_storage_service.dart';

/// Central HTTP client — singleton, shared across all API services.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    print('🌐 [ApiService] will use baseUrl = ${ApiConfig.baseUrl}');
  }

  /// Reset baseUrl — call after changing ApiConfig
  void resetBaseUrl() {
    _dio.options.baseUrl = '';
    print('🌐 [ApiService] baseUrl reset to ${ApiConfig.baseUrl}');
  }

  late Dio _dio;
  String? _token;
  final LocalStorageService _localStorage = LocalStorageService();

  bool get isAuthenticated => _token != null;

  void setToken(String token) {
    _token = token;
    _dio.options.headers['token'] = token;
    print('🔑 [ApiService] Token set in memory');
  }

  void clearToken() {
    _token = null;
    _dio.options.headers.remove('token');
    print('🔑 [ApiService] Token cleared');
  }

  /// Load token from storage before each request if not already in memory.
  Future<void> _ensureToken() async {
    if (_token != null) return;
    final saved = await _localStorage.getToken();
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      _dio.options.headers['token'] = saved;
      print('🔑 [ApiService] Token loaded from storage');
    } else {
      print('! [ApiService] No token found in storage');
    }
  }

  Future<ApiResponse> get(String path,
      {Map<String, String>? queryParams}) async {
    await _ensureToken();
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}$path',
        queryParameters: queryParams,
      );
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [GET $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<ApiResponse> post(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureToken();
    try {
      final response = await _dio.post('${ApiConfig.baseUrl}$path', data: body);
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [POST $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<ApiResponse> postRaw(String path, String jsonBody) async {
    await _ensureToken();
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}$path',
        data: jsonBody,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [POST raw $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<ApiResponse> put(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureToken();
    try {
      final response = await _dio.put('${ApiConfig.baseUrl}$path', data: body);
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [PUT $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<ApiResponse> patch(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureToken();
    try {
      final response =
          await _dio.patch('${ApiConfig.baseUrl}$path', data: body);
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [PATCH $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<ApiResponse> delete(String path,
      {Map<String, dynamic>? body}) async {
    await _ensureToken();
    try {
      final response = await _dio.delete('${ApiConfig.baseUrl}$path', data: body);
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [DELETE $path] $msg');
      return ApiResponse.error(msg);
    }
  }

  Future<FileApiResponse> getFile(String path,
      {Map<String, String>? queryParams}) async {
    await _ensureToken();
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}$path',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );
      return FileApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      return FileApiResponse.error(_extractError(e));
    }
  }

  // ── POST MULTIPART ──────────────────────────────────────────────────────────
  Future<ApiResponse> postMultipart(
    String path, {
    Map<String, File>? files,
    Map<String, String>? fields,
  }) async {
    await _ensureToken();
    try {
      final formData = FormData();
      if (files != null) {
        for (final entry in files.entries) {
          formData.files.add(MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
            ),
          ));
        }
      }
      if (fields != null) {
        for (final entry in fields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value));
        }
      }
      final response = await _dio.post('${ApiConfig.baseUrl}$path', data: formData);
      return ApiResponse.success(response.data, response.statusMessage);
    } on DioException catch (e) {
      final msg = _extractError(e);
      print('❌ [POST multipart $path] $msg');
      return ApiResponse.error(msg);
    }
  }
  String _extractError(DioException e) {
    // Server returned a response
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Server error ${e.response?.statusCode}';
      }
      if (data is String && data.isNotEmpty) return data;
      return 'Server error ${e.response?.statusCode}';
    }
    // No response — connection issue
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out — is the backend running at ${ApiConfig.baseUrl}?';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach backend at ${ApiConfig.baseUrl} — make sure npm run dev is running';
    }
    return e.message ?? 'Network error';
  }
}

// ── Response models ──────────────────────────────────────────────────────────

class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? message;

  ApiResponse._(this.isSuccess, this.data, this.message);

  factory ApiResponse.success(dynamic data, String? message) =>
      ApiResponse._(true, data, message);

  factory ApiResponse.error(String message) =>
      ApiResponse._(false, null, message);

  T? getData<T>(String key) {
    if (data is Map<String, dynamic>) return data[key] as T?;
    return null;
  }
}

class FileApiResponse {
  final bool isSuccess;
  final List<int>? fileBytes;
  final String? message;

  FileApiResponse._(this.isSuccess, this.fileBytes, this.message);

  factory FileApiResponse.success(List<int> fileBytes, String? message) =>
      FileApiResponse._(true, fileBytes, message);

  factory FileApiResponse.error(String message) =>
      FileApiResponse._(false, null, message);
}
