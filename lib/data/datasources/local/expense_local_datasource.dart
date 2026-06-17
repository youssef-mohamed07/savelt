import '../../models/expense_model.dart';

/// Local SQLite layer removed — MongoDB via API is the source of truth.
class ExpenseLocalDataSource {
  static final ExpenseLocalDataSource instance =
      ExpenseLocalDataSource._internal();

  ExpenseLocalDataSource._internal();
  factory ExpenseLocalDataSource() => instance;

  Never _unsupported() =>
      throw UnimplementedError('Local SQLite removed; use TransactionApiService');

  Future<int> insertExpense(ExpenseModel expense) async => _unsupported();

  Future<List<ExpenseModel>> getAllExpenses() async => _unsupported();

  Future<List<ExpenseModel>> getExpensesByDateRange(
    String fromDate,
    String toDate,
  ) async =>
      _unsupported();

  Future<List<ExpenseModel>> getExpensesByCategory(String category) async =>
      _unsupported();

  Future<List<ExpenseModel>> getUnsyncedExpenses() async => _unsupported();

  Future<int> updateExpense(ExpenseModel expense) async => _unsupported();

  Future<int> deleteExpense(int id) async => _unsupported();

  Future<int> markAsSynced(int id) async => _unsupported();

  Future<int> clearAll() async => _unsupported();

  Future<List<Map<String, dynamic>>> getTotalsByCategory() async =>
      _unsupported();

  Future<double> getTotalByDateRange(String fromDate, String toDate) async =>
      _unsupported();

  Future<int> getExpenseCount() async => _unsupported();

  Future<void> close() async => _unsupported();
}
