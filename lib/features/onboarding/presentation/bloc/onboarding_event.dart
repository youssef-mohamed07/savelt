// الأحداث (Events) - الأفعال اللي ممكن تحصل في الـ Onboarding
// Events - Actions that can happen in onboarding

import 'package:equatable/equatable.dart';

// Base class for all onboarding events
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

// Event: When user swipes or page changes
// حدث: لما المستخدم يعمل swipe أو الصفحة تتغير
class PageChanged extends OnboardingEvent {
  final int pageIndex;

  const PageChanged(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

// Event: When user clicks "Next" button
// حدث: لما المستخدم يضغط زر "Next"
class NextPageRequested extends OnboardingEvent {
  const NextPageRequested();
}

// Event: When user clicks "Back" button
// حدث: لما المستخدم يضغط زر "Back"
class PreviousPageRequested extends OnboardingEvent {
  const PreviousPageRequested();
}

// Event: When user clicks "Skip" button
// حدث: لما المستخدم يضغط زر "Skip"
class SkipRequested extends OnboardingEvent {
  const SkipRequested();
}

// Event: When user reaches last page and clicks "Get Started"
// حدث: لما المستخدم يوصل آخر صفحة ويضغط "Get Started"
class CompleteOnboarding extends OnboardingEvent {
  const CompleteOnboarding();
}
