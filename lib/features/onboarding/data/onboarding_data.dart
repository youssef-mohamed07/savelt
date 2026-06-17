import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/onboarding_model.dart';

class OnboardingData {
  static List<OnboardingModel> getPages() {
    return [
      const OnboardingModel(
        lottieAsset: AppConstants.moneyLottie,
        title: 'Welcome to SaveIt',
        subtitle: 'Smarter money, better life.',
        description:
            'Keep track of your spending and stay in control with ease.',
        animationPadding: EdgeInsets.only(
          top: 60.0,
          left: 10.0,
          right: 10.0,
          bottom: 20.0,
        ),
      ),
      const OnboardingModel(
        lottieAsset: AppConstants.microphoneLottie,
        title: 'Talk, We Track',
        subtitle: 'Speak your spending and we will handle the rest.',
        description: 'No typing, no hassle.',
        animationPadding: EdgeInsets.only(
          top: 80.0,
          left: 30.0,
          right: 30.0,
          bottom: 40.0,
        ),
      ),
      const OnboardingModel(
        lottieAsset: AppConstants.scanReceiptLottie,
        title: 'Scan Your Receipts',
        subtitle:
            'Snap a photo of any bill and we will extract the details automatically',
        description: 'Fast, simple, and accurate.',
        animationPadding: EdgeInsets.only(
          top: 40.0,
          left: 0.0,
          right: 0.0,
          bottom: 5.0,
        ),
      ),
    ];
  }
}



