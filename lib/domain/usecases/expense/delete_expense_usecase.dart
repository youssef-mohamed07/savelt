import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for deleting an expense
class DeleteExpenseUseCase implements UseCase<void, String> {
  final ExpenseRepository _repository;

  DeleteExpenseUseCase(this._repository);

  @override
  Future<void> call(String expenseId) async {
    return _repository.deleteExpense(expenseId);
  }
}


