import 'package:equatable/equatable.dart';
import '../../../../domain/entities/expense_entity.dart';

/// Base expense state
abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

/// Loading state
class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

/// Loaded state with expenses
class ExpenseLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;

  const ExpenseLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

/// Error state
class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Expense operation success (add, update, delete)
class ExpenseOperationSuccess extends ExpenseState {
  final String message;

  const ExpenseOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}


