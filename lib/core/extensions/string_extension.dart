/// Extension on String for common utilities
extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if valid phone (basic)
  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(this);
  }

  /// Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    final number = double.tryParse(replaceAll(RegExp(r'[^\d.]'), ''));
    if (number == null) return this;

    if (number >= 1000) {
      return '$symbol${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${number.toStringAsFixed(2)}';
  }
}

/// Extension on nullable String
extension NullableStringExtension on String? {
  /// Return empty string if null
  String get orEmpty => this ?? '';

  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}


