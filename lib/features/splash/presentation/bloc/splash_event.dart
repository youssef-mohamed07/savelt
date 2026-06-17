// Splash Events - أحداث شاشة البداية
// Splash Events - Events for splash screen

import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

// Event: Start splash timer
// حدث: بدء مؤقت الـ Splash
class StartSplashTimer extends SplashEvent {
  const StartSplashTimer();
}
