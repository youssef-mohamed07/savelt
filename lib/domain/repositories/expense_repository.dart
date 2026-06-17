import '../entities/expense_entity.dart';

/// Abstract repository interface for expenses
/// Defines the contract that data layer must implement
abstract class ExpenseRepository {
  /// Get all expenses
  Future<List<ExpenseEntity>> getAllExpenses();

  /// Get expenses by date range
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime fromDate,
    DateTime toDate,
  );

  /// Get expenses by category
  Future<List<ExpenseEntity>> getExpensesByCategory(String category);

  /// Get unsynced expenses
  Future<List<ExpenseEntity>> getUnsyncedExpenses();

  /// Add new expense
  Future<ExpenseEntity> addExpense(ExpenseEntity expense);

  /// Update expense
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense);

  /// Delete expense
  Future<void> deleteExpense(String id);

  /// Mark expense as synced
  Future<void> markAsSynced(String id);

  /// Sync all unsynced expenses
  Future<void> syncExpenses();

  /// Clear all expenses
  Future<void> clearAll();

  /// Get total amount by category
  Future<Map<String, double>> getTotalsByCategory();

  /// Get total amount by date range
  Future<double> getTotalByDateRange(DateTime fromDate, DateTime toDate);
}


