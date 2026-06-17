import 'api_service.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  static final NotificationApiService instance =
      NotificationApiService._internal();
  NotificationApiService._internal();
  factory NotificationApiService() => instance;

  final ApiService _api = ApiService();

  Future<NotificationListResult> fetchMy({int limit = 50}) async {
    final response = await _api.get('/notifications/my', queryParams: {
      'limit': limit.toString(),
    });

    if (!response.isSuccess || response.data is! Map) {
      return NotificationListResult.failure(
        message: response.message ?? 'Failed to load notifications',
      );
    }

    final map = response.data as Map<String, dynamic>;
    final raw = map['data'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <AppNotification>[];

    return NotificationListResult.success(
      notifications: list,
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    if (!response.isSuccess || response.data is! Map) return 0;
    return (response.data as Map)['unreadCount'] as int? ?? 0;
  }

  Future<bool> markAsRead(String id) async {
    final response = await _api.patch('/notifications/$id/read');
    return response.isSuccess;
  }

  Future<bool> markAllAsRead() async {
    final response = await _api.patch('/notifications/read-all');
    return response.isSuccess;
  }

  Future<bool> deleteNotification(String id) async {
    final response = await _api.delete('/notifications/$id');
    return response.isSuccess;
  }

  Future<bool> clearAll() async {
    final response = await _api.delete('/notifications/clear-all');
    return response.isSuccess;
  }

  Future<bool> create({
    required String title,
    required String body,
    String type = 'system',
    String? referenceId,
  }) async {
    final response = await _api.post('/notifications', body: {
      'title': title,
      'body': body,
      'type': type,
      if (referenceId != null) 'referenceId': referenceId,
    });
    return response.isSuccess;
  }
}

class NotificationListResult {
  final bool isSuccess;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? message;

  NotificationListResult._({
    required this.isSuccess,
    this.notifications = const [],
    this.unreadCount = 0,
    this.message,
  });

  factory NotificationListResult.success({
    required List<AppNotification> notifications,
    required int unreadCount,
  }) {
    return NotificationListResult._(
      isSuccess: true,
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  factory NotificationListResult.failure({required String message}) {
    return NotificationListResult._(isSuccess: false, message: message);
  }
}
