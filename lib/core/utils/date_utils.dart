import 'package:flutter/material.dart';

/// Date formatting utilities
/// Extracted from UI to maintain single responsibility
class DateUtils {
  DateUtils._();

  /// Get month name from month number (1-12)
  static String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Get full month name
  static String getFullMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Format date as dd/MM/yyyy
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format date as dd/MM
  static String formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Get date range display text
  static String getDateRangeText(DateTime? fromDate, DateTime? toDate) {
    if (fromDate == null || toDate == null) {
      return 'Select date range';
    }

    final fromMonth = getMonthName(fromDate.month);
    final toMonth = getMonthName(toDate.month);

    if (fromDate.year == toDate.year) {
      if (fromDate.month == toDate.month) {
        return '$fromMonth ${fromDate.year}';
      }
      return '$fromMonth – $toMonth ${fromDate.year}';
    }
    return '$fromMonth ${fromDate.year} – $toMonth ${toDate.year}';
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get start of week for a given date
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Get end of week for a given date
  static DateTime getEndOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  /// Get first day of month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}

/// Date picker helper
class DatePickerHelper {
  DatePickerHelper._();

  /// Show date picker with consistent theme
  static Future<DateTime?> showPicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}


