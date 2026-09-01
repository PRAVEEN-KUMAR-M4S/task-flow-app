import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/assign_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_comments_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_task_detail_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_favorite_usecases.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_status_usecase.dart';

// ─── States ─────────────────────────────────────────────────────────────────

abstract class TaskDetailState extends Equatable {
  const TaskDetailState();
  @override
  List<Object?> get props => [];
}

class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

class TaskDetailSuccess extends TaskDetailState {
  final TaskEntity task;
  final List<TaskComment> comments;
  final bool commentsLoading;
  const TaskDetailSuccess(
    this.task, {
    this.comments = const [],
    this.commentsLoading = false,
  });

  TaskDetailSuccess copyWith({
    TaskEntity? task,
    List<TaskComment>? comments,
    bool? commentsLoading,
  }) {
    return TaskDetailSuccess(
      task ?? this.task,
      comments: comments ?? this.comments,
      commentsLoading: commentsLoading ?? this.commentsLoading,
    );
  }

  @override
  List<Object?> get props => [task, comments, commentsLoading];
}

class TaskDetailError extends TaskDetailState {
  final Failure failure;
  const TaskDetailError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ──────────────────────────────────────────────────────────────────

/// Manages task detail — load, comments, and detail mutations.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final GetTaskDetailUseCase _getTaskDetailUseCase;
  final GetCommentsUseCase _getCommentsUseCase;
  final AssignTaskUseCase _assignTaskUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final ToggleFavoriteUsecases _favoriteUsecases;

  TaskDetailCubit({
    required GetTaskDetailUseCase getTaskDetailUseCase,
    required GetCommentsUseCase getCommentsUseCase,
    required AssignTaskUseCase assignTaskUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required ToggleFavoriteUsecases favoriteUsecases,
  }) : _getTaskDetailUseCase = getTaskDetailUseCase,
       _getCommentsUseCase = getCommentsUseCase,
       _assignTaskUseCase = assignTaskUseCase,
       _updateTaskStatusUseCase = updateTaskStatusUseCase,
       _deleteTaskUseCase = deleteTaskUseCase,
       _favoriteUsecases = favoriteUsecases,
       super(const TaskDetailInitial());

  void reset() => emit(const TaskDetailInitial());

  /// Load a single task with comments.
  Future<void> loadTask(String taskId) async {
    emit(const TaskDetailLoading());
    final result = await _getTaskDetailUseCase(taskId);
    result.fold((failure) => emit(TaskDetailError(failure)), (task) async {
      emit(TaskDetailSuccess(task, commentsLoading: true));
      await _loadComments(taskId);
    });
  }

  Future<void> refresh(String taskId) => loadTask(taskId);

  /// Optimistic local update without re-fetching.
  void updateTaskLocally(TaskEntity task) {
    final current = state;
    if (current is TaskDetailSuccess) {
      emit(current.copyWith(task: task));
    } else {
      emit(TaskDetailSuccess(task));
    }
  }

  // ─── Mutations ─────────────────────────────────────────────────────────

  /// Change status. Returns null on success, error on failure.
  Future<String?> updateStatus(String taskId, String status) async {
    final result = await _updateTaskStatusUseCase(
      UpdateTaskStatusParams(taskId: taskId, status: status),
    );
    return result.fold((f) => f.message, (updated) {
      updateTaskLocally(updated);
      return null;
    });
  }

  /// Assign/unassign. Returns null on success, error on failure.
  Future<String?> assignTask(
    String taskId,
    String? assigneeId,
    String orgId,
  ) async {
    final result = await _assignTaskUseCase(
      AssignTaskParams(taskId: taskId, assigneeId: assigneeId, orgId: orgId),
    );
    return result.fold((f) => f.message, (updated) {
      updateTaskLocally(updated);
      return null;
    });
  }

  /// Toggle favorite. Returns null on success, error message on failure.
  Future<String?> toggleFavorite(String taskId) async {
    final result = await _favoriteUsecases(taskId: taskId);
    return result.fold((f) => f.message, (updated) {
      updateTaskLocally(updated);
      return null;
    });
  }

  /// Delete task. Returns null on success, error on failure.
  Future<String?> deleteTask(String taskId) async {
    final result = await _deleteTaskUseCase(taskId);
    return result.fold((f) => f.message, (_) => null);
  }

  // ─── Comments ──────────────────────────────────────────────────────────

  Future<void> _loadComments(String taskId) async {
    final result = await _getCommentsUseCase(taskId);
    if (!isClosed && state is TaskDetailSuccess) {
      result.fold(
        (failure) => emit(
          (state as TaskDetailSuccess).copyWith(
            comments: [],
            commentsLoading: false,
          ),
        ),
        (comments) => emit(
          (state as TaskDetailSuccess).copyWith(
            comments: comments,
            commentsLoading: false,
          ),
        ),
      );
    }
  }
}
