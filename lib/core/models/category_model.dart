// Category Model - نموذج الفئة
// Represents an expense category from the API

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String color;
  final String icon;
  final bool isDefault;
  final String userId;
  final List<String> itemIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon = 'category',
    this.isDefault = false,
    required this.userId,
    this.itemIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Copy with
  CategoryModel copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDefault,
    String? userId,
    List<String>? itemIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      itemIds: itemIds ?? this.itemIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // From API response
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '#FF5733',
      icon: map['icon']?.toString() ?? 'category',
      isDefault: map['isDefault'] == true,
      userId: map['user'] is Map ? map['user']['_id'] : (map['user'] ?? ''),
      itemIds: (map['items'] as List?)
              ?.map((item) => item is Map ? item['_id'] as String : item as String)
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  // To map for API
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
      'user': userId,
      'items': itemIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Get Flutter Color from hex string
  Color get colorValue {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Get emoji based on category name
  String get emoji {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('food') || lowerName.contains('طعام')) return '🍔';
    if (lowerName.contains('transport') || lowerName.contains('مواصلات')) return '🚗';
    if (lowerName.contains('shopping') || lowerName.contains('تسوق')) return '🛒';
    if (lowerName.contains('entertainment') || lowerName.contains('ترفيه')) return '🎬';
    if (lowerName.contains('bill') || lowerName.contains('فواتير')) return '📄';
    if (lowerName.contains('health') || lowerName.contains('صحة')) return '💊';
    if (lowerName.contains('education') || lowerName.contains('تعليم')) return '📚';
    if (lowerName.contains('travel') || lowerName.contains('سفر')) return '✈️';
    if (lowerName.contains('coffee') || lowerName.contains('قهوة')) return '☕';
    if (lowerName.contains('groceries') || lowerName.contains('بقالة')) return '🥬';
    return '📦';
  }

  @override
  List<Object?> get props =>
      [id, name, color, icon, isDefault, userId, itemIds, createdAt, updatedAt];
}

// Predefined category colors
class CategoryColors {
  static const List<String> colors = [
    '#FF5733', // Red-Orange
    '#33FF57', // Green
    '#3357FF', // Blue
    '#FF33F5', // Pink
    '#F5FF33', // Yellow
    '#33FFF5', // Cyan
    '#FF8C33', // Orange
    '#8C33FF', // Purple
    '#33FF8C', // Mint
    '#FF3333', // Red
  ];

  static String getRandomColor() {
    return colors[DateTime.now().millisecond % colors.length];
  }
}
