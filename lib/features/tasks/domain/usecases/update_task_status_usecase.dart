import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class UpdateTaskStatusParams extends Equatable {
  final String taskId;
  final String status;

  const UpdateTaskStatusParams({required this.taskId, required this.status});

  @override
  List<Object> get props => [taskId, status];
}

class UpdateTaskStatusUseCase extends UseCase<TaskEntity, UpdateTaskStatusParams> {
  final TaskRepository repository;

  UpdateTaskStatusUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskStatusParams params) {
    return repository.updateTaskStatus(
      taskId: params.taskId,
      status: params.status,
    );
  }
}
