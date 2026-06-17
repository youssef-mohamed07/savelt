import 'package:flutter/material.dart';

/// @deprecated Use AppColors from core/theme/app_colors.dart instead
/// This file is kept for backward compatibility only
///
/// Migration:
/// - Replace `ColorsManager.black` with `AppColors.black`
/// - Replace `ColorsManager.black1A` with `AppColors.black` (or add to AppColors)
@Deprecated('Use AppColors from core/theme/app_colors.dart instead')
class ColorsManager {
  static const Color black = Color(0xFF363130);
  static const Color black1A = Color(0xFF1A1A1A);
}


