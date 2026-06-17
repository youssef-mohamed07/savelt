import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDatePickerColors {
  static const navy = Color(0xFF0D5DB8);
  static const navyLight = Color(0xFF1478E0);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}

/// Branded date picker matching the app design system.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select date',
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: title,
    cancelText: 'Cancel',
    confirmText: 'Done',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppDatePickerColors.navy,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppDatePickerColors.text,
            secondary: AppDatePickerColors.navyLight,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            elevation: 12,
            shadowColor: AppDatePickerColors.navy.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppDatePickerColors.navy,
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            headerBackgroundColor: AppDatePickerColors.navy,
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            headerHelpStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
            weekdayStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppDatePickerColors.muted,
            ),
            dayStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            yearStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            todayForegroundColor: WidgetStateProperty.all(AppDatePickerColors.navy),
            todayBackgroundColor: WidgetStateProperty.all(
              AppDatePickerColors.navy.withValues(alpha: 0.1),
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppDatePickerColors.text;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppDatePickerColors.navy;
              }
              return Colors.transparent;
            }),
            rangeSelectionBackgroundColor:
                AppDatePickerColors.navy.withValues(alpha: 0.12),
            rangeSelectionOverlayColor: WidgetStateProperty.all(
              AppDatePickerColors.navy.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isToday(DateTime? value) => isSameDay(value, DateTime.now());

String formatDisplayDate(DateTime? date) {
  if (date == null) return 'Select';
  if (isToday(date)) return 'Today';
  return '${date.day}/${date.month}/${date.year}';
}

/// Branded time picker matching the app design system.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Select time',
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: title,
    cancelText: 'Cancel',
    confirmText: 'Done',
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppDatePickerColors.navy,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppDatePickerColors.text,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            dialHandColor: AppDatePickerColors.navy,
            dialBackgroundColor: AppDatePickerColors.navy.withValues(alpha: 0.08),
            hourMinuteTextStyle: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
            helpTextStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppDatePickerColors.muted,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppDatePickerColors.navy,
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

String formatDisplayTime(TimeOfDay? time) {
  if (time == null) return 'Select';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
