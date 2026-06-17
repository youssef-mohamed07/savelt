/// Base use case interface
/// All use cases must implement this contract
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<T> {
  Future<T> call();
}


