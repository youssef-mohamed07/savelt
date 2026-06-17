import '../../entities/expense_entity.dart';
import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for adding a new expense
class AddExpenseUseCase implements UseCase<ExpenseEntity, ExpenseEntity> {
  final ExpenseRepository _repository;

  AddExpenseUseCase(this._repository);

  @override
  Future<ExpenseEntity> call(ExpenseEntity expense) async {
    return _repository.addExpense(expense);
  }
}


