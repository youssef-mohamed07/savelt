import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/auth_ui.dart';
import 'login_page.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (!_formKey.currentState!.validate()) return;
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AuthColors.navy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AuthColors.navy, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                'Password updated',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AuthColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AuthColors.muted),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Go to Log In',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  NavigationHelper.pushReplacement(context, const LoginPage());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Security',
      title: 'Set new password',
      subtitle: 'Choose a strong password for your account',
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
                label: 'Save password',
                onPressed: _handleChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
