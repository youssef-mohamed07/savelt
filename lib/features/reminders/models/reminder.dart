import 'package:flutter/material.dart';

enum ReminderSound {
  defaultSound('Default', Icons.notifications_active),
  alarm1('Alarm', Icons.alarm),
  alarm2('Alert', Icons.warning_amber_rounded),
  gentle('Gentle', Icons.music_note),
  silent('Silent', Icons.notifications_off);

  final String label;
  final IconData icon;
  const ReminderSound(this.label, this.icon);
}

class Reminder {
  final String id;
  final String title;
  final double? amount;
  final DateTime date;
  final String repeat;
  final bool enabled;
  final IconData icon;
  final ReminderSound sound;

  const Reminder({
    required this.id,
    required this.title,
    this.amount,
    required this.date,
    required this.repeat,
    required this.enabled,
    required this.icon,
    this.sound = ReminderSound.defaultSound,
  });

  Reminder copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? repeat,
    bool? enabled,
    IconData? icon,
    ReminderSound? sound,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      sound: sound ?? this.sound,
    );
  }

  Map<String, dynamic> toApiBody() {
    return {
      'title': title,
      if (amount != null) 'amount': amount,
      'date': date.toIso8601String(),
      'repeat': repeat,
      'enabled': enabled,
      'iconCode': icon.codePoint,
      'sound': sound.name,
    };
  }

  factory Reminder.fromApi(Map<String, dynamic> map) {
    final iconCode = map['iconCode'] as int? ?? Icons.notifications_rounded.codePoint;
    final soundName = map['sound']?.toString() ?? 'defaultSound';
    final sound = ReminderSound.values.firstWhere(
      (s) => s.name == soundName,
      orElse: () => ReminderSound.defaultSound,
    );

    return Reminder(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble(),
      date: DateTime.parse(map['date'].toString()),
      repeat: map['repeat']?.toString() ?? 'Once',
      enabled: map['enabled'] != false,
      icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
      sound: sound,
    );
  }
}
