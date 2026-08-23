import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_filter.dart';

TaskEntity _task({
  String id = 't1',
  String status = 'todo',
  String priority = 'medium',
  String? assigneeId,
  String title = 'Test Task',
  String description = 'A test task',
  DateTime? dueDate,
}) {
  return TaskEntity(
    id: id,
    projectId: 'proj1',
    title: title,
    description: description,
    status: status,
    priority: priority,
    assigneeId: assigneeId,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    dueDate: dueDate,
  );
}

void main() {
  group('TaskFilter', () {
    group('empty filter', () {
      test('matches all tasks', () {
        final filter = TaskFilter.empty;
        expect(filter.matches(_task(status: 'todo')), isTrue);
        expect(filter.matches(_task(status: 'done')), isTrue);
        expect(filter.matches(_task(priority: 'urgent')), isTrue);
      });

      test('isActive is false', () {
        expect(TaskFilter.empty.isActive, isFalse);
      });

      test('activeCount is 0', () {
        expect(TaskFilter.empty.activeCount, 0);
      });
    });

    group('status filter', () {
      test('matches tasks with exact status', () {
        final filter = TaskFilter(status: 'todo');
        expect(filter.matches(_task(status: 'todo')), isTrue);
        expect(filter.matches(_task(status: 'done')), isFalse);
      });

      test('isActive is true when set', () {
        expect(TaskFilter(status: 'todo').isActive, isTrue);
      });
    });

    group('priority filter', () {
      test('matches tasks with exact priority', () {
        final filter = TaskFilter(priority: 'urgent');
        expect(filter.matches(_task(priority: 'urgent')), isTrue);
        expect(filter.matches(_task(priority: 'low')), isFalse);
      });
    });

    group('assignee filter', () {
      test('matches specific user', () {
        final filter = TaskFilter(assigneeId: 'user_001');
        expect(filter.matches(_task(assigneeId: 'user_001')), isTrue);
        expect(filter.matches(_task(assigneeId: 'user_002')), isFalse);
        expect(filter.matches(_task(assigneeId: null)), isFalse);
      });

      test('matches unassigned via sentinel', () {
        final filter = TaskFilter(assigneeId: '__unassigned__');
        expect(filter.matches(_task(assigneeId: null)), isTrue);
        expect(filter.matches(_task(assigneeId: 'user_001')), isFalse);
      });
    });

    group('search query filter', () {
      test('matches title case-insensitively', () {
        final filter = TaskFilter(searchQuery: 'login');
        expect(filter.matches(_task(title: 'Implement Login')), isTrue);
        expect(filter.matches(_task(title: 'LOGOUT flow')), isFalse);
      });

      test('matches description', () {
        final filter = TaskFilter(searchQuery: 'backend');
        expect(filter.matches(_task(description: 'Fix backend API')), isTrue);
        expect(filter.matches(_task(description: 'Frontend only')), isFalse);
      });

      test('ignores whitespace-only queries', () {
        final filter = TaskFilter(searchQuery: '   ');
        expect(filter.matches(_task()), isTrue);
      });
    });

    group('due date range filter', () {
      test('matches tasks within range', () {
        final filter = TaskFilter(
          dueFrom: DateTime(2024, 6, 1),
          dueTo: DateTime(2024, 6, 30),
        );
        expect(filter.matches(_task(dueDate: DateTime(2024, 6, 15))), isTrue);
        expect(filter.matches(_task(dueDate: DateTime(2024, 7, 1))), isFalse);
        expect(filter.matches(_task(dueDate: DateTime(2024, 5, 31))), isFalse);
      });

      test('excludes tasks without due date', () {
        final filter = TaskFilter(dueFrom: DateTime(2024, 6, 1));
        expect(filter.matches(_task(dueDate: null)), isFalse);
      });

      test('only from-bound', () {
        final filter = TaskFilter(dueFrom: DateTime(2024, 6, 15));
        expect(filter.matches(_task(dueDate: DateTime(2024, 6, 20))), isTrue);
        expect(filter.matches(_task(dueDate: DateTime(2024, 6, 10))), isFalse);
      });
    });

    group('apply', () {
      test('filters a list of tasks', () {
        final tasks = [
          _task(id: 't1', status: 'todo'),
          _task(id: 't2', status: 'done'),
          _task(id: 't3', status: 'todo'),
        ];
        final filter = TaskFilter(status: 'todo');
        final result = filter.apply(tasks);
        expect(result.length, 2);
        expect(result.map((t) => t.id), containsAll(['t1', 't3']));
      });
    });

    group('activeCount', () {
      test('counts all active facets', () {
        final filter = TaskFilter(
          status: 'todo',
          priority: 'high',
          assigneeId: 'user_001',
        );
        expect(filter.activeCount, 3);
      });

      test('ignores null/empty values', () {
        final filter = TaskFilter(status: null, priority: '', assigneeId: null);
        expect(filter.activeCount, 0);
      });
    });

    group('copyWith', () {
      test('preserves existing values', () {
        final original = TaskFilter(status: 'todo', priority: 'high');
        final copied = original.copyWith(priority: 'low');
        expect(copied.status, 'todo');
        expect(copied.priority, 'low');
      });

      test('clears values with clear flags', () {
        final original = TaskFilter(status: 'todo', priority: 'high');
        final copied = original.copyWith(clearStatus: true);
        expect(copied.status, isNull);
        expect(copied.priority, 'high');
      });
    });
  });
}
