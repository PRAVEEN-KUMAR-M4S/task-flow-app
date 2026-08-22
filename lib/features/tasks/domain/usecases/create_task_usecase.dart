import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class CreateTaskParams extends Equatable {
  final String projectId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assigneeId;
  final String createdBy;
  final DateTime? dueDate;
  final List<String> tags;

  const CreateTaskParams({
    required this.projectId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assigneeId,
    required this.createdBy,
    this.dueDate,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        projectId,
        title,
        description,
        priority,
        status,
        assigneeId,
        createdBy,
        dueDate,
        tags,
      ];
}

class CreateTaskUseCase extends UseCase<TaskEntity, CreateTaskParams> {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) {
    return repository.createTask(
      projectId: params.projectId,
      title: params.title,
      description: params.description,
      priority: params.priority,
      status: params.status,
      assigneeId: params.assigneeId,
      createdBy: params.createdBy,
      dueDate: params.dueDate,
      tags: params.tags,
    );
  }
}
