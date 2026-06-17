import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategoryData {
  final String name;
  final IconData icon;
  final LinearGradient gradient;

  const CategoryData({
    required this.name,
    required this.icon,
    required this.gradient,
  });
}

// Default categories that appear in both Home and Categories pages
const List<CategoryData> defaultCategories = [
  CategoryData(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    gradient: AppColors.shoppingGradient,
  ),
  CategoryData(
    name: 'Bills',
    icon: Icons.receipt_long,
    gradient: AppColors.billsGradient,
  ),
  CategoryData(
    name: 'Health',
    icon: Icons.favorite_border,
    gradient: AppColors.healthGradient,
  ),
];



