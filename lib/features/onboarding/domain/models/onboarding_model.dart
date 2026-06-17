import 'package:flutter/material.dart';

class OnboardingModel {
  final String? lottieAsset;
  final String title;
  final String? subtitle;
  final String description;
  final EdgeInsets? animationPadding;

  const OnboardingModel({
    this.lottieAsset,
    required this.title,
    this.subtitle,
    required this.description,
    this.animationPadding,
  });
}



