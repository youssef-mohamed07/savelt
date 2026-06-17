import 'package:equatable/equatable.dart';
import '../../../core/models/expense.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

// Initial state
class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

// Loading state
class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

// Loaded state with expenses
class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;

  const ExpenseLoaded(this.expenses);

  /// Returns true ONLY when real items exist
  bool get hasData => expenses.isNotEmpty;

  /// Returns true when there are no items
  bool get isEmpty => expenses.isEmpty;

  // Get total for a specific category
  double getCategoryTotal(String category) {
    return expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get total for all expenses
  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expenses by category
  List<Expense> getExpensesByCategory(String category) {
    return expenses.where((expense) => expense.category == category).toList();
  }

  // Get expenses for current week (for chart)
  Map<String, double> getWeeklyExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekExpenses = <String, double>{};

    // Initialize days
    for (int i = 0; i < 7; i++) {
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
      weekExpenses[dayName] = 0.0;
    }

    // Sum expenses by day
    for (var expense in expenses) {
      if (expense.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        final dayName = [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][expense.date.weekday - 1];
        weekExpenses[dayName] = (weekExpenses[dayName] ?? 0) + expense.amount;
      }
    }

    return weekExpenses;
  }

  @override
  List<Object?> get props => [expenses];
}

// Error state
class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}


