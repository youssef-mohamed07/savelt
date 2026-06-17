import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for syncing expenses with remote
class SyncExpensesUseCase implements UseCaseNoParams<void> {
  final ExpenseRepository _repository;

  SyncExpensesUseCase(this._repository);

  @override
  Future<void> call() async {
    return _repository.syncExpenses();
  }
}


