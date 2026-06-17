import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/auth_api_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/auth_ui.dart';
import 'change_password_page.dart';

enum OtpPurpose { signup, passwordReset }

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;

  const OtpVerificationPage({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.signup,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthApiService.instance;
  bool _isLoading = false;
  bool _isResending = false;

  bool get _isReset => widget.purpose == OtpPurpose.passwordReset;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpCode.length == 6) _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      showAuthSnackBar(context, 'Please enter the full 6-digit code', isError: false);
      return;
    }

    if (_isReset) {
      NavigationHelper.pushReplacement(
        context,
        ChangePasswordPage(
          email: widget.email,
          otp: _otpCode,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.confirmOtp(_otpCode);
      if (!mounted) return;
      if (result.isSuccess) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        showAuthSnackBar(context, result.message ?? 'OTP verification failed');
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) showAuthSnackBar(context, 'Verification error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final result = _isReset
          ? await _authService.forgetPassword(widget.email)
          : await _authService.resendOtp(widget.email);
      if (!mounted) return;
      showAuthSnackBar(
        context,
        result.message ?? 'Code sent',
        isError: !result.isSuccess,
      );
    } catch (e) {
      if (mounted) showAuthSnackBar(context, 'Resend error: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: _isReset ? 'Security' : 'Verify',
      title: _isReset ? 'Enter reset code' : 'Check your email',
      subtitle: _isReset
          ? 'Enter the 6-digit code we sent to\n${widget.email}'
          : 'Enter the 6-digit code sent to\n${widget.email}',
      child: AuthCard(
        child: Column(
          children: [
            if (_isReset)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: AuthBanner.info(
                  message: 'The code expires in 10 minutes.',
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 46,
                  height: 54,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AuthColors.text,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AuthColors.fieldFill,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AuthColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AuthColors.navy, width: 1.5),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onOtpChanged(value, index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: _isReset ? 'Continue' : 'Verify',
              loading: _isLoading,
              onPressed: _verifyOtp,
            ),
            const SizedBox(height: 12),
            AuthLinkRow(
              prefix: "Didn't receive code?",
              action: _isResending ? 'Sending…' : 'Resend',
              onTap: _isResending ? () {} : _resendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
