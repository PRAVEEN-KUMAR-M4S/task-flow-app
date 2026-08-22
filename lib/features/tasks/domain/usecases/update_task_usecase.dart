import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class UpdateTaskParams extends Equatable {
  final String taskId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assigneeId;
  final DateTime? dueDate;
  final List<String> tags;

  const UpdateTaskParams({
    required this.taskId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assigneeId,
    this.dueDate,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        taskId,
        title,
        description,
        priority,
        status,
        assigneeId,
        dueDate,
        tags,
      ];
}

class UpdateTaskUseCase extends UseCase<TaskEntity, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) {
    return repository.updateTask(
      taskId: params.taskId,
      title: params.title,
      description: params.description,
      priority: params.priority,
      status: params.status,
      assigneeId: params.assigneeId,
      dueDate: params.dueDate,
      tags: params.tags,
    );
  }
}
