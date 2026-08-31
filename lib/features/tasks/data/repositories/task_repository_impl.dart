import 'package:dartz/dartz.dart';
import 'package:task_flow/core/error/failure_mapper.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/network/connectivity_cubit.dart';
import 'package:task_flow/core/utils/cached.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_filter.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource datasource;
  final ConnectivityCubit connectivity;

  TaskRepositoryImpl({required this.datasource, required this.connectivity});

  bool get _isOffline => connectivity.state.isOffline;

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Cached<List<TaskEntity>>>> getTasksByProject(
    String projectId, {
    String? status,
    String? priority,
    String? assigneeId,
    String? searchQuery,
    DateTime? dueFrom,
    DateTime? dueTo,
  }) async {
    final filter = TaskFilter(
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      searchQuery: searchQuery,
      dueFrom: dueFrom,
      dueTo: dueTo,
    );

    if (_isOffline) {
      final cached = datasource.getCachedTasks(projectId);
      if (cached != null) return Right(Cached.stale(filter.apply(cached)));
      return const Left(
        NetworkFailure(
          message: 'You are offline and this project has not been saved yet.',
        ),
      );
    }

    try {
      final tasks = await datasource.getTasksByProject(projectId);
      return Right(Cached.fresh(filter.apply(tasks)));
    } catch (error) {
      final cached = datasource.getCachedTasks(projectId);
      if (cached != null) return Right(Cached.stale(filter.apply(cached)));
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Cached<TaskEntity>>> getTaskById(String taskId) async {
    if (_isOffline) {
      final cached = datasource.getCachedTask(taskId);
      if (cached != null) return Right(Cached.stale(cached));
      return const Left(
        NetworkFailure(
          message: 'You are offline and this task has not been saved.',
        ),
      );
    }
    try {
      return Right(Cached.fresh(await datasource.getTaskById(taskId)));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<TaskComment>>> getComments(String taskId) async {
    // Comments are not cached — an empty thread offline is honest, whereas a
    // stale thread reads as if nothing new was said.
    if (_isOffline) {
      return const Left(
        NetworkFailure(message: 'Comments are unavailable offline.'),
      );
    }
    try {
      return Right(await datasource.getComments(taskId));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, TaskEntity>> createTask({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    required String createdBy,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    if (_isOffline) return Left(_offlineWrite('create a task'));
    try {
      return Right(
        await datasource.createTask(
          projectId: projectId,
          title: title,
          description: description,
          priority: priority,
          status: status,
          assigneeId: assigneeId,
          createdBy: createdBy,
          dueDate: dueDate,
          tags: tags,
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    if (_isOffline) return Left(_offlineWrite('edit a task'));
    try {
      return Right(
        await datasource.updateTask(
          taskId: taskId,
          title: title,
          description: description,
          priority: priority,
          status: status,
          assigneeId: assigneeId,
          dueDate: dueDate,
          tags: tags,
        ),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String taskId) async {
    if (_isOffline) return Left(_offlineWrite('delete a task'));
    try {
      await datasource.deleteTask(taskId);
      return const Right(unit);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> assignTask({
    required String taskId,
    String? assigneeId,
  }) async {
    if (_isOffline) return Left(_offlineWrite('reassign a task'));
    try {
      return Right(
        await datasource.assignTask(taskId: taskId, assigneeId: assigneeId),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    if (_isOffline) return Left(_offlineWrite('change a task status'));
    try {
      return Right(
        await datasource.updateTaskStatus(taskId: taskId, status: status),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTaskPriority({
    required String taskId,
    required String priority,
  }) async {
    if (_isOffline) return Left(_offlineWrite('change a task priority'));
    try {
      return Right(
        await datasource.updateTaskPriority(taskId: taskId, priority: priority),
      );
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  NetworkFailure _offlineWrite(String action) =>
      NetworkFailure(message: 'You need to be online to $action.');

  @override
  Future<Either<Failure, TaskEntity>> toggleFavorite({
    required String taskId,
  }) async {
    try {
      if (_isOffline) {
        return Left(_offlineWrite('toggle a task favorite'));
      }
      return Right(await datasource.toggleFavorite(taskId: taskId));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
