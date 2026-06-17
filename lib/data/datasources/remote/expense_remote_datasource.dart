import 'dart:io';
import '../../models/expense_model.dart';

/// Legacy clean-architecture remote datasource — not used by the active app.
/// Active sync uses [TransactionApiService] via [SyncService] and [ExpenseBloc].
class ExpenseRemoteDataSource {
  static final ExpenseRemoteDataSource instance =
      ExpenseRemoteDataSource._internal();

  ExpenseRemoteDataSource._internal();
  factory ExpenseRemoteDataSource() => instance;

  static Never _notUsed() {
    throw UnimplementedError(
      'ExpenseRemoteDataSource is deprecated. Use TransactionApiService instead.',
    );
  }

  Future<bool> syncExpense(ExpenseModel expense) async => _notUsed();

  Future<Map<int, bool>> syncExpenses(List<ExpenseModel> expenses) async =>
      _notUsed();

  Future<List<ExpenseModel>> fetchExpenses() async => _notUsed();

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async => _notUsed();
}
