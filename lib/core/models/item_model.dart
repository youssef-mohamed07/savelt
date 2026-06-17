// Item Model - نموذج العنصر
// Represents an item that can be added to transactions

import 'package:equatable/equatable.dart';

class ItemModel extends Equatable {
  final String id;
  final String name;
  final double? price;
  final String? categoryId;
  final String? categoryName;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ItemModel({
    required this.id,
    required this.name,
    this.price,
    this.categoryId,
    this.categoryName,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble(),
      categoryId: map['category'] is Map ? map['category']['_id'] : map['category'],
      categoryName: map['category'] is Map ? map['category']['name'] : null,
      userId: map['user'] is Map ? map['user']['_id'] : (map['user'] ?? ''),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'category': categoryId,
      'user': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? categoryId,
    String? categoryName,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedPrice => price != null ? '${price!.toStringAsFixed(2)} EGP' : '';

  @override
  List<Object?> get props => [id, name, price, categoryId, categoryName, userId, createdAt, updatedAt];
}
