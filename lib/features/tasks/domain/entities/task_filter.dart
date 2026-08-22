import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

/// The task-list filter, expressed as a domain value object.
///
/// Filtering lives here rather than in the data source or the widget so the
/// same rules apply to a live read and to a cached (offline) read, and so the
/// behaviour is unit-testable without a data source at all.
class TaskFilter extends Equatable {
  /// One of [AppConstants.taskStatuses], or `null` for any.
  final String? status;

  /// One of [AppConstants.taskPriorities], or `null` for any.
  final String? priority;

  /// A user id, [AppConstants.assigneeUnassigned], or `null` for any.
  final String? assigneeId;

  /// Case-insensitive substring match on title and description.
  final String? searchQuery;

  /// Inclusive due-date window. A task with no due date matches neither bound.
  final DateTime? dueFrom;
  final DateTime? dueTo;

  const TaskFilter({
    this.status,
    this.priority,
    this.assigneeId,
    this.searchQuery,
    this.dueFrom,
    this.dueTo,
  });

  static const empty = TaskFilter();

  bool get isActive =>
      _has(status) ||
      _has(priority) ||
      _has(assigneeId) ||
      _has(searchQuery) ||
      dueFrom != null ||
      dueTo != null;

  /// How many facets are narrowing the list — drives the filter-bar badge.
  int get activeCount => [
        _has(status),
        _has(priority),
        _has(assigneeId),
        _has(searchQuery),
        dueFrom != null || dueTo != null,
      ].where((active) => active).length;

  bool matches(TaskEntity task) {
    if (_has(status) && task.status != status) return false;
    if (_has(priority) && task.priority != priority) return false;

    if (_has(assigneeId)) {
      if (assigneeId == AppConstants.assigneeUnassigned) {
        if (task.assigneeId != null) return false;
      } else if (task.assigneeId != assigneeId) {
        return false;
      }
    }

    final query = searchQuery?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      final haystack =
          '${task.title} ${task.description} ${task.assigneeName ?? ''}'
              .toLowerCase();
      if (!haystack.contains(query)) return false;
    }

    if (dueFrom != null || dueTo != null) {
      final due = task.dueDate;
      if (due == null) return false;
      final day = DateTime(due.year, due.month, due.day);
      if (dueFrom != null && day.isBefore(_dateOnly(dueFrom!))) return false;
      if (dueTo != null && day.isAfter(_dateOnly(dueTo!))) return false;
    }

    return true;
  }

  List<TaskEntity> apply(Iterable<TaskEntity> tasks) =>
      tasks.where(matches).toList();

  /// `copyWith` can't clear a field, so each clearable facet has a flag.
  TaskFilter copyWith({
    String? status,
    String? priority,
    String? assigneeId,
    String? searchQuery,
    DateTime? dueFrom,
    DateTime? dueTo,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearAssignee = false,
    bool clearSearch = false,
    bool clearDueRange = false,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      dueFrom: clearDueRange ? null : (dueFrom ?? this.dueFrom),
      dueTo: clearDueRange ? null : (dueTo ?? this.dueTo),
    );
  }

  static bool _has(String? value) => value != null && value.isNotEmpty;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props =>
      [status, priority, assigneeId, searchQuery, dueFrom, dueTo];
}
