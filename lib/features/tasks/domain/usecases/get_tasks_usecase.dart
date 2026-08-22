import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/usecase/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class GetTasksParams extends Equatable {
  final String projectId;
  final String? status;
  final String? priority;
  final String? assigneeId;
  final String? searchQuery;

  const GetTasksParams({
    required this.projectId,
    this.status,
    this.priority,
    this.assigneeId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [projectId, status, priority, assigneeId, searchQuery];
}

class GetTasksUseCase extends UseCase<List<TaskEntity>, GetTasksParams> {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(GetTasksParams params) async {
    final result = await repository.getTasksByProject(
      params.projectId,
      status: params.status,
      priority: params.priority,
      assigneeId: params.assigneeId,
      searchQuery: params.searchQuery,
    );
    return result.fold(
      (failure) => Left(failure),
      (cached) => Right(cached.data),
    );
  }
}
