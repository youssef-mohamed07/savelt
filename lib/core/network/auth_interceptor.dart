import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../services/auth_api_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  
  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/signup endpoints
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['token'] = token;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final options = err.requestOptions;
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['token'] = token;
        }
        
        try {
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        } catch (e) {
          // If retry fails, continue with original error
        }
      } else {
        // Refresh failed, logout user
        await AuthApiService.instance.logout();
      }
    }

    handler.next(err);
  }

  bool _shouldSkipAuth(String path) {
    const skipPaths = [
      '/auth/signin',
      '/auth/signup',
      '/auth/signup/configurationOTP',
      '/auth/forgetPassword',
      '/auth/resendOTP',
      '/auth/google',
      '/auth/setNewPassword',
    ];
    return skipPaths.any((skipPath) => path.contains(skipPath));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      // Call refresh endpoint
      final dio = Dio();
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }
}