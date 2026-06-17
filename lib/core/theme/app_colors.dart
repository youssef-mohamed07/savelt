import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // Secondary Colors
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryLight = Color(0xFF62EFFF);
  static const Color secondaryDark = Color(0xFF008BA3);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F3F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Category Colors
  static const Color foodColor = Color(0xFFFF5722);
  static const Color transportColor = Color(0xFF3F51B5);
  static const Color shoppingColor = Color(0xFFE91E63);
  static const Color healthColor = Color(0xFF4CAF50);
  static const Color educationColor = Color(0xFF9C27B0);
  static const Color entertainmentColor = Color(0xFFFF9800);
  static const Color billsColor = Color(0xFF607D8B);
  static const Color othersColor = Color(0xFF795548);
  
  // Chart Colors
  static const Color chartBar1 = Color(0xFF4CAF50);
  static const Color chartBar2 = Color(0xFF2196F3);
  
  // Card Background
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Gradients
  static const LinearGradient shoppingGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient billsGradient = LinearGradient(
    colors: [Color(0xFF607D8B), Color(0xFF455A64)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient healthGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient foodGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFD84315)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient educationGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Additional gradients
  static const LinearGradient notificationGradient = LinearGradient(
    colors: [Color(0xFF0814F9), Color(0xFFF509D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Input colors
  static const Color inputBackground = Color(0xFFF3F4F6);
}