import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_favorite_usecases.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';

// ─── States ─────────────────────────────────────────────────────────────────

abstract class TaskListState extends Equatable {
  const TaskListState();
  @override
  List<Object?> get props => [];
}

class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListSuccess extends TaskListState {
  final List<TaskEntity> tasks;
  final bool isStale;
  const TaskListSuccess({required this.tasks, this.isStale = false});
  @override
  List<Object?> get props => [tasks, isStale];
}

class TaskListEmpty extends TaskListState {
  const TaskListEmpty();
}

class TaskListError extends TaskListState {
  final Failure failure;
  const TaskListError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Cubit ──────────────────────────────────────────────────────────────────

/// Manages the task list — loading, filtering, and list-level CRUD.
class TaskListCubit extends Cubit<TaskListState> {
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final ToggleFavoriteUsecases _favoriteUsecases;

  List<TaskEntity> _allTasks = [];
  String? _currentProjectId;
  String? _statusFilter;
  String? _priorityFilter;
  String? _assigneeFilter;
  String? _searchQuery;

  TaskListCubit({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required ToggleFavoriteUsecases favoriteUsecases,
  }) : _getTasksUseCase = getTasksUseCase,
       _createTaskUseCase = createTaskUseCase,
       _updateTaskUseCase = updateTaskUseCase,
       _deleteTaskUseCase = deleteTaskUseCase,
       _favoriteUsecases = favoriteUsecases,
       super(const TaskListInitial());

  /// Load tasks for a project.
  Future<void> loadTasks(String projectId) async {
    _currentProjectId = projectId;
    emit(const TaskListLoading());
    final result = await _getTasksUseCase(GetTasksParams(projectId: projectId));
    result.fold((failure) => emit(TaskListError(failure)), (tasks) {
      _allTasks = tasks;
      _applyFilters();
    });
  }

  /// Refresh the current list.
  void refresh() {
    if (_currentProjectId != null) loadTasks(_currentProjectId!);
  }

  // ─── Filters ───────────────────────────────────────────────────────────

  void filterByStatus(String? status) {
    _statusFilter = status;
    _applyFilters();
  }

  void filterByPriority(String? priority) {
    _priorityFilter = priority;
    _applyFilters();
  }

  void filterByAssignee(String? assigneeId) {
    _assigneeFilter = assigneeId;
    _applyFilters();
  }

  void filterBySearch(String? query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<TaskEntity>.from(_allTasks);
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t.status == _statusFilter).toList();
    }
    if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t.priority == _priorityFilter).toList();
    }
    if (_assigneeFilter != null && _assigneeFilter!.isNotEmpty) {
      filtered = filtered
          .where((t) => t.assigneeId == _assigneeFilter)
          .toList();
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q),
          )
          .toList();
    }
    emit(
      filtered.isEmpty
          ? const TaskListEmpty()
          : TaskListSuccess(tasks: filtered),
    );
  }

  // ─── Mutations ─────────────────────────────────────────────────────────

  /// Create task. Returns null on success, error message on failure.
  Future<String?> createTask(CreateTaskParams params) async {
    final result = await _createTaskUseCase(params);
    return result.fold((f) => f.message, (newTask) {
      _allTasks.insert(0, newTask);
      _applyFilters();
      return null;
    });
  }

  /// Update task. Returns null on success, error message on failure.
  Future<String?> updateTask(UpdateTaskParams params) async {
    final result = await _updateTaskUseCase(params);
    return result.fold((f) => f.message, (updated) {
      final i = _allTasks.indexWhere((t) => t.id == updated.id);
      if (i != -1) _allTasks[i] = updated;
      _applyFilters();
      return null;
    });
  }

  /// Delete task. Returns null on success, error message on failure.
  Future<String?> deleteTask(String taskId) async {
    final result = await _deleteTaskUseCase(taskId);
    return result.fold((f) => f.message, (_) {
      _allTasks.removeWhere((t) => t.id == taskId);
      _applyFilters();
      return null;
    });
  }

  Future<String?> toggleFavorite(String taskId) async {
    final result = await _favoriteUsecases(taskId: taskId);

    return result.fold((failure) => failure.message, (updatedTask) {
      final index = _allTasks.indexWhere((task) => task.id == updatedTask.id);

      if (index != -1) {
        _allTasks[index] = updatedTask;
      }

      _applyFilters();

      return null;
    });
  }
}
