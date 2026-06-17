import 'package:flutter/material.dart';
import '../../transactions/utils/transaction_ui_helpers.dart';

class CategoryUiStyle {
  final Color color;
  final Color background;
  final IconData icon;

  const CategoryUiStyle({
    required this.color,
    required this.background,
    required this.icon,
  });
}

CategoryUiStyle categoryUiStyle(String name) {
  final n = name.toLowerCase();
  if (n.contains('food') || n.contains('drink')) {
    return const CategoryUiStyle(
      color: Color(0xFFEA580C),
      background: Color(0xFFFFF7ED),
      icon: Icons.restaurant_rounded,
    );
  }
  if (n.contains('shop')) {
    return const CategoryUiStyle(
      color: Color(0xFF7C3AED),
      background: Color(0xFFF5F3FF),
      icon: Icons.shopping_bag_rounded,
    );
  }
  if (n.contains('bill')) {
    return const CategoryUiStyle(
      color: Color(0xFF0D5DB8),
      background: Color(0xFFEFF6FF),
      icon: Icons.receipt_long_rounded,
    );
  }
  if (n.contains('health')) {
    return const CategoryUiStyle(
      color: Color(0xFF059669),
      background: Color(0xFFECFDF5),
      icon: Icons.local_hospital_rounded,
    );
  }
  if (n.contains('transport') || n.contains('fuel')) {
    return const CategoryUiStyle(
      color: Color(0xFF0284C7),
      background: Color(0xFFF0F9FF),
      icon: Icons.directions_car_rounded,
    );
  }
  final base = categoryStyle(name);
  return CategoryUiStyle(
    color: base.color,
    background: base.background,
    icon: base.icon,
  );
}

const categoryChartColors = [
  Color(0xFF0D5DB8),
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF64748B),
];
