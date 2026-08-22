import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/auth/domain/entities/user.dart';
import 'package:task_flow/features/auth/domain/repositories/auth_repository.dart';

class GetCachedSessionUseCase extends UseCaseNoParams<User?> {
  final AuthRepository repository;

  GetCachedSessionUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call() {
    return repository.getCachedUser();
  }
}
