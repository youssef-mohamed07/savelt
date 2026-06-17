/// Extension on DateTime for formatting and manipulation
extension DateExtension on DateTime {
  /// Format as dd/MM/yyyy
  String get formatted => '$day/$month/$year';

  /// Format as dd/MM (short)
  String get shortFormatted => '$day/$month';

  /// Get month name (short)
  String get monthName {
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
    return months[month - 1];
  }

  /// Get month name (full)
  String get monthNameFull {
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
    return months[month - 1];
  }

  /// Get day name (short)
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Check if same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0);

  /// Get date range text
  String getDateRangeText(DateTime? toDate) {
    if (toDate == null) return 'Select date range';

    if (year == toDate.year) {
      if (month == toDate.month) {
        return '$monthName $year';
      }
      return '$monthName – ${toDate.monthName} $year';
    }
    return '$monthName $year – ${toDate.monthName} ${toDate.year}';
  }
}


