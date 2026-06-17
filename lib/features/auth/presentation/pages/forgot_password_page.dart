import 'package:flutter/material.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/auth_ui.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';
import 'signup_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthApiService.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final result = await _authService.forgetPassword(email);
      if (!mounted) return;

      if (result.isSuccess) {
        NavigationHelper.pushReplacement(
          context,
          OtpVerificationPage(
            email: email,
            purpose: OtpPurpose.passwordReset,
          ),
        );
      } else {
        showAuthSnackBar(context, result.message ?? 'Failed to send reset code');
      }
    } catch (e) {
      if (mounted) {
        showAuthSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Security',
      title: 'Reset password',
      subtitle: 'We\'ll send a 6-digit code to your email',
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Email address',
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Send reset code',
                loading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 20),
              AuthLinkRow(
                prefix: "Don't have an account?",
                action: 'Sign Up',
                onTap: () => NavigationHelper.push(context, const SignUpPage()),
              ),
              const SizedBox(height: 8),
              AuthLinkRow(
                prefix: 'Remember your password?',
                action: 'Log In',
                onTap: () => NavigationHelper.pushReplacement(context, const LoginPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
