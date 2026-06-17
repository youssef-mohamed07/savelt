import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../features/reminders/models/reminder.dart';
import '../core/services/notification_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Notification history
  final List<NotificationItem> _notificationHistory = [];
  List<NotificationItem> get notificationHistory => List.unmodifiable(_notificationHistory);

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific page
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Schedule a reminder notification
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.enabled) return;

    final scheduledDate = tz.TZDateTime.from(reminder.date, tz.local);
    
    // Don't schedule if date is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _getChannelForSound(reminder.sound),
      _getChannelNameForSound(reminder.sound),
      channelDescription: 'Financial reminders and bills',
      importance: Importance.high,
      priority: Priority.high,
      playSound: reminder.sound != ReminderSound.silent,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      // Use system default sound - no custom sound needed
      sound: null,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: reminder.sound != ReminderSound.silent ? 'default' : null,
      presentAlert: true,
      presentBadge: true,
      presentSound: reminder.sound != ReminderSound.silent,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.amount != null 
          ? '${reminder.amount!.toStringAsFixed(0)} EGP' 
          : 'Reminder',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );

    // Handle repeat
    if (reminder.repeat != 'Once') {
      _scheduleRepeatingReminder(reminder, scheduledDate);
    }
  }

  String _getChannelForSound(ReminderSound sound) {
    switch (sound) {
      case ReminderSound.defaultSound:
        return 'reminders_default';
      case ReminderSound.alarm1:
        return 'reminders_alarm';
      case ReminderSound.alarm2:
        return 'reminders_alarm2';
      case ReminderSound.gentle:
        return 'reminders_gentle';
      case ReminderSound.silent:
        return 'reminders_silent';
    }
  }

  String _getChannelNameForSound(ReminderSound sound) {
    switch (sound) {
      case ReminderSound.defaultSound:
        return 'Reminders';
      case ReminderSound.alarm1:
        return 'Reminders (Alarm)';
      case ReminderSound.alarm2:
        return 'Reminders (Alarm 2)';
      case ReminderSound.gentle:
        return 'Reminders (Gentle)';
      case ReminderSound.silent:
        return 'Reminders (Silent)';
    }
  }

  void _scheduleRepeatingReminder(Reminder reminder, tz.TZDateTime firstDate) {
    // For repeating reminders, we'll reschedule when the notification fires
    // This is handled by the app when it receives the notification
  }

  // Cancel a scheduled notification
  Future<void> cancelReminder(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'For testing notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Test Notification',
      'This is a test notification!',
      details,
    );

    // Persist to backend inbox
    await NotificationApiService.instance.create(
      title: 'Test Notification',
      body: 'This is a test notification!',
      type: 'system',
    );
  }

  // Add notification to history
  void _addToHistory(NotificationItem item) {
    _notificationHistory.insert(0, item);
    // Keep only last 50 notifications
    if (_notificationHistory.length > 50) {
      _notificationHistory.removeLast();
    }
  }

  // Add notification to history (public method for when notification fires)
  void addNotificationToHistory(String title, String body) {
    _addToHistory(NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    ));
  }

  // Clear notification history
  void clearHistory() {
    _notificationHistory.clear();
  }

  // Mark notification as read
  void markAsRead(String id) {
    final index = _notificationHistory.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
    }
  }

  // Delete notification from history
  void deleteFromHistory(String id) {
    _notificationHistory.removeWhere((n) => n.id == id);
  }
}

// Notification history item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
