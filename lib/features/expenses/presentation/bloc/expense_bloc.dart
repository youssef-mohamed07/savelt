import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/usecases.dart';
import 'expense_event.dart';
import 'expense_state.dart';

/// Expense BLoC - Manages expense state using use cases
///
/// This BLoC follows clean architecture principles:
/// - No direct data source access
/// - All operations go through use cases
/// - Pure business logic handling
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetAllExpensesUseCase _getAllExpenses;
  final GetExpensesByDateRangeUseCase _getExpensesByDateRange;
  final AddExpenseUseCase _addExpense;
  final UpdateExpenseUseCase _updateExpense;
  final DeleteExpenseUseCase _deleteExpense;
  final SyncExpensesUseCase _syncExpenses;
  final ClearAllExpensesUseCase _clearAllExpenses;

  ExpenseBloc({
    required GetAllExpensesUseCase getAllExpenses,
    required GetExpensesByDateRangeUseCase getExpensesByDateRange,
    required AddExpenseUseCase addExpense,
    required UpdateExpenseUseCase updateExpense,
    required DeleteExpenseUseCase deleteExpense,
    required SyncExpensesUseCase syncExpenses,
    required ClearAllExpensesUseCase clearAllExpenses,
  }) : _getAllExpenses = getAllExpenses,
       _getExpensesByDateRange = getExpensesByDateRange,
       _addExpense = addExpense,
       _updateExpense = updateExpense,
       _deleteExpense = deleteExpense,
       _syncExpenses = syncExpenses,
       _clearAllExpenses = clearAllExpenses,
       super(const ExpenseInitial()) {
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<LoadExpensesByDateRangeEvent>(_onLoadExpensesByDateRange);
    on<AddExpenseEvent>(_onAddExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<SyncExpensesEvent>(_onSyncExpenses);
    on<ClearAllExpensesEvent>(_onClearAllExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());
    try {
      final expenses = await _getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
    }
  }

  Future<void> _onLoadExpensesByDateRange(
    LoadExpensesByDateRangeEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());
    try {
      final expenses = await _getExpensesByDateRange(
        DateRangeParams(fromDate: event.fromDate, toDate: event.toDate),
      );
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _addExpense(event.expense);

      // Reload expenses after adding
      final expenses = await _getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to add expense: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _updateExpense(event.expense);

      // Reload expenses after updating
      final expenses = await _getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _deleteExpense(event.expenseId);

      // Reload expenses after deleting
      final expenses = await _getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }

  Future<void> _onSyncExpenses(
    SyncExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _syncExpenses();

      // Reload after sync
      final expenses = await _getAllExpenses();
      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(ExpenseError('Failed to sync expenses: ${e.toString()}'));
    }
  }

  Future<void> _onClearAllExpenses(
    ClearAllExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _clearAllExpenses();
      emit(const ExpenseLoaded([]));
    } catch (e) {
      emit(ExpenseError('Failed to clear expenses: ${e.toString()}'));
    }
  }
}


