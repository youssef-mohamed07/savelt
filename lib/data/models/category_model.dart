import 'package:flutter/material.dart';

/// Category model for expense categorization
class CategoryModel {
  final String id;
  final String name;
  final String nameAr; // Arabic name
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });

  /// Predefined categories
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      nameAr: 'تسوق',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF00CCFF),
      gradientColors: [Color(0xFF00CCFF), Color(0xFF0D5DB8)],
    ),
    CategoryModel(
      id: 'bills',
      name: 'Bills',
      nameAr: 'فواتير',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFF25858),
      gradientColors: [Color(0xFFF25858), Color(0xFF192148)],
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      nameAr: 'صحة',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF45F36B),
      gradientColors: [Color(0xFF45F36B), Color(0xFF141744)],
    ),
    CategoryModel(
      id: 'activities',
      name: 'Activities',
      nameAr: 'أنشطة',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFCF0FB6),
      gradientColors: [Color(0xFFCF0FB6), Color(0xFF212C55)],
    ),
    CategoryModel(
      id: 'food',
      name: 'Food & Drinks',
      nameAr: 'طعام ومشروبات',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF4285F4),
      gradientColors: [Color(0xFF4285F4), Color(0xFF192148)],
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transport',
      nameAr: 'مواصلات',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF9C27B0),
      gradientColors: [Color(0xFF9C27B0), Color(0xFF192148)],
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      nameAr: 'تعليم',
      icon: Icons.school_rounded,
      color: Color(0xFF02FFD5),
      gradientColors: [Color(0xFF02FFD5), Color(0xFF192148)],
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      nameAr: 'ترفيه',
      icon: Icons.movie_rounded,
      color: Color(0xFFFFA726),
      gradientColors: [Color(0xFFFFA726), Color(0xFFEC407A)],
    ),
    CategoryModel(
      id: 'general',
      name: 'General',
      nameAr: 'عام',
      icon: Icons.category_rounded,
      color: Color(0xFF6B7280),
      gradientColors: [Color(0xFF6B7280), Color(0xFF374151)],
    ),
  ];

  /// Find category by id
  static CategoryModel findById(String id) {
    return defaultCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => defaultCategories.last,
    );
  }

  /// Find category by name
  static CategoryModel findByName(String name) {
    return defaultCategories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      orElse: () => defaultCategories.last,
    );
  }

  /// Get gradient
  LinearGradient get gradient => LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


