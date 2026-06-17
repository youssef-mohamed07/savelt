import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../widgets/auth_ui.dart';

Future<void> performGoogleSignIn(
  BuildContext context, {
  required ValueChanged<bool> onLoadingChanged,
}) async {
  if (!GoogleAuthService.instance.isConfigured) {
    showAuthSnackBar(
      context,
      'Google Sign-In is not configured. Set GOOGLE_WEB_CLIENT_ID.',
    );
    return;
  }

  onLoadingChanged(true);
  try {
    final idToken = await GoogleAuthService.instance.signInAndGetIdToken();
    if (!context.mounted) return;
    if (idToken == null) return;

    final result = await AuthApiService.instance.signInWithGoogle(idToken: idToken);
    if (!context.mounted) return;

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      showAuthSnackBar(context, result.message ?? 'Google sign-in failed');
    }
  } on GoogleSignInException catch (e) {
    if (!context.mounted) return;
    if (e.code != GoogleSignInExceptionCode.canceled) {
      showAuthSnackBar(context, 'Google sign-in error: ${e.description ?? e.code.name}');
    }
  } catch (e) {
    if (context.mounted) {
      showAuthSnackBar(context, 'Google sign-in error: $e');
    }
  } finally {
    if (context.mounted) onLoadingChanged(false);
  }
}
