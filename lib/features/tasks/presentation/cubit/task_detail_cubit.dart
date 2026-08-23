import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_comments_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_task_detail_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

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

// ─── Cubit ────────────────────────────────────────────────────────────────────

class TaskDetailCubit extends Cubit<TaskDetailState> {
  final GetTaskDetailUseCase _getTaskDetailUseCase;
  final GetCommentsUseCase _getCommentsUseCase;

  TaskDetailCubit({
    required GetTaskDetailUseCase getTaskDetailUseCase,
    required GetCommentsUseCase getCommentsUseCase,
  })  : _getTaskDetailUseCase = getTaskDetailUseCase,
        _getCommentsUseCase = getCommentsUseCase,
        super(const TaskDetailInitial());

  /// Reset state before opening a new detail screen — singleton reuse.
  void reset() => emit(const TaskDetailInitial());

  Future<void> loadTask(String taskId) async {
    emit(const TaskDetailLoading());
    final result = await _getTaskDetailUseCase(taskId);
    result.fold(
      (failure) => emit(TaskDetailError(failure)),
      (task) {
        emit(TaskDetailSuccess(task, commentsLoading: true));
        _loadComments(taskId);
      },
    );
  }

  Future<void> refresh(String taskId) => loadTask(taskId);

  /// Optimistically replace the current task without re-fetching.
  void updateTaskLocally(TaskEntity task) {
    final current = state;
    if (current is TaskDetailSuccess) {
      emit(current.copyWith(task: task));
    } else {
      emit(TaskDetailSuccess(task));
    }
  }

  // ─── Comments ────────────────────────────────────────────────────────────

  Future<void> _loadComments(String taskId) async {
    final result = await _getCommentsUseCase(taskId);
    if (!isClosed && state is TaskDetailSuccess) {
      result.fold(
        (failure) => emit((state as TaskDetailSuccess).copyWith(
              comments: [],
              commentsLoading: false,
            )),
        (comments) => emit((state as TaskDetailSuccess).copyWith(
              comments: comments,
              commentsLoading: false,
            )),
      );
    }
  }

  Future<void> refreshComments(String taskId) async {
    final current = state;
    if (current is TaskDetailSuccess) {
      emit(current.copyWith(commentsLoading: true));
      await _loadComments(taskId);
    }
  }
}
