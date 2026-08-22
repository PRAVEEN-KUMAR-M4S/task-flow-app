import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/assign_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_status_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class TasksLoadRequested extends TaskEvent {
  final String projectId;
  const TasksLoadRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class TaskFilterChanged extends TaskEvent {
  final String? status;
  final String? priority;
  final String? assigneeId;
  final String? searchQuery;

  const TaskFilterChanged({
    this.status,
    this.priority,
    this.assigneeId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [status, priority, assigneeId, searchQuery];
}

class TaskAssigned extends TaskEvent {
  final String taskId;
  final String? assigneeId;
  final String orgId;

  const TaskAssigned({
    required this.taskId,
    this.assigneeId,
    required this.orgId,
  });

  @override
  List<Object?> get props => [taskId, assigneeId, orgId];
}

class TaskStatusUpdated extends TaskEvent {
  final String taskId;
  final String status;

  const TaskStatusUpdated({required this.taskId, required this.status});

  @override
  List<Object?> get props => [taskId, status];
}

class TaskCreated extends TaskEvent {
  final CreateTaskParams params;
  const TaskCreated(this.params);
  @override
  List<Object?> get props => [params];
}

class TaskUpdated extends TaskEvent {
  final UpdateTaskParams params;
  const TaskUpdated(this.params);
  @override
  List<Object?> get props => [params];
}

class TaskDeleted extends TaskEvent {
  final String taskId;
  const TaskDeleted(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class TaskRefreshRequested extends TaskEvent {
  final String projectId;
  const TaskRefreshRequested(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskSuccess extends TaskState {
  final List<TaskEntity> tasks;
  final bool isStale;

  const TaskSuccess({required this.tasks, this.isStale = false});

  @override
  List<Object?> get props => [tasks, isStale];
}

class TaskEmpty extends TaskState {
  const TaskEmpty();
}

class TaskError extends TaskState {
  final Failure failure;
  const TaskError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final AssignTaskUseCase _assignTaskUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;

  List<TaskEntity> _allTasks = [];
  String? _currentProjectId;

  // Cache filter parameters
  String? _statusFilter;
  String? _priorityFilter;
  String? _assigneeFilter;
  String? _searchFilter;

  TaskBloc({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required AssignTaskUseCase assignTaskUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _assignTaskUseCase = assignTaskUseCase,
        _updateTaskStatusUseCase = updateTaskStatusUseCase,
        super(const TaskInitial()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TaskFilterChanged>(_onFilterChanged);
    on<TaskAssigned>(_onAssigned);
    on<TaskStatusUpdated>(_onStatusUpdated);
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TaskDeleted>(_onDeleted);
    on<TaskRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(TasksLoadRequested event, Emitter<TaskState> emit) async {
    _currentProjectId = event.projectId;
    emit(const TaskLoading());

    // Fetch all unfiltered tasks first
    final result = await _getTasksUseCase(GetTasksParams(projectId: event.projectId));

    result.fold(
      (failure) => emit(TaskError(failure)),
      (tasks) {
        _allTasks = tasks;
        _applyFilters(emit);
      },
    );
  }

  void _onFilterChanged(TaskFilterChanged event, Emitter<TaskState> emit) {
    _statusFilter = event.status;
    _priorityFilter = event.priority;
    _assigneeFilter = event.assigneeId;
    _searchFilter = event.searchQuery;

    _applyFilters(emit);
  }

  void _applyFilters(Emitter<TaskState> emit) {
    var filtered = List<TaskEntity>.from(_allTasks);

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t.status == _statusFilter).toList();
    }
    if (_priorityFilter != null && _priorityFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t.priority == _priorityFilter).toList();
    }
    if (_assigneeFilter != null && _assigneeFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t.assigneeId == _assigneeFilter).toList();
    }
    if (_searchFilter != null && _searchFilter!.isNotEmpty) {
      final query = _searchFilter!.toLowerCase();
      filtered = filtered.where((t) =>
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query)).toList();
    }

    if (filtered.isEmpty) {
      emit(const TaskEmpty());
    } else {
      emit(TaskSuccess(tasks: filtered));
    }
  }

  Future<void> _onAssigned(TaskAssigned event, Emitter<TaskState> emit) async {
    final result = await _assignTaskUseCase(AssignTaskParams(
      taskId: event.taskId,
      assigneeId: event.assigneeId,
      orgId: event.orgId,
    ));

    result.fold(
      (failure) => emit(TaskError(failure)),
      (updatedTask) {
        // Update local memory
        final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
        _applyFilters(emit);
      },
    );
  }

  Future<void> _onStatusUpdated(TaskStatusUpdated event, Emitter<TaskState> emit) async {
    final result = await _updateTaskStatusUseCase(UpdateTaskStatusParams(
      taskId: event.taskId,
      status: event.status,
    ));

    result.fold(
      (failure) => emit(TaskError(failure)),
      (updatedTask) {
        final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
        _applyFilters(emit);
      },
    );
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TaskState> emit) async {
    final result = await _createTaskUseCase(event.params);

    result.fold(
      (failure) => emit(TaskError(failure)),
      (newTask) {
        _allTasks.insert(0, newTask);
        _applyFilters(emit);
      },
    );
  }

  Future<void> _onUpdated(TaskUpdated event, Emitter<TaskState> emit) async {
    final result = await _updateTaskUseCase(event.params);

    result.fold(
      (failure) => emit(TaskError(failure)),
      (updatedTask) {
        final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
        _applyFilters(emit);
      },
    );
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TaskState> emit) async {
    final result = await _deleteTaskUseCase(event.taskId);

    result.fold(
      (failure) => emit(TaskError(failure)),
      (_) {
        _allTasks.removeWhere((t) => t.id == event.taskId);
        _applyFilters(emit);
      },
    );
  }

  Future<void> _onRefreshRequested(TaskRefreshRequested event, Emitter<TaskState> emit) async {
    if (_currentProjectId != null) {
      add(TasksLoadRequested(_currentProjectId!));
    }
  }
}
