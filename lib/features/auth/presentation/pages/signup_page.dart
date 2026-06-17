import 'package:flutter/material.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/auth_ui.dart';
import '../utils/auth_google_sign_in.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthApiService.instance;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _authService.signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _mobileController.text.trim(),
      );

      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        showAuthSnackBar(
          context,
          result.message ?? 'Signup failed',
          isError: !result.isEmailTaken,
        );
      }
    } catch (e) {
      if (mounted) showAuthSnackBar(context, 'Signup error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Account',
      title: 'Create account',
      subtitle: 'Start tracking expenses in seconds',
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'First name',
                controller: _firstNameController,
                hint: 'John',
                keyboardType: TextInputType.name,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Last name',
                controller: _lastNameController,
                hint: 'Doe',
                keyboardType: TextInputType.name,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Mobile',
                controller: _mobileController,
                hint: '+20 123 456 7890',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 10) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthPasswordField(
                label: 'Password',
                controller: _passwordController,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthPasswordField(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggle: () =>
                    setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Sign Up',
                loading: _isLoading,
                onPressed: _handleSignUp,
              ),
              const SizedBox(height: 16),
              const AuthSocialDivider(),
              const SizedBox(height: 16),
              AuthGoogleButton(
                loading: _isGoogleLoading,
                onPressed: () => performGoogleSignIn(
                  context,
                  onLoadingChanged: (v) => setState(() => _isGoogleLoading = v),
                ),
              ),
              const SizedBox(height: 16),
              AuthLinkRow(
                prefix: 'Already have an account?',
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
