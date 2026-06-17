import '../../entities/expense_entity.dart';
import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for getting all expenses
class GetAllExpensesUseCase implements UseCaseNoParams<List<ExpenseEntity>> {
  final ExpenseRepository _repository;

  GetAllExpensesUseCase(this._repository);

  @override
  Future<List<ExpenseEntity>> call() async {
    return _repository.getAllExpenses();
  }
}


