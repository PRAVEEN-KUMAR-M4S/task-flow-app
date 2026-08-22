import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_task_detail_usecase.dart';

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
  const TaskDetailSuccess(this.task);
  @override
  List<Object?> get props => [task];
}

class TaskDetailError extends TaskDetailState {
  final Failure failure;
  const TaskDetailError(this.failure);
  @override
  List<Object?> get props => [failure];
}

class TaskDetailCubit extends Cubit<TaskDetailState> {
  final GetTaskDetailUseCase _getTaskDetailUseCase;

  TaskDetailCubit({
    required GetTaskDetailUseCase getTaskDetailUseCase,
  })  : _getTaskDetailUseCase = getTaskDetailUseCase,
        super(const TaskDetailInitial());

  Future<void> loadTask(String taskId) async {
    emit(const TaskDetailLoading());
    final result = await _getTaskDetailUseCase(taskId);
    result.fold(
      (failure) => emit(TaskDetailError(failure)),
      (task) => emit(TaskDetailSuccess(task)),
    );
  }

  Future<void> refresh(String taskId) => loadTask(taskId);
}
