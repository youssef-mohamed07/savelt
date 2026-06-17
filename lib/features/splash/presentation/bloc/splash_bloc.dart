// Splash Bloc - منطق شاشة البداية
// Splash Bloc - Business logic for splash screen

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    // معالج حدث بدء المؤقت
    // Handler for starting the timer
    on<StartSplashTimer>(_onStartSplashTimer);
  }

  // دالة معالجة بدء المؤقت
  // Function to handle timer start
  Future<void> _onStartSplashTimer(
    StartSplashTimer event,
    Emitter<SplashState> emit,
  ) async {
    // نعرض حالة التحميل أولاً
    // Show loading state first
    emit(const SplashLoading());

    // ننتظر مدة الـ Splash
    // Wait for splash duration
    await Future.delayed(AppConstants.splashDuration);

    // بعد انتهاء المدة، ننتقل للـ Onboarding
    // After duration ends, navigate to onboarding
    emit(const SplashNavigateToOnboarding());
  }
}
