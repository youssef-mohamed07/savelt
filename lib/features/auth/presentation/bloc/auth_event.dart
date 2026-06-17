// Auth Events - أحداث المصادقة (Authentication)
// Auth Events - Events for authentication

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Event: Email changed - تغيير الإيميل
class EmailChanged extends AuthEvent {
  final String email;

  const EmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

// Event: Password changed - تغيير الباسورد
class PasswordChanged extends AuthEvent {
  final String password;

  const PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

// Event: Toggle password visibility - إظهار/إخفاء الباسورد
class PasswordVisibilityToggled extends AuthEvent {
  const PasswordVisibilityToggled();
}

// Event: Login button pressed - الضغط على زر تسجيل الدخول
class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// Event: Logout - تسجيل الخروج
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

// Event: Google Sign In - تسجيل الدخول بجوجل
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

// Event: Facebook Sign In - تسجيل الدخول بفيسبوك
class FacebookSignInRequested extends AuthEvent {
  const FacebookSignInRequested();
}
