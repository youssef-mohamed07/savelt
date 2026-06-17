import 'package:equatable/equatable.dart';

/// Pure expense entity for domain layer
/// Contains only business data, no serialization logic
class ExpenseEntity extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final bool isSynced;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.isSynced = false,
    required this.createdAt,
  });

  /// Create a copy with updated fields
  ExpenseEntity copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return ExpenseEntity(
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

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    category,
    date,
    description,
    isSynced,
    createdAt,
  ];
}


