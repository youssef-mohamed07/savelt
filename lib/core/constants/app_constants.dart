// ثوابت التطبيق - معلومات ثابتة تستخدم في كل التطبيق
// App Constants - Fixed values used throughout the app
class AppConstants {
  AppConstants._();

  // معلومات التطبيق - App info
  static const String appName = 'SaveIt'; // اسم التطبيق
  static const String appVersion = '1.0.0'; // رقم الإصدار

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);

  // Asset paths
  static const String moneyLottie = 'assets/Money.json';
  static const String microphoneLottie = 'assets/microphone.json';
  static const String scanReceiptLottie = 'assets/Scan a receipt.json';

  // Padding and margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 28.0;
  static const double radiusFull = 999.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;

  // Button heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;

  // Chart dimensions
  static const double chartHeight = 200.0;
  static const double chartPointRadius = 6.0;
  static const double chartLineWidth = 3.0;

  // Bottom navigation
  static const double bottomNavHeight = 65.0;

  // Card dimensions
  static const double cardMinHeight = 60.0;
  static const double offerCardWidth = 300.0;
  static const double offerCardHeight = 180.0;

  // Default dates
  static final DateTime defaultStartDate = DateTime(2024, 1, 1);

  // Database
  static const String databaseName = 'saveit_app.db';
  static const int databaseVersion = 1;

  // API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncDelay = Duration(seconds: 1);
}


