import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class DeleteTaskUseCase extends UseCase<Unit, String> {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String taskId) {
    return repository.deleteTask(taskId);
  }
}
