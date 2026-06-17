import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reminder.dart';
import 'reminder_ui_helpers.dart';

class ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<bool>? onSelectChanged;

  const ReminderTile({
    super.key,
    required this.reminder,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onToggle,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = reminder.enabled;
    final iconColor = reminderIconColor(reminder.icon, enabled: enabled);
    final iconBg = reminderIconBg(reminder.icon, enabled: enabled);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ReminderColors.navy.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ReminderColors.navy
                : (enabled ? ReminderColors.border : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: ReminderColors.navy.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.72,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: enabled ? iconColor : const Color(0xFFCBD5E1),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(reminder.icon, color: iconColor, size: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: enabled
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (reminder.amount != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '${reminder.amount!.toStringAsFixed(0)} EGP',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: enabled
                                        ? ReminderColors.navy
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: enabled
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      formatReminderDate(reminder.date),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: enabled
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (reminder.repeat != 'Once') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: enabled
                                            ? ReminderColors.navy
                                                .withValues(alpha: 0.1)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        reminder.repeat,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: enabled
                                              ? ReminderColors.navy
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelectionMode)
                          Checkbox(
                            value: isSelected,
                            onChanged: (v) => onSelectChanged?.call(v ?? false),
                            activeColor: ReminderColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          )
                        else
                          Transform.scale(
                            scale: 0.85,
                            child: Switch.adaptive(
                              value: reminder.enabled,
                              onChanged: onToggle,
                              activeTrackColor: ReminderColors.navy,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
