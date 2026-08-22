import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class GetTaskDetailUseCase extends UseCase<TaskEntity, String> {
  final TaskRepository repository;

  GetTaskDetailUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(String taskId) async {
    final result = await repository.getTaskById(taskId);
    return result.fold(
      (failure) => Left(failure),
      (cached) => Right(cached.data),
    );
  }
}
