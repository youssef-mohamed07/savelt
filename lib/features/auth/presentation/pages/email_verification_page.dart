import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/auth_api_service.dart';
import '../widgets/auth_ui.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authService = AuthApiService.instance;
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _canResend = false;
      _resendCooldown = 60;
    });

    try {
      final result = await _authService.resendOtp(widget.email);
      if (!mounted) return;
      showAuthSnackBar(
        context,
        result.message ?? (result.isSuccess ? 'Verification email sent' : 'Failed to resend'),
        isError: !result.isSuccess,
      );
    } catch (e) {
      if (mounted) showAuthSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      final isLoggedIn = await _authService.isAuthenticated();
      if (!mounted) return;
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        showAuthSnackBar(
          context,
          'Please verify your email using the link we sent.',
          isError: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Verify',
      title: 'Check your email',
      subtitle: widget.email,
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AuthColors.navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 40,
              color: AuthColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          AuthCard(
            child: Column(
              children: [
                const AuthBanner.info(
                  message:
                      'Open the link in your email to verify your account, then tap the button below.',
                ),
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'I\'ve verified my email',
                  loading: _isLoading,
                  onPressed: _checkVerification,
                ),
                const SizedBox(height: 12),
                AuthLinkRow(
                  prefix: "Didn't receive it?",
                  action: _canResend ? 'Resend' : 'Resend (${_resendCooldown}s)',
                  onTap: _canResend ? _resendEmail : () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AuthBanner.warning(
            message: 'Check your spam folder if you don\'t see the email.',
          ),
        ],
      ),
    );
  }
}
