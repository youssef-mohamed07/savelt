import '../../features/reminders/models/reminder.dart';
import 'api_service.dart';

class ReminderApiService {
  static final ReminderApiService instance = ReminderApiService._internal();
  ReminderApiService._internal();
  factory ReminderApiService() => instance;

  final ApiService _api = ApiService();

  Future<ReminderListResult> fetchMy() async {
    final response = await _api.get('/reminders/my');
    if (!response.isSuccess || response.data is! Map) {
      return ReminderListResult.failure(
        message: response.message ?? 'Failed to load reminders',
      );
    }

    final map = response.data as Map<String, dynamic>;
    final raw = map['data'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => Reminder.fromApi(Map<String, dynamic>.from(e)))
            .toList()
        : <Reminder>[];

    return ReminderListResult.success(reminders: list);
  }

  Future<Reminder?> create(Reminder reminder) async {
    final response = await _api.post('/reminders', body: reminder.toApiBody());
    if (!response.isSuccess || response.data is! Map) return null;
    final data = (response.data as Map)['data'];
    if (data is! Map) return null;
    return Reminder.fromApi(Map<String, dynamic>.from(data));
  }

  Future<Reminder?> update(Reminder reminder) async {
    final response =
        await _api.put('/reminders/${reminder.id}', body: reminder.toApiBody());
    if (!response.isSuccess || response.data is! Map) return null;
    final data = (response.data as Map)['data'];
    if (data is! Map) return null;
    return Reminder.fromApi(Map<String, dynamic>.from(data));
  }

  Future<Reminder?> toggle(String id) async {
    final response = await _api.patch('/reminders/$id/toggle');
    if (!response.isSuccess || response.data is! Map) return null;
    final data = (response.data as Map)['data'];
    if (data is! Map) return null;
    return Reminder.fromApi(Map<String, dynamic>.from(data));
  }

  Future<bool> delete(String id) async {
    final response = await _api.delete('/reminders/$id');
    return response.isSuccess;
  }

  Future<bool> deleteMultiple(List<String> ids) async {
    final response = await _api.delete('/reminders/bulk', body: {'ids': ids});
    return response.isSuccess;
  }
}

class ReminderListResult {
  final bool isSuccess;
  final List<Reminder> reminders;
  final String? message;

  ReminderListResult._({
    required this.isSuccess,
    this.reminders = const [],
    this.message,
  });

  factory ReminderListResult.success({required List<Reminder> reminders}) {
    return ReminderListResult._(isSuccess: true, reminders: reminders);
  }

  factory ReminderListResult.failure({required String message}) {
    return ReminderListResult._(isSuccess: false, message: message);
  }
}
