import 'dart:io';
import 'package:flutter/foundation.dart';

// API Configuration — device-aware URLs
class ApiConfig {
  // ── Backend base URL ────────────────────────────────────────────────────────
  // localhost    = iOS Simulator / macOS
  // 10.0.2.2     = Android emulator → host machine localhost
  // _pcLanIp     = Real phone on same WiFi → your Mac's LAN IP
  static const bool _useRealDevice = false; // true = physical device, false = simulators
  static const String _pcLanIp = '192.168.1.30'; // update to your Mac's current WiFi IP

  static String get _host {
    if (_useRealDevice) return _pcLanIp;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost'; // iOS simulator, macOS, etc.
  }

  static String get baseUrl => 'http://$_host:3001';

  // ── AI Server (voice + OCR unified on port 8000) ─────────────────────────────
  static String get aiBaseUrl => 'http://$_host:8000';
  static String get voiceApiBaseUrl => aiBaseUrl;
  static const String voiceAnalyzeText  = '/analyze';
  static const String voiceAnalyzeAudio = '/voice';

  // OCR runs on the same unified AI server
  static String get ocrBaseUrl => aiBaseUrl;

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String authSignup          = '/auth/signup';
  static const String authConfirmOtp      = '/auth/signup/configurationOTP';
  static const String authSignin          = '/auth/signin';
  static const String authChangePassword  = '/auth/changePassword';
  static const String authResendOtp       = '/auth/resendOTP';
  static const String authForgetPassword  = '/auth/forgetPassword';
  static const String authSetNewPassword  = '/auth/setNewPassword';
  static const String authProfile         = '/auth/profile';
  static const String authDeleteAccount   = '/auth/account';

  // ── Transactions ────────────────────────────────────────────────────────────
  static const String transactions            = '/transactions';
  static const String transactionsWithText    = '/transactions/createWithText';
  static const String transactionsMy         = '/transactions/my';
  static const String transactionsByCategory = '/transactions/category';
  static const String transactionsByDateRange = '/transactions/date-range';

  // ── Categories ──────────────────────────────────────────────────────────────
  static const String categories = '/category';

  // ── Items ───────────────────────────────────────────────────────────────────
  static const String items                   = '/items';
  static const String itemsAddToCategory      = '/items/add-to-category';
  static const String itemsRemoveFromCategory = '/items/remove-from-category';

  // ── Analytics ───────────────────────────────────────────────────────────────
  static const String analyticsSummary      = '/analytics/summary';
  static const String analyticsByCategory   = '/analytics/by-category';
  static const String analyticsByDate       = '/analytics/by-date';
  static const String analyticsTopCategories = '/analytics/top-categories';
  static const String analyticsTrends       = '/analytics/trends';

  // ── Offers ──────────────────────────────────────────────────────────────────
  static const String offers        = '/api/offers';
  static const String offersPreview = '/api/offers/preview';

  // ── Export ──────────────────────────────────────────────────────────────────
  static const String export = '/export';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const String notificationsMy = '/notifications/my';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsClearAll = '/notifications/clear-all';
  static const String notificationsReadAll = '/notifications/read-all';

  // ── Reminders ───────────────────────────────────────────────────────────────
  static const String remindersMy = '/reminders/my';

  // ── Health ──────────────────────────────────────────────────────────────────
  static const String healthCheck = '/api';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout    = Duration(seconds: 15);
}
