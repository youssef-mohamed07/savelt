import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../models/reminder.dart';
import 'reminder_ui_helpers.dart';

Future<void> showReminderFormSheet(
  BuildContext context, {
  required ReminderBloc bloc,
  Reminder? existing,
}) async {
  final isEdit = existing != null;
  var title = existing?.title ?? '';
  var amount = existing?.amount;
  var selectedDate =
      existing?.date ?? DateTime.now().add(const Duration(hours: 1));
  var selectedTime = TimeOfDay.fromDateTime(selectedDate);
  var repeat = existing?.repeat ?? 'Once';
  var selectedIcon = existing?.icon ?? Icons.notifications_rounded;
  var selectedSound = existing?.sound ?? ReminderSound.defaultSound;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        if (isEdit)
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (d) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Delete reminder?'),
                                  content: Text('Delete "${existing.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(d, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(d, true),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                bloc.add(DeleteReminder(existing.id));
                              }
                            },
                            child: Text('Delete',
                                style: GoogleFonts.inter(color: Colors.red)),
                          )
                        else
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                          ),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Reminder' : 'New Reminder',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (title.trim().isEmpty) return;
                            HapticFeedback.lightImpact();
                            final dateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            if (isEdit) {
                              bloc.add(UpdateReminder(Reminder(
                                id: existing.id,
                                title: title.trim(),
                                amount: amount,
                                date: dateTime,
                                repeat: repeat,
                                enabled: existing.enabled,
                                icon: selectedIcon,
                                sound: selectedSound,
                              )));
                            } else {
                              bloc.add(AddReminder(Reminder(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: title.trim(),
                                amount: amount,
                                date: dateTime,
                                repeat: repeat,
                                enabled: true,
                                icon: selectedIcon,
                                sound: selectedSound,
                              )));
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              color: ReminderColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Icon',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF64748B))),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: reminderIconOptions.map((icon) {
                              final selected = selectedIcon == icon;
                              final color = reminderIconColor(icon, enabled: true);
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedIcon = icon),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: selected ? color : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? color : ReminderColors.border,
                                    ),
                                  ),
                                  child: Icon(icon,
                                      color: selected ? Colors.white : color, size: 22),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          _field(
                            label: 'Title *',
                            hint: 'e.g. Electricity Bill',
                            initial: isEdit ? title : null,
                            onChanged: (v) => title = v,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Amount (optional)',
                            hint: '350',
                            suffix: 'EGP',
                            keyboard: TextInputType.number,
                            initial: amount?.toStringAsFixed(0),
                            onChanged: (v) => amount = double.tryParse(v),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _pickerTile(
                                  icon: Icons.calendar_today_rounded,
                                  label:
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (date != null) {
                                      setModalState(() => selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pickerTile(
                                  icon: Icons.access_time_rounded,
                                  label:
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: ctx,
                                      initialTime: selectedTime,
                                    );
                                    if (time != null) {
                                      setModalState(() => selectedTime = time);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text('Repeat',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Once', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                                .map((opt) {
                              final selected = repeat == opt;
                              return GestureDetector(
                                onTap: () => setModalState(() => repeat = opt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? ReminderColors.navy
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? ReminderColors.navy
                                          : ReminderColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Sound',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ReminderSound.values.map((sound) {
                              final selected = selectedSound == sound;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedSound = sound),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? ReminderColors.navy
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? ReminderColors.navy
                                          : ReminderColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(sound.icon,
                                          size: 16,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        sound.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _field({
  required String label,
  required String hint,
  String? suffix,
  TextInputType? keyboard,
  String? initial,
  required ValueChanged<String> onChanged,
}) {
  return TextField(
    controller: initial != null ? TextEditingController(text: initial) : null,
    keyboardType: keyboard,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ReminderColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ReminderColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ReminderColors.navy, width: 1.5),
      ),
    ),
  );
}

Widget _pickerTile({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReminderColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ReminderColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}
