// Transaction Model - نموذج المعاملة
// Represents a financial transaction in the app

import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final String? location;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
    this.receiptUrl,
    this.location,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Copy with method
  TransactionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
    String? notes,
    String? receiptUrl,
    String? location,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for API/Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
      'receiptUrl': receiptUrl,
      'location': location,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? map['_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      type: map['type'] ?? 'expense',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      notes: map['notes'],
      receiptUrl: map['receiptUrl'],
      location: map['location'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) => 
      TransactionModel.fromMap(json);

  // Helper getters
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  
  String get formattedAmount {
    final sign = isIncome ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)} EGP';
  }

  String get shortDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        amount,
        category,
        type,
        date,
        notes,
        receiptUrl,
        location,
        metadata,
        createdAt,
        updatedAt,
      ];
}