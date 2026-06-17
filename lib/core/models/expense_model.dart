import 'package:equatable/equatable.dart';

// Expense categories
enum ExpenseCategory {
  food('Food', '🍔'),
  transport('Transport', '🚗'),
  shopping('Shopping', '🛒'),
  entertainment('Entertainment', '🎬'),
  bills('Bills', '📄'),
  health('Health', '💊'),
  education('Education', '📚'),
  travel('Travel', '✈️'),
  groceries('Groceries', '🥬'),
  other('Other', '📦');

  final String name;
  final String emoji;
  const ExpenseCategory(this.name, this.emoji);

  static ExpenseCategory fromString(String? value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}

class Expense extends Equatable {
  final int? id;
  final String? firestoreId;
  final String title;
  final double amount;
  final String? category;
  final String date;
  final String? description;
  final int isSynced;
  final String createdAt;
  final String? updatedAt;

  const Expense({
    this.id,
    this.firestoreId,
    required this.title,
    required this.amount,
    this.category,
    required this.date,
    this.description,
    this.isSynced = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Copy with method for immutability
  Expense copyWith({
    int? id,
    String? firestoreId,
    String? title,
    double? amount,
    String? category,
    String? date,
    String? description,
    int? isSynced,
    String? createdAt,
    String? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "firestoreId": firestoreId,
      "title": title,
      "amount": amount,
      "category": category,
      "date": date,
      "description": description,
      "isSynced": isSynced,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map["id"],
      firestoreId: map["firestoreId"],
      title: map["title"] ?? '',
      amount: (map["amount"] as num?)?.toDouble() ?? 0.0,
      category: map["category"],
      date: map["date"] ?? '',
      description: map["description"],
      isSynced: map["isSynced"] ?? 0,
      createdAt: map["createdAt"] ?? '',
      updatedAt: map["updatedAt"],
    );
  }

  // Get category enum
  ExpenseCategory get categoryEnum => ExpenseCategory.fromString(category);

  // Format amount with currency
  String get formattedAmount => '${amount.toStringAsFixed(2)} EGP';

  // Check if synced
  bool get isSyncedToCloud => isSynced == 1;

  // Parse date
  DateTime? get dateTime => DateTime.tryParse(date);

  @override
  List<Object?> get props => [
        id,
        firestoreId,
        title,
        amount,
        category,
        date,
        description,
        isSynced,
        createdAt,
        updatedAt,
      ];
}
