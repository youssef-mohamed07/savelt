import 'package:flutter_bloc/flutter_bloc.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';
import '../../../core/services/reminder_api_service.dart';
import '../../../services/notification_service.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final NotificationService _notificationService = NotificationService();
  final ReminderApiService _api = ReminderApiService.instance;

  ReminderBloc() : super(const ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
    on<UpdateReminder>(_onUpdateReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<ToggleReminder>(_onToggleReminder);
    on<DeleteMultipleReminders>(_onDeleteMultiple);

    add(const LoadReminders());
  }

  Future<void> _onLoadReminders(
      LoadReminders event, Emitter<ReminderState> emit) async {
    emit(const ReminderLoading());

    final result = await _api.fetchMy();
    if (!result.isSuccess) {
      emit(ReminderError(result.message ?? 'Failed to load reminders'));
      return;
    }

    for (final reminder in result.reminders) {
      if (reminder.enabled) {
        await _notificationService.scheduleReminder(reminder);
      }
    }

    emit(ReminderLoaded(result.reminders));
  }

  Future<void> _onAddReminder(
      AddReminder event, Emitter<ReminderState> emit) async {
    final created = await _api.create(event.reminder);
    if (created == null) return;

    if (created.enabled) {
      await _notificationService.scheduleReminder(created);
    }

    if (state is ReminderLoaded) {
      final current = state as ReminderLoaded;
      emit(ReminderLoaded([created, ...current.reminders]));
    } else {
      emit(ReminderLoaded([created]));
    }
  }

  Future<void> _onUpdateReminder(
      UpdateReminder event, Emitter<ReminderState> emit) async {
    final updated = await _api.update(event.reminder);
    if (updated == null) return;

    await _notificationService.cancelReminder(updated.id);
    if (updated.enabled) {
      await _notificationService.scheduleReminder(updated);
    }

    if (state is ReminderLoaded) {
      final current = state as ReminderLoaded;
      emit(ReminderLoaded(
        current.reminders
            .map((r) => r.id == updated.id ? updated : r)
            .toList(),
      ));
    }
  }

  Future<void> _onDeleteReminder(
      DeleteReminder event, Emitter<ReminderState> emit) async {
    final ok = await _api.delete(event.id);
    if (!ok) return;

    await _notificationService.cancelReminder(event.id);

    if (state is ReminderLoaded) {
      final current = state as ReminderLoaded;
      emit(ReminderLoaded(
        current.reminders.where((r) => r.id != event.id).toList(),
      ));
    }
  }

  Future<void> _onToggleReminder(
      ToggleReminder event, Emitter<ReminderState> emit) async {
    final updated = await _api.toggle(event.id);
    if (updated == null) return;

    if (updated.enabled) {
      await _notificationService.scheduleReminder(updated);
    } else {
      await _notificationService.cancelReminder(updated.id);
    }

    if (state is ReminderLoaded) {
      final current = state as ReminderLoaded;
      emit(ReminderLoaded(
        current.reminders
            .map((r) => r.id == updated.id ? updated : r)
            .toList(),
      ));
    }
  }

  Future<void> _onDeleteMultiple(
      DeleteMultipleReminders event, Emitter<ReminderState> emit) async {
    final ok = await _api.deleteMultiple(event.ids);
    if (!ok) return;

    for (final id in event.ids) {
      await _notificationService.cancelReminder(id);
    }

    if (state is ReminderLoaded) {
      final current = state as ReminderLoaded;
      emit(ReminderLoaded(
        current.reminders.where((r) => !event.ids.contains(r.id)).toList(),
      ));
    }
  }
}
