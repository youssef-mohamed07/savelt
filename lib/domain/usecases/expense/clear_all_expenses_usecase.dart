import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for clearing all expenses
class ClearAllExpensesUseCase implements UseCaseNoParams<void> {
  final ExpenseRepository _repository;

  ClearAllExpensesUseCase(this._repository);

  @override
  Future<void> call() async {
    return _repository.clearAll();
  }
}


