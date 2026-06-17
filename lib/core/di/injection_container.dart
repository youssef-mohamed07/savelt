import '../../data/datasources/local/expense_local_datasource.dart';
import '../../data/datasources/remote/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';

/// Service locator for dependency injection
/// NOTE: Add get_it to pubspec.yaml: get_it: ^7.6.4
///
/// Usage:
/// 1. Add to pubspec.yaml: get_it: ^7.6.4
/// 2. Run: flutter pub get
/// 3. Call initDependencies() in main.dart before runApp()
///
/// For now, providing a simple factory pattern alternative:
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Lazy singletons
  ExpenseLocalDataSource? _localDataSource;
  ExpenseRemoteDataSource? _remoteDataSource;
  ExpenseRepository? _repository;

  ExpenseLocalDataSource get localDataSource =>
      _localDataSource ??= ExpenseLocalDataSource.instance;

  ExpenseRemoteDataSource get remoteDataSource =>
      _remoteDataSource ??= ExpenseRemoteDataSource.instance;

  ExpenseRepository get repository => _repository ??= ExpenseRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );

  // Use cases
  GetAllExpensesUseCase get getAllExpenses => GetAllExpensesUseCase(repository);

  GetExpensesByDateRangeUseCase get getExpensesByDateRange =>
      GetExpensesByDateRangeUseCase(repository);

  AddExpenseUseCase get addExpense => AddExpenseUseCase(repository);

  UpdateExpenseUseCase get updateExpense => UpdateExpenseUseCase(repository);

  DeleteExpenseUseCase get deleteExpense => DeleteExpenseUseCase(repository);

  SyncExpensesUseCase get syncExpenses => SyncExpensesUseCase(repository);

  GetCategoryTotalsUseCase get getCategoryTotals =>
      GetCategoryTotalsUseCase(repository);

  ClearAllExpensesUseCase get clearAllExpenses =>
      ClearAllExpensesUseCase(repository);

  // BLoC factory
  ExpenseBloc createExpenseBloc() => ExpenseBloc(
    getAllExpenses: getAllExpenses,
    getExpensesByDateRange: getExpensesByDateRange,
    addExpense: addExpense,
    updateExpense: updateExpense,
    deleteExpense: deleteExpense,
    syncExpenses: syncExpenses,
    clearAllExpenses: clearAllExpenses,
  );
}

/// Global service locator instance
final sl = ServiceLocator();


