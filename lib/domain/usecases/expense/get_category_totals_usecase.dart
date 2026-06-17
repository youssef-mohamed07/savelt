import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Use case for getting totals by category
class GetCategoryTotalsUseCase implements UseCaseNoParams<Map<String, double>> {
  final ExpenseRepository _repository;

  GetCategoryTotalsUseCase(this._repository);

  @override
  Future<Map<String, double>> call() async {
    return _repository.getTotalsByCategory();
  }
}


