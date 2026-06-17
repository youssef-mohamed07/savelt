import '../../entities/expense_entity.dart';
import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for updating an expense
class UpdateExpenseUseCase implements UseCase<ExpenseEntity, ExpenseEntity> {
  final ExpenseRepository _repository;

  UpdateExpenseUseCase(this._repository);

  @override
  Future<ExpenseEntity> call(ExpenseEntity expense) async {
    return _repository.updateExpense(expense);
  }
}


