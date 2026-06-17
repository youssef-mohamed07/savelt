import 'package:equatable/equatable.dart';
import '../../../core/models/expense.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

// Add new expense
class AddExpense extends ExpenseEvent {
  final Expense expense;

  const AddExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

// Delete expense
class DeleteExpense extends ExpenseEvent {
  final String expenseId;

  const DeleteExpense(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

// Load expenses (for future Firebase integration)
class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
}

// Update expense
class UpdateExpense extends ExpenseEvent {
  final Expense expense;

  const UpdateExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

// Clear all expenses
class ClearAllExpenses extends ExpenseEvent {
  const ClearAllExpenses();
}



