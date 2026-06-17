// Auth State - حالات المصادقة (Authentication States)
// Auth State - States for authentication

import 'package:equatable/equatable.dart';

// Enum للحالات المختلفة - Enum for different states
enum AuthStatus {
  initial, // أول ما يفتح التطبيق - Initial state
  loading, // أثناء تسجيل الدخول - During login
  authenticated, // مسجل دخول بنجاح - Successfully authenticated
  unauthenticated, // غير مسجل - Not authenticated
  error, // حصل خطأ - Error occurred
}

class AuthState extends Equatable {
  final AuthStatus status; // الحالة الحالية - Current status
  final String email; // الإيميل المدخل - Entered email
  final String password; // الباسورد المدخل - Entered password
  final bool isPasswordVisible; // هل الباسورد ظاهر؟ - Is password visible?
  final String? emailError; // خطأ في الإيميل - Email error message
  final String? passwordError; // خطأ في الباسورد - Password error message
  final String? errorMessage; // رسالة الخطأ العامة - General error message
  final bool isFormValid; // هل الفورم صحيحة؟ - Is form valid?

  const AuthState({
    this.status = AuthStatus.initial,
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.emailError,
    this.passwordError,
    this.errorMessage,
    this.isFormValid = false,
  });

  // نسخ الـ State مع تغيير بعض القيم
  // Copy state with some values changed
  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? password,
    bool? isPasswordVisible,
    String? emailError,
    String? passwordError,
    String? errorMessage,
    bool? isFormValid,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      emailError: emailError,
      passwordError: passwordError,
      errorMessage: errorMessage,
      isFormValid: isFormValid ?? this.isFormValid,
    );
  }

  @override
  List<Object?> get props => [
    status,
    email,
    password,
    isPasswordVisible,
    emailError,
    passwordError,
    errorMessage,
    isFormValid,
  ];
}
