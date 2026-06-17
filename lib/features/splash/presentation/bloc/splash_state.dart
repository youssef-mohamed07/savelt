// Splash State - حالات شاشة البداية
// Splash State - States for splash screen

import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

// Initial state - الحالة الأولية
// Initial state when splash starts
class SplashInitial extends SplashState {
  const SplashInitial();
}

// Loading state - حالة التحميل
// State while showing splash animation
class SplashLoading extends SplashState {
  const SplashLoading();
}

// Navigate state - حالة الانتقال
// State when it's time to navigate to next screen
class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();
}
