import 'package:equatable/equatable.dart';
import '../../../../domain/entities/expense_entity.dart';

/// Base expense event
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

/// Load all expenses
class LoadExpensesEvent extends ExpenseEvent {
  const LoadExpensesEvent();
}

/// Load expenses by date range
class LoadExpensesByDateRangeEvent extends ExpenseEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadExpensesByDateRangeEvent({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

/// Add new expense
class AddExpenseEvent extends ExpenseEvent {
  final ExpenseEntity expense;

  const AddExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Update expense
class UpdateExpenseEvent extends ExpenseEvent {
  final ExpenseEntity expense;

  const UpdateExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

/// Delete expense
class DeleteExpenseEvent extends ExpenseEvent {
  final String expenseId;

  const DeleteExpenseEvent(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

/// Sync expenses with remote
class SyncExpensesEvent extends ExpenseEvent {
  const SyncExpensesEvent();
}

/// Clear all expenses
class ClearAllExpensesEvent extends ExpenseEvent {
  const ClearAllExpensesEvent();
}


