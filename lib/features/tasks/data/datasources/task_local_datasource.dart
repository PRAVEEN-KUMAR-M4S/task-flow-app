import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/mock_datasource_mixin.dart';
import 'package:task_flow/core/storage/hive_service.dart';
import 'package:task_flow/features/tasks/data/models/task_comment_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:uuid/uuid.dart';

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class TaskLocalDatasource {
  /// Every task in [projectId]. Filtering is a domain concern (`TaskFilter`) so
  /// the same rules apply to live and cached reads.
  Future<List<TaskEntity>> getTasksByProject(String projectId);

  Future<TaskEntity> getTaskById(String taskId);

  Future<TaskEntity> createTask({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    required String createdBy,
    DateTime? dueDate,
    List<String> tags,
  });

  Future<TaskEntity> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    DateTime? dueDate,
    List<String> tags,
  });

  Future<void> deleteTask(String taskId);

  Future<TaskEntity> assignTask({required String taskId, String? assigneeId});

  Future<TaskEntity> updateTaskStatus({
    required String taskId,
    required String status,
  });

  Future<TaskEntity> updateTaskPriority({
    required String taskId,
    required String priority,
  });

  Future<List<TaskComment>> getComments(String taskId);

  /// Last-known-good tasks for [projectId], or `null` if nothing is cached.
  List<TaskEntity>? getCachedTasks(String projectId);

  /// Looks a single task up across every cached project, so the detail screen
  /// still works offline after a deep link.
  TaskEntity? getCachedTask(String taskId);
}

// ─── Implementation ───────────────────────────────────────────────────────────

class TaskLocalDatasourceImpl
    with MockDatasourceMixin
    implements TaskLocalDatasource {
  static const _uuid = Uuid();

  final MockDatabase _db;

  @override
  final ErrorSimulator errorSimulator;

  bool _hiveMerged = false;

  TaskLocalDatasourceImpl({
    required MockDatabase database,
    required this.errorSimulator,
  }) : _db = database;

  // ─── Hive → MockDatabase merge ──────────────────────────────────────────

  Future<void> _mergeHiveIntoMock() async {
    if (_hiveMerged) return;
    _hiveMerged = true;

    try {
      final box = HiveService.tasksBox;

      for (final key in box.keys) {
        if (key is! String || !key.startsWith('tasks_')) continue;
        final rows = HiveService.readList(box, key);
        if (rows == null) continue;

        for (final row in rows) {
          final id = row['id'] as String?;
          if (id == null) continue;
          if (_db.tasks.containsKey(id)) continue;

          // Strip denormalized fields before inserting into MockDatabase.
          final clean = Map<String, dynamic>.from(row)
            ..remove('_assignee_name')
            ..remove('_assignee_avatar_url');
          _db.tasks[id] = clean;
       
        }
      }
    } catch (_) {
      // Hive cache is best-effort.
    }
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<List<TaskEntity>> getTasksByProject(String projectId) async {
    await _db.ensureLoaded();
    await _mergeHiveIntoMock();
    await simulatedDelay();
    checkForSimulatedError(projectId);

    final rows = _db.tasks.values
        .where((row) => row['project_id'] == projectId)
        .toList(growable: false);

    // The whole project is cached, not a filtered slice, so going offline
    // mid-filter doesn't silently shrink the dataset.
    await _cacheTasks(projectId, rows);

    return rows.map(_buildTask).toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
  }

  @override
  Future<TaskEntity> getTaskById(String taskId) async {
    await _db.ensureLoaded();
    await _mergeHiveIntoMock();
    await simulatedDelay();
    return _buildTask(_require(taskId));
  }

  @override
  Future<List<TaskComment>> getComments(String taskId) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(taskId);

    if (!_db.tasks.containsKey(taskId)) {
      throw NotFoundException(message: 'Task "$taskId" no longer exists.');
    }

    final rows =
        _db.comments.values.where((row) => row['task_id'] == taskId).map((row) {
          final author = _db.users[row['author_id']];
          return TaskCommentModel.fromJson(row).toEntity(
            authorName: author?['name'] as String?,
            authorAvatarUrl: author?['avatar_url'] as String?,
          );
        }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return rows;
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<TaskEntity> createTask({
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
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(null, title);

    _validate(title: title, status: status, priority: priority);
    if (!_db.projects.containsKey(projectId)) {
      throw NotFoundException(
        message: 'Project "$projectId" no longer exists.',
      );
    }
    _requireKnownAssignee(assigneeId);

    final id = 'task_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();
    final raw = <String, dynamic>{
      'id': id,
      'project_id': projectId,
      'title': title.trim(),
      'description': description.trim(),
      'status': status,
      'priority': priority,
      'assignee_id': assigneeId,
      'created_by': createdBy,
      // Date-only, matching the seeded rows — an ISO timestamp here would make
      // the overdue comparison inconsistent between seeded and new tasks.
      'due_date': dueDate == null ? null : TaskModel.formatDueDate(dueDate),
      'created_at': now,
      'updated_at': now,
      if (tags.isNotEmpty) 'tags': tags,
    };

    _db.tasks[id] = raw;
    await _cacheProject(projectId);
    return _buildTask(raw);
  }

  @override
  Future<TaskEntity> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? assigneeId,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(taskId, title);

    final existing = _require(taskId, skipErrorCheck: true);
    _validate(title: title, status: status, priority: priority);
    _requireKnownAssignee(assigneeId);

    return _commit(taskId, {
      ...existing,
      'title': title.trim(),
      'description': description.trim(),
      'status': status,
      'priority': priority,
      'assignee_id': assigneeId,
      'due_date': dueDate == null ? null : TaskModel.formatDueDate(dueDate),
      if (tags.isNotEmpty) 'tags': tags,
    });
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final existing = _require(taskId);
    _db.tasks.remove(taskId);
    // Comments and notifications pointing at a deleted task would dangle.
    _db.comments.removeWhere((_, row) => row['task_id'] == taskId);
    await _cacheProject(existing['project_id'] as String);
  }

  @override
  Future<TaskEntity> assignTask({
    required String taskId,
    String? assigneeId,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final existing = _require(taskId);
    _requireKnownAssignee(assigneeId);

    return _commit(taskId, {...existing, 'assignee_id': assigneeId});
  }

  @override
  Future<TaskEntity> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final existing = _require(taskId);
    if (!AppConstants.taskStatuses.contains(status)) {
      throw ValidationException(message: 'Unknown task status "$status".');
    }

    return _commit(taskId, {...existing, 'status': status});
  }

  @override
  Future<TaskEntity> updateTaskPriority({
    required String taskId,
    required String priority,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final existing = _require(taskId);
    if (!AppConstants.taskPriorities.contains(priority)) {
      throw ValidationException(message: 'Unknown task priority "$priority".');
    }

    return _commit(taskId, {...existing, 'priority': priority});
  }

  // ─── Cache ──────────────────────────────────────────────────────────────

  @override
  List<TaskEntity>? getCachedTasks(String projectId) {
    try {
      final cached = HiveService.readList(
        HiveService.tasksBox,
        _cacheKey(projectId),
      );
      if (cached == null || cached.isEmpty) return null;
      return cached.map(_buildTask).toList()
        ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    } catch (_) {
      return null;
    }
  }

  @override
  TaskEntity? getCachedTask(String taskId) {
    try {
      final box = HiveService.tasksBox;
      for (final key in box.keys) {
        if (key is! String || !key.startsWith('tasks_')) continue;
        final rows = HiveService.readList(box, key);
        if (rows == null) continue;
        for (final row in rows) {
          if (row['id'] == taskId) return _buildTask(row);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheProject(String projectId) => _cacheTasks(
    projectId,
    _db.tasks.values.where((row) => row['project_id'] == projectId).toList(),
  );

  Future<void> _cacheTasks(
    String projectId,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      // Denormalize the assignee so the offline list still shows names — the
      // users table isn't cached separately.
      final snapshot = rows.map((row) {
        final user = _db.users[row['assignee_id']];
        return <String, dynamic>{
          ...row,
          if (user != null) ...{
            '_assignee_name': user['name'],
            '_assignee_avatar_url': user['avatar_url'],
          },
        };
      }).toList();
      await HiveService.cacheList(
        HiveService.tasksBox,
        _cacheKey(projectId),
        snapshot,
      );
    } catch (_) {
      // Caching is best-effort; never fail the read that triggered it.
    }
  }

  static String _cacheKey(String projectId) => 'tasks_$projectId';

  // ─── Helpers ────────────────────────────────────────────────────────────

  /// Writes [row] back to the shared store, stamping `updated_at`, and returns
  /// the rebuilt entity.
  Future<TaskEntity> _commit(String taskId, Map<String, dynamic> row) async {
    final updated = <String, dynamic>{
      ...row,
      'updated_at': DateTime.now().toIso8601String(),
    };
    _db.tasks[taskId] = updated;
    await _cacheProject(updated['project_id'] as String);
    return _buildTask(updated);
  }

  Map<String, dynamic> _require(String taskId, {bool skipErrorCheck = false}) {
    final raw = _db.tasks[taskId];
    if (!skipErrorCheck) {
      checkForSimulatedError(taskId, raw?['title'] as String?);
    }
    if (raw == null) {
      throw NotFoundException(message: 'Task "$taskId" no longer exists.');
    }
    return raw;
  }

  void _validate({
    required String title,
    required String status,
    required String priority,
  }) {
    if (title.trim().isEmpty) {
      throw const ValidationException(message: 'Task title is required.');
    }
    if (!AppConstants.taskStatuses.contains(status)) {
      throw ValidationException(message: 'Unknown task status "$status".');
    }
    if (!AppConstants.taskPriorities.contains(priority)) {
      throw ValidationException(message: 'Unknown task priority "$priority".');
    }
  }

  void _requireKnownAssignee(String? assigneeId) {
    if (assigneeId == null || assigneeId.isEmpty) return;
    if (!_db.users.containsKey(assigneeId)) {
      throw NotFoundException(message: 'User "$assigneeId" does not exist.');
    }
  }

  TaskEntity _buildTask(Map<String, dynamic> raw) {
    final user = _db.users[raw['assignee_id']];
    return TaskModel.fromJson(raw).toEntity(
      // Live join when available, cached snapshot when reading offline.
      assigneeName:
          (user?['name'] as String?) ?? raw['_assignee_name'] as String?,
      assigneeAvatarUrl:
          (user?['avatar_url'] as String?) ??
          raw['_assignee_avatar_url'] as String?,
    );
  }
}
