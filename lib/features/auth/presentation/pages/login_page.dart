import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/routes/app_routes.dart';
import '../widgets/auth_ui.dart';
import '../utils/auth_google_sign_in.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthApiService.instance;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _authService.signin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        showAuthSnackBar(context, result.message ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) showAuthSnackBar(context, 'Login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Account',
      title: 'Welcome back',
      subtitle: 'Sign in to continue tracking your spending',
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthPasswordField(
                label: 'Password',
                controller: _passwordController,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => NavigationHelper.push(context, const ForgotPasswordPage()),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: 'Log In',
                loading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 20),
              const AuthSocialDivider(),
              const SizedBox(height: 16),
              AuthGoogleButton(
                loading: _isGoogleLoading,
                onPressed: () => performGoogleSignIn(
                  context,
                  onLoadingChanged: (v) => setState(() => _isGoogleLoading = v),
                ),
              ),
              const SizedBox(height: 20),
              AuthLinkRow(
                prefix: "Don't have an account?",
                action: 'Sign Up',
                onTap: () => NavigationHelper.push(context, const SignUpPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
