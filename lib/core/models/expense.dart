/// @deprecated Use ExpenseEntity from domain/entities and ExpenseModel from data/models
///
/// Migration guide:
/// - For domain logic: Use ExpenseEntity from 'domain/entities/expense_entity.dart'
/// - For data operations: Use ExpenseModel from 'data/models/expense_model.dart'
///
/// This class is kept for backward compatibility with the old BLoC
@Deprecated('Use ExpenseEntity (domain) and ExpenseModel (data) instead')
class Expense {
  final String id;
  final double amount;
  final String category; // 'Shopping', 'Bills', 'Health', etc.
  final String title;
  final DateTime date;
  final String? notes;
  final bool isVoiceInput; // Added for voice input indicator
  final int quantity; // Added for quantity tracking

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.title,
    required this.date,
    this.notes,
    this.isVoiceInput = false, // Default to false for manual entries
    this.quantity = 1, // Default to 1 for backward compatibility
  });

  // Convert to Map for Firebase/Storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'isVoiceInput': isVoiceInput,
      'quantity': quantity,
    };
  }

  // Create from Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      isVoiceInput: map['isVoiceInput'] as bool? ?? false,
      quantity: map['quantity'] as int? ?? 1, // Default to 1 for backward compatibility
    );
  }

  // Copy with method for updates
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? title,
    DateTime? date,
    String? notes,
    bool? isVoiceInput,
    int? quantity,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isVoiceInput: isVoiceInput ?? this.isVoiceInput,
      quantity: quantity ?? this.quantity,
    );
  }
}


