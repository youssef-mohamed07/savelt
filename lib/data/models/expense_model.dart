import '../../domain/entities/expense_entity.dart';

/// Data model for expense - includes serialization logic
/// Used by data sources (SQLite, Firebase, API)
class ExpenseModel {
  final int? id;
  final String title;
  final double amount;
  final String? category;
  final String date;
  final String? description;
  final int isSynced;
  final String createdAt;

  const ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    this.category,
    required this.date,
    this.description,
    this.isSynced = 0,
    required this.createdAt,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
      'description': description,
      'isSynced': isSynced,
      'createdAt': createdAt,
    };
  }

  /// Create from database Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String?,
      date: map['date'] as String,
      description: map['description'] as String?,
      isSynced: (map['isSynced'] as int?) ?? 0,
      createdAt: map['createdAt'] as String,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
      'description': description,
      'isSynced': isSynced == 1,
      'createdAt': createdAt,
    };
  }

  /// Create from JSON response
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String?,
      date: json['date'] as String,
      description: json['description'] as String?,
      isSynced: (json['isSynced'] == true) ? 1 : 0,
      createdAt: json['createdAt'] as String,
    );
  }

  /// Convert to domain entity
  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category ?? 'General',
      date: DateTime.parse(date),
      description: description,
      isSynced: isSynced == 1,
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Create from domain entity
  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: int.tryParse(entity.id),
      title: entity.title,
      amount: entity.amount,
      category: entity.category,
      date: entity.date.toIso8601String(),
      description: entity.description,
      isSynced: entity.isSynced ? 1 : 0,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }

  /// Create a copy with updated fields
  ExpenseModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? date,
    String? description,
    int? isSynced,
    String? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


