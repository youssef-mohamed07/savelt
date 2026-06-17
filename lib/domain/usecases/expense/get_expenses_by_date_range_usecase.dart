import '../../entities/expense_entity.dart';
import '../../repositories/expense_repository.dart';
import '../base_usecase.dart';

/// Parameters for date range query
class DateRangeParams {
  final DateTime fromDate;
  final DateTime toDate;

  const DateRangeParams({required this.fromDate, required this.toDate});
}

/// Use case for getting expenses by date range
class GetExpensesByDateRangeUseCase
    implements UseCase<List<ExpenseEntity>, DateRangeParams> {
  final ExpenseRepository _repository;

  GetExpensesByDateRangeUseCase(this._repository);

  @override
  Future<List<ExpenseEntity>> call(DateRangeParams params) async {
    return _repository.getExpensesByDateRange(params.fromDate, params.toDate);
  }
}


