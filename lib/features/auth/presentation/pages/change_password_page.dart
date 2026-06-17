import 'package:flutter/material.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/auth_ui.dart';
import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ChangePasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _auth = AuthApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.otp.isEmpty) {
      showAuthSnackBar(context, 'Invalid reset code. Request a new one.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _auth.setNewPassword(
      email: widget.email,
      otp: widget.otp,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      showAuthSnackBar(context, 'Password changed successfully', isError: false);
      NavigationHelper.pushReplacement(context, const LoginPage());
    } else {
      showAuthSnackBar(context, result.message ?? 'Failed to change password');
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Security',
      title: 'New password',
      subtitle: 'Choose a new password for ${widget.email}',
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPasswordField(
                label: 'New password',
                controller: _newPasswordController,
                isVisible: _isNewPasswordVisible,
                onToggle: () =>
                    setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthPasswordField(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirm your password';
                  if (value != _newPasswordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Save new password',
                loading: _isLoading,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
