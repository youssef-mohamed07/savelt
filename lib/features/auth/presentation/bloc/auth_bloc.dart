// Auth Bloc - منطق المصادقة (Authentication Business Logic)
// Auth Bloc - Business logic for authentication

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    // تسجيل معالجات الأحداث
    // Register event handlers

    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<FacebookSignInRequested>(_onFacebookSignInRequested);
  }

  // معالج تغيير الإيميل - Handler for email change
  void _onEmailChanged(EmailChanged event, Emitter<AuthState> emit) {
    final emailError = _validateEmail(event.email);
    final isFormValid =
        emailError == null && _validatePassword(state.password) == null;

    emit(
      state.copyWith(
        email: event.email,
        emailError: emailError,
        isFormValid: isFormValid,
      ),
    );
  }

  // معالج تغيير الباسورد - Handler for password change
  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    final passwordError = _validatePassword(event.password);
    final isFormValid =
        _validateEmail(state.email) == null && passwordError == null;

    emit(
      state.copyWith(
        password: event.password,
        passwordError: passwordError,
        isFormValid: isFormValid,
      ),
    );
  }

  // معالج إظهار/إخفاء الباسورد - Handler for password visibility toggle
  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  // معالج تسجيل الدخول - Handler for login submission
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // نتأكد من صحة البيانات أولاً
    // Validate data first
    final emailError = _validateEmail(event.email);
    final passwordError = _validatePassword(event.password);

    if (emailError != null || passwordError != null) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          emailError: emailError,
          passwordError: passwordError,
          errorMessage: 'Please fix the errors above',
        ),
      );
      return;
    }

    // نبدأ عملية تسجيل الدخول
    // Start login process
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // TODO: هنا هيتنفذ الكود الحقيقي لتسجيل الدخول
      // TODO: Here the actual login code will be executed
      // مثال: await authRepository.login(event.email, event.password);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // لو نجح تسجيل الدخول
      // If login succeeded
      emit(state.copyWith(status: AuthStatus.authenticated));
    } catch (error) {
      // لو حصل خطأ
      // If error occurred
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Login failed: ${error.toString()}',
        ),
      );
    }
  }

  // معالج تسجيل الخروج - Handler for logout
  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // معالج تسجيل الدخول بجوجل - Handler for Google Sign In
  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // TODO: تنفيذ تسجيل الدخول بجوجل
      // TODO: Implement Google Sign In
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: AuthStatus.authenticated));
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Google Sign In failed: ${error.toString()}',
        ),
      );
    }
  }

  // معالج تسجيل الدخول بفيسبوك - Handler for Facebook Sign In
  Future<void> _onFacebookSignInRequested(
    FacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // TODO: تنفيذ تسجيل الدخول بفيسبوك
      // TODO: Implement Facebook Sign In
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: AuthStatus.authenticated));
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Facebook Sign In failed: ${error.toString()}',
        ),
      );
    }
  }

  // دالة للتحقق من صحة الإيميل - Function to validate email
  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    // Regular expression للتحقق من صيغة الإيميل
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null; // null = لا يوجد خطأ - null = no error
  }

  // دالة للتحقق من صحة الباسورد - Function to validate password
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null; // null = لا يوجد خطأ - null = no error
  }
}
