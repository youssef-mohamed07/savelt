import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../domain/models/onboarding_model.dart';
import '../../../../../core/theme/app_colors.dart';

class OnboardingPageItem extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPageItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top circular section with animation
        Expanded(
          flex: 7,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEEEEEE), Color(0xFFDEDFE2)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(400),
                bottomRight: Radius.circular(400),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding:
                  model.animationPadding ??
                  const EdgeInsets.only(
                    top: 60.0,
                    left: 10.0,
                    right: 10.0,
                    bottom: 20.0,
                  ),
              child: model.lottieAsset != null
                  ? Lottie.asset(model.lottieAsset!, fit: BoxFit.contain)
                  : const Icon(
                      Icons.error,
                      size: 220,
                      color: AppColors.secondary,
                    ),
            ),
          ),
        ),
        // Bottom section with text
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    model.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                  if (model.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      model.subtitle!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    model.description,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A6C7D),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}



