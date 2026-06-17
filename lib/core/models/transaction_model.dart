// Transaction Model - نموذج المعاملة
// Represents a financial transaction from the API

import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String? text;
  final String? voicePath;
  final String? ocrPath;
  final double price;
  final int quantity;
  final String? categoryId;
  final String? categoryName;
  final String userId;
  final List<TransactionItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    this.text,
    this.voicePath,
    this.ocrPath,
    required this.price,
    this.quantity = 1,
    this.categoryId,
    this.categoryName,
    required this.userId,
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Copy with
  TransactionModel copyWith({
    String? id,
    String? text,
    String? voicePath,
    String? ocrPath,
    double? price,
    String? categoryId,
    String? categoryName,
    String? userId,
    List<TransactionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      voicePath: voicePath ?? this.voicePath,
      ocrPath: ocrPath ?? this.ocrPath,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // From API response
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['_id'] ?? '',
      text: map['text'],
      voicePath: map['voice_path'],
      ocrPath: map['OCR_path'],
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      categoryId: map['category'] is Map ? map['category']['_id'] : map['category'],
      categoryName: map['category'] is Map ? map['category']['name'] : null,
      userId: map['user'] is Map ? map['user']['_id'] : (map['user'] ?? ''),
      items: (map['items'] as List?)
              ?.map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
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
      'text': text,
      'voice_path': voicePath,
      'OCR_path': ocrPath,
      'price': price,
      'category': categoryId,
      'user': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get formattedPrice => '${price.toStringAsFixed(2)} EGP';
  
  String get displayText {
    if (text != null && text!.isNotEmpty) return text!;
    if (voicePath != null) return '🎤 Voice transaction';
    if (ocrPath != null) return '📷 Receipt scan';
    return 'Transaction';
  }

  TransactionType get type {
    if (voicePath != null) return TransactionType.voice;
    if (ocrPath != null) return TransactionType.ocr;
    return TransactionType.text;
  }

  String get typeIcon {
    switch (type) {
      case TransactionType.voice:
        return '🎤';
      case TransactionType.ocr:
        return '📷';
      case TransactionType.text:
        return '📝';
    }
  }

  @override
  List<Object?> get props => [
        id,
        text,
        voicePath,
        ocrPath,
        price,
        categoryId,
        categoryName,
        userId,
        items,
        createdAt,
        updatedAt,
      ];
}

// Transaction type enum
enum TransactionType { text, voice, ocr }

// Transaction item model
class TransactionItem extends Equatable {
  final String id;
  final String? name;
  final double? price;

  const TransactionItem({
    required this.id,
    this.name,
    this.price,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['_id'] ?? '',
      name: map['name'],
      price: (map['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [id, name, price];
}
