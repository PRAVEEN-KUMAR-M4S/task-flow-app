import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class TaskFormState extends Equatable {
  const TaskFormState();
  @override
  List<Object?> get props => [];
}

class TaskFormInitial extends TaskFormState {
  const TaskFormInitial();
}

class TaskFormSubmitting extends TaskFormState {
  const TaskFormSubmitting();
}

class TaskFormSuccess extends TaskFormState {
  const TaskFormSuccess();
}

class TaskFormError extends TaskFormState {
  final Failure failure;
  const TaskFormError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class TaskFormCubit extends Cubit<TaskFormState> {
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;

  TaskFormCubit({
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
  })  : _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        super(const TaskFormInitial());

  /// Reset state before opening a new form — singleton reuse.
  void reset() => emit(const TaskFormInitial());

  Future<void> createTask({
    required CreateTaskParams params,
  }) async {
    emit(const TaskFormSubmitting());
    final result = await _createTaskUseCase(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TaskFormError(failure)),
      (_) => emit(const TaskFormSuccess()),
    );
  }

  Future<void> updateTask({
    required UpdateTaskParams params,
  }) async {
    emit(const TaskFormSubmitting());
    final result = await _updateTaskUseCase(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(TaskFormError(failure)),
      (_) => emit(const TaskFormSuccess()),
    );
  }
}
