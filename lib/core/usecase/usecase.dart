import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';

/// Base use case interface for use cases that take a parameter.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Base use case interface for use cases that take no parameters.
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Used as the Params type when a use case takes no parameters.
class NoParams {
  const NoParams();
}
