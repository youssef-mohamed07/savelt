// OnboardingBloc - العقل المدبر اللي بيتحكم في الـ Onboarding
// OnboardingBloc - The brain that controls the onboarding logic

import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  // Constructor - بنبدأ بـ initial state (صفحة 0)
  OnboardingBloc() : super(const OnboardingState()) {
    // Register event handlers
    // تسجيل معالجات الأحداث

    // لما الصفحة تتغير (سواء بـ swipe أو زر)
    // When page changes (either by swipe or button)
    on<PageChanged>(_onPageChanged);

    // لما المستخدم يضغط "Next"
    // When user clicks "Next"
    on<NextPageRequested>(_onNextPageRequested);

    // لما المستخدم يضغط "Back"
    // When user clicks "Back"
    on<PreviousPageRequested>(_onPreviousPageRequested);

    // لما المستخدم يضغط "Skip"
    // When user clicks "Skip"
    on<SkipRequested>(_onSkipRequested);

    // لما المستخدم يخلص الـ Onboarding
    // When user completes onboarding
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  // معالج حدث تغيير الصفحة
  // Handler for page change event
  void _onPageChanged(PageChanged event, Emitter<OnboardingState> emit) {
    emit(
      state.copyWith(
        currentPage: event.pageIndex,
        isFirstPage: event.pageIndex == 0,
        isLastPage: event.pageIndex == state.totalPages - 1,
        shouldNavigateToAuth: false, // Reset navigation flag
      ),
    );
  }

  // معالج حدث الضغط على "Next"
  // Handler for "Next" button press
  void _onNextPageRequested(
    NextPageRequested event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isLastPage) {
      // لو في آخر صفحة، خلص الـ Onboarding
      // If on last page, complete onboarding
      add(const CompleteOnboarding());
    } else {
      // لو مش آخر صفحة، روح للصفحة التالية
      // If not last page, go to next page
      final nextPage = state.currentPage + 1;
      emit(
        state.copyWith(
          currentPage: nextPage,
          isFirstPage: false,
          isLastPage: nextPage == state.totalPages - 1,
        ),
      );
    }
  }

  // معالج حدث الضغط على "Back"
  // Handler for "Back" button press
  void _onPreviousPageRequested(
    PreviousPageRequested event,
    Emitter<OnboardingState> emit,
  ) {
    if (!state.isFirstPage) {
      final previousPage = state.currentPage - 1;
      emit(
        state.copyWith(
          currentPage: previousPage,
          isFirstPage: previousPage == 0,
          isLastPage: false,
        ),
      );
    }
  }

  // معالج حدث الضغط على "Skip"
  // Handler for "Skip" button press
  void _onSkipRequested(SkipRequested event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(shouldNavigateToAuth: true));
  }

  // معالج حدث إنهاء الـ Onboarding
  // Handler for completing onboarding
  void _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(shouldNavigateToAuth: true));
  }
}
