import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase extends UseCaseNoParams<Unit> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call() {
    return repository.logout();
  }
}
