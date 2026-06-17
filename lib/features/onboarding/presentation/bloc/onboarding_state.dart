// الحالات (States) - الأوضاع المختلفة للـ Onboarding
// States - Different states of the onboarding screen

import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  final int currentPage; // الصفحة الحالية (Current page index)
  final int totalPages; // إجمالي عدد الصفحات (Total number of pages)
  final bool isLastPage; // هل دي آخر صفحة؟ (Is this the last page?)
  final bool isFirstPage; // هل دي أول صفحة؟ (Is this the first page?)
  final bool
  shouldNavigateToAuth; // لازم ننتقل للـ Auth؟ (Should navigate to auth?)

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.isLastPage = false,
    this.isFirstPage = true,
    this.shouldNavigateToAuth = false,
  });

  // دالة لعمل نسخة من الـ State مع تغيير بعض القيم
  // Function to create a copy of state with some values changed
  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isLastPage,
    bool? isFirstPage,
    bool? shouldNavigateToAuth,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLastPage: isLastPage ?? this.isLastPage,
      isFirstPage: isFirstPage ?? this.isFirstPage,
      shouldNavigateToAuth: shouldNavigateToAuth ?? this.shouldNavigateToAuth,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    isLastPage,
    isFirstPage,
    shouldNavigateToAuth,
  ];
}
