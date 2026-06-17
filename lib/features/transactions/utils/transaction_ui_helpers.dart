import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionUiStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const TransactionUiStyle({
    required this.icon,
    required this.color,
    required this.background,
  });
}

TransactionUiStyle categoryStyle(String? raw) {
  final c = (raw ?? '').trim().toLowerCase();
  if (c.contains('food') || c.contains('drink') || c.contains('restaurant') || c.contains('طعام') || c.contains('أكل')) {
    return const TransactionUiStyle(
      icon: Icons.restaurant_rounded,
      color: Color(0xFFEA580C),
      background: Color(0xFFFFF7ED),
    );
  }
  if (c.contains('shop') || c.contains('grocer') || c.contains('market') || c.contains('تسوق')) {
    return const TransactionUiStyle(
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF7C3AED),
      background: Color(0xFFF5F3FF),
    );
  }
  if (c.contains('bill') || c.contains('util') || c.contains('فات') || c.contains('rent')) {
    return const TransactionUiStyle(
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF0D5DB8),
      background: Color(0xFFEFF6FF),
    );
  }
  if (c.contains('health') || c.contains('med') || c.contains('pharm') || c.contains('صح')) {
    return const TransactionUiStyle(
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF059669),
      background: Color(0xFFECFDF5),
    );
  }
  if (c.contains('transport') || c.contains('fuel') || c.contains('car') || c.contains('مواص')) {
    return const TransactionUiStyle(
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0284C7),
      background: Color(0xFFF0F9FF),
    );
  }
  if (c.contains('entertain') || c.contains('game') || c.contains('fun')) {
    return const TransactionUiStyle(
      icon: Icons.movie_rounded,
      color: Color(0xFFDB2777),
      background: Color(0xFFFDF2F8),
    );
  }
  return const TransactionUiStyle(
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF475569),
    background: Color(0xFFF1F5F9),
  );
}

String formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatFullDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String sectionDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return formatFullDate(date);
}

String monthYearLabel(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

List<MapEntry<String, List<TransactionModel>>> groupTransactionsByDay(
  List<TransactionModel> transactions,
) {
  final sorted = List<TransactionModel>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));

  final groups = <String, List<TransactionModel>>{};
  for (final t in sorted) {
    final key = sectionDateLabel(t.date);
    groups.putIfAbsent(key, () => []).add(t);
  }
  return groups.entries.toList();
}

double sumExpenses(List<TransactionModel> transactions) {
  return transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
}

String displayCategory(String category) {
  if (category.trim().isEmpty) return 'General';
  return category.trim();
}
