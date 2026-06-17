import 'package:flutter/foundation.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local/expense_local_datasource.dart';
import '../datasources/remote/expense_remote_datasource.dart';
import '../models/expense_model.dart';

/// Implementation of ExpenseRepository
/// Handles both local and remote data sources
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource;
  final ExpenseRemoteDataSource _remoteDataSource;

  ExpenseRepositoryImpl({
    ExpenseLocalDataSource? localDataSource,
    ExpenseRemoteDataSource? remoteDataSource,
  }) : _localDataSource = localDataSource ?? ExpenseLocalDataSource.instance,
       _remoteDataSource = remoteDataSource ?? ExpenseRemoteDataSource.instance;

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async {
    try {
      final models = await _localDataSource.getAllExpenses();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ Error getting all expenses: $e');
      return [];
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    try {
      final models = await _localDataSource.getExpensesByDateRange(
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ Error getting expenses by date range: $e');
      return [];
    }
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async {
    try {
      final models = await _localDataSource.getExpensesByCategory(category);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ Error getting expenses by category: $e');
      return [];
    }
  }

  @override
  Future<List<ExpenseEntity>> getUnsyncedExpenses() async {
    try {
      final models = await _localDataSource.getUnsyncedExpenses();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      debugPrint('❌ Error getting unsynced expenses: $e');
      return [];
    }
  }

  @override
  Future<ExpenseEntity> addExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      final id = await _localDataSource.insertExpense(model);

      final savedModel = model.copyWith(id: id);
      debugPrint('✅ Expense added locally: ${expense.title}');

      return savedModel.toEntity();
    } catch (e) {
      debugPrint('❌ Error adding expense: $e');
      rethrow;
    }
  }

  @override
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await _localDataSource.updateExpense(model);

      debugPrint('✅ Expense updated: ${expense.title}');
      return expense;
    } catch (e) {
      debugPrint('❌ Error updating expense: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final intId = int.tryParse(id);
      if (intId != null) {
        await _localDataSource.deleteExpense(intId);
        debugPrint('✅ Expense deleted: $id');
      }
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsSynced(String id) async {
    try {
      final intId = int.tryParse(id);
      if (intId != null) {
        await _localDataSource.markAsSynced(intId);
      }
    } catch (e) {
      debugPrint('❌ Error marking as synced: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncExpenses() async {
    try {
      // Check internet connection
      final hasInternet = await _remoteDataSource.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('📵 No internet connection');
        return;
      }

      // Get unsynced expenses
      final unsyncedModels = await _localDataSource.getUnsyncedExpenses();
      if (unsyncedModels.isEmpty) {
        debugPrint('✅ No expenses to sync');
        return;
      }

      debugPrint('📤 Found ${unsyncedModels.length} expenses to sync');

      // Sync each expense
      final results = await _remoteDataSource.syncExpenses(unsyncedModels);

      // Mark successful ones as synced
      for (final entry in results.entries) {
        if (entry.value) {
          await _localDataSource.markAsSynced(entry.key);
        }
      }

      final successCount = results.values.where((v) => v).length;
      debugPrint('🎉 Synced $successCount/${unsyncedModels.length} expenses');
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _localDataSource.clearAll();
      debugPrint('✅ All expenses cleared');
    } catch (e) {
      debugPrint('❌ Error clearing expenses: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, double>> getTotalsByCategory() async {
    try {
      final results = await _localDataSource.getTotalsByCategory();
      return Map.fromEntries(
        results.map(
          (r) => MapEntry(
            r['category'] as String? ?? 'General',
            (r['total'] as num?)?.toDouble() ?? 0.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error getting totals by category: $e');
      return {};
    }
  }

  @override
  Future<double> getTotalByDateRange(DateTime fromDate, DateTime toDate) async {
    try {
      return await _localDataSource.getTotalByDateRange(
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Error getting total by date range: $e');
      return 0.0;
    }
  }
}


