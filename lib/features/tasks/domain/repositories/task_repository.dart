import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

abstract class TaskRepository {
  /// Reads may be served from cache while offline — [Cached.isStale] says which.
  Future<Either<Failure, Cached<List<TaskEntity>>>> getTasksByProject(
    String projectId, {
    String? status,
    String? priority,
    String? assigneeId,
    String? searchQuery,
    DateTime? dueFrom,
    DateTime? dueTo,
  });

  Future<Either<Failure, Cached<TaskEntity>>> getTaskById(String taskId);

  Future<Either<Failure, List<TaskComment>>> getComments(String taskId);

  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    required String createdBy,
    DateTime? dueDate,
    List<String> tags,
  });

  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    DateTime? dueDate,
    List<String> tags,
  });

  Future<Either<Failure, Unit>> deleteTask(String taskId);

  Future<Either<Failure, TaskEntity>> assignTask({
    required String taskId,
    String? assigneeId,
  });

  Future<Either<Failure, TaskEntity>> updateTaskStatus({
    required String taskId,
    required String status,
  });

  Future<Either<Failure, TaskEntity>> updateTaskPriority({
    required String taskId,
    required String priority,
  });

  Future<Either<Failure, TaskEntity>> toggleFavorite({required String taskId});
}
