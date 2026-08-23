import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/usecases/assign_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_status_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockAssignTaskUseCase extends Mock implements AssignTaskUseCase {}
class MockUpdateTaskStatusUseCase extends Mock implements UpdateTaskStatusUseCase {}

void main() {
  late TaskBloc bloc;
  late MockGetTasksUseCase mockGetTasks;
  late MockCreateTaskUseCase mockCreate;
  late MockDeleteTaskUseCase mockDelete;
  late MockUpdateTaskStatusUseCase mockUpdateStatus;
  late MockAssignTaskUseCase mockAssign;

  late final testTasks = <TaskEntity>[
    TaskEntity(
      id: 't1', projectId: 'p1', title: 'Task 1', description: 'Desc 1',
      status: 'todo', priority: 'medium',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ),
    TaskEntity(
      id: 't2', projectId: 'p1', title: 'Task 2', description: 'Desc 2',
      status: 'done', priority: 'high',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ),
    TaskEntity(
      id: 't3', projectId: 'p1', title: 'Task 3', description: 'Desc 3',
      status: 'todo', priority: 'low', assigneeId: 'user_001',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const GetTasksParams(projectId: 'p1'));
  });

  setUp(() {
    mockGetTasks = MockGetTasksUseCase();
    mockCreate = MockCreateTaskUseCase();
    mockDelete = MockDeleteTaskUseCase();
    mockUpdateStatus = MockUpdateTaskStatusUseCase();
    mockAssign = MockAssignTaskUseCase();

    bloc = TaskBloc(
      getTasksUseCase: mockGetTasks,
      createTaskUseCase: mockCreate,
      updateTaskUseCase: MockUpdateTaskUseCase(),
      deleteTaskUseCase: mockDelete,
      assignTaskUseCase: mockAssign,
      updateTaskStatusUseCase: mockUpdateStatus,
    );
  });

  tearDown(() => bloc.close());

  group('TaskBloc', () {
    test('initial state is TaskInitial', () {
      expect(bloc.state, isA<TaskInitial>());
    });

    group('TasksLoadRequested', () {
      blocTest<TaskBloc, TaskState>(
        'emits TaskLoading → TaskSuccess with tasks',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => Right(testTasks),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const TasksLoadRequested('p1')),
        expect: () => [
          isA<TaskLoading>(),
          predicate<TaskState>((s) =>
              s is TaskSuccess && s.tasks.length == 3),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'emits TaskLoading → TaskEmpty when no tasks',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => const Right([]),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const TasksLoadRequested('p1')),
        expect: () => [
          isA<TaskLoading>(),
          isA<TaskEmpty>(),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'emits TaskLoading → TaskError on failure',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => Left<Failure, List<TaskEntity>>(ServerFailure(message: 'Server error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const TasksLoadRequested('p1')),
        expect: () => [
          isA<TaskLoading>(),
          predicate<TaskState>((s) =>
              s is TaskError && s.failure.message == 'Server error'),
        ],
      );
    });

    group('TaskFilterChanged', () {
      blocTest<TaskBloc, TaskState>(
        'filters tasks by status',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => Right(testTasks),
          );
          return bloc;
        },
        act: (bloc) {
          bloc.add(const TasksLoadRequested('p1'));
          bloc.add(const TaskFilterChanged(status: 'todo'));
        },
        skip: 2, // skip Loading + Success
        expect: () => [
          predicate<TaskState>((s) =>
              s is TaskSuccess && s.tasks.length == 2), // t1, t3 are 'todo'
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'filters tasks by priority',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => Right(testTasks),
          );
          return bloc;
        },
        act: (bloc) {
          bloc.add(const TasksLoadRequested('p1'));
          bloc.add(const TaskFilterChanged(priority: 'high'));
        },
        skip: 2,
        expect: () => [
          predicate<TaskState>((s) =>
              s is TaskSuccess && s.tasks.length == 1 && s.tasks.first.id == 't2'),
        ],
      );
    });

    group('TaskDeleted', () {
      blocTest<TaskBloc, TaskState>(
        'calls delete use case',
        build: () {
          when(() => mockGetTasks(any())).thenAnswer(
            (_) async => Right(testTasks),
          );
          when(() => mockDelete(any())).thenAnswer(
            (_) async => const Right(unit),
          );
          return bloc;
        },
        act: (bloc) {
          bloc.add(const TasksLoadRequested('p1'));
          bloc.add(const TaskDeleted('t1'));
        },
        skip: 2, // skip Loading + Success
        verify: (_) => verify(() => mockDelete('t1')).called(1),
      );
    });
  });
}
