import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;

  /// Web client ID is required for backend token verification.
  /// On Android, [google-services.json] can supply it when dart-define is empty.
  bool get isConfigured => ApiConfig.googleWebClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS && ApiConfig.googleIosClientId.isNotEmpty
          ? ApiConfig.googleIosClientId
          : null,
      serverClientId:
          ApiConfig.googleWebClientId.isNotEmpty ? ApiConfig.googleWebClientId : null,
    );
    _initialized = true;
  }

  Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) {
      throw StateError('Google Sign-In is not configured');
    }

    await _ensureInitialized();
    final signIn = GoogleSignIn.instance;

    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is not supported on this platform');
    }

    try {
      final account = await signIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_initialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
