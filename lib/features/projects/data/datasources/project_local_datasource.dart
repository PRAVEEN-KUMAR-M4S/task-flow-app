import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/mock_datasource_mixin.dart';
import 'package:task_flow/core/storage/hive_service.dart';
import 'package:task_flow/features/projects/data/models/project_model.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';
import 'package:uuid/uuid.dart';

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class ProjectLocalDatasource {
  Future<List<Project>> getProjects({required String orgId});
  Future<Project> getProjectById(String id);
  Future<Project> createProject({
    required String orgId,
    required String name,
    required String description,
    required String createdBy,
  });
  Future<Project> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  });
  Future<void> deleteProject(String id);

  /// Last-known-good projects for [orgId], or `null` if nothing is cached.
  List<Project>? getCachedProjects(String orgId);

  /// Looks a single project up in the cache, scanning every cached org so the
  /// detail screen still works offline after a deep link.
  Project? getCachedProject(String id);
}

// ─── Implementation ───────────────────────────────────────────────────────────

class ProjectLocalDatasourceImpl
    with MockDatasourceMixin
    implements ProjectLocalDatasource {
  static const _uuid = Uuid();

  final MockDatabase _db;

  @override
  final ErrorSimulator errorSimulator;

  bool _hiveMerged = false;

  ProjectLocalDatasourceImpl({
    required MockDatabase database,
    required this.errorSimulator,
  }) : _db = database;

  // ─── Hive → MockDatabase merge ──────────────────────────────────────────

  /// After MockDatabase seeds from the JSON asset, scan Hive for any
  /// locally-created projects that the JSON doesn't contain and merge them in.
  /// This runs exactly once per app session.
  Future<void> _mergeHiveIntoMock() async {
    if (_hiveMerged) return;
    _hiveMerged = true;

    try {
      final box = HiveService.projectsBox;

      for (final key in box.keys) {
        if (key is! String || !key.startsWith('projects_')) continue;
        final rows = HiveService.readList(box, key);
        if (rows == null) continue;

        for (final row in rows) {
          final id = row['id'] as String?;
          if (id == null) continue;
          if (_db.projects.containsKey(id)) continue; // already in MockDatabase

          // This project was created locally in a previous session.
          _db.projects[id] = row;
        }
      }
    } catch (_) {
      // Hive cache is best-effort; never fail the read.
    }

    // Ensure Hive-cached tasks are also in-memory so that _countsFor()
    // returns correct numbers for locally-created projects.
    await _db.mergeHiveTasks();
  }

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<List<Project>> getProjects({required String orgId}) async {
    await _db.ensureLoaded();
    await _mergeHiveIntoMock();
    await simulatedDelay();

    final rows = _db.projects.values
        .where((row) => row['org_id'] == orgId)
        .toList(growable: false);

    final projects = rows.map(_buildProject).toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    // Cache on every *successful* read, not just on mutation — otherwise the
    // offline path has nothing to fall back to on a cold start.
    await _cacheProjects(orgId, rows);

    return projects;
  }

  @override
  Future<Project> getProjectById(String id) async {
    await _db.ensureLoaded();
    await _mergeHiveIntoMock();
    await simulatedDelay();

    final raw = _db.projects[id];
    checkForSimulatedError(id, raw?['name'] as String?);
    if (raw == null) {
      throw NotFoundException(message: 'Project "$id" no longer exists.');
    }
    return _buildProject(raw);
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<Project> createProject({
    required String orgId,
    required String name,
    required String description,
    required String createdBy,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(null, name);

    if (name.trim().isEmpty) {
      throw const ValidationException(message: 'Project name is required.');
    }

    final id = 'proj_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now().toIso8601String();
    final raw = <String, dynamic>{
      'id': id,
      'org_id': orgId,
      'name': name.trim(),
      'description': description.trim(),
      'task_count': 0,
      'status': 'active',
      'created_by': createdBy,
      'created_at': now,
      'updated_at': now,
    };

    _db.projects[id] = raw;

    await _cacheOrg(orgId);
    return _buildProject(raw);
  }

  @override
  Future<Project> updateProject({
    required String id,
    required String name,
    required String description,
    required String status,
  }) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(id, name);

    final existing = _db.projects[id];
    if (existing == null) {
      throw NotFoundException(message: 'Project "$id" no longer exists.');
    }
    if (name.trim().isEmpty) {
      throw const ValidationException(message: 'Project name is required.');
    }
    if (!AppProjectStatus.isValid(status)) {
      throw ValidationException(message: 'Unknown project status "$status".');
    }

    final updated = <String, dynamic>{
      ...existing,
      'name': name.trim(),
      'description': description.trim(),
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    _db.projects[id] = updated;

    await _cacheOrg(updated['org_id'] as String);
    return _buildProject(updated);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _db.ensureLoaded();
    await simulatedDelay();

    final existing = _db.projects[id];
    checkForSimulatedError(id, existing?['name'] as String?);
    if (existing == null) {
      throw NotFoundException(message: 'Project "$id" no longer exists.');
    }

    _db.projects.remove(id);

    // Cascade: a task can't outlive its project, and orphans would corrupt the
    // per-project counts on the next read.
    _db.tasks.removeWhere((_, task) => task['project_id'] == id);
    await _cacheOrg(existing['org_id'] as String);
  }

  // ─── Cache ──────────────────────────────────────────────────────────────

  @override
  List<Project>? getCachedProjects(String orgId) {
    try {
      final cached = HiveService.readList(
        HiveService.projectsBox,
        _cacheKey(orgId),
      );
      if (cached == null || cached.isEmpty) return null;
      return cached.map((raw) => ProjectModel.fromJson(raw).toEntity()).toList()
        ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    } catch (_) {
      return null;
    }
  }

  @override
  Project? getCachedProject(String id) {
    try {
      final box = HiveService.projectsBox;
      for (final key in box.keys) {
        if (key is! String || !key.startsWith('projects_')) continue;
        final rows = HiveService.readList(box, key);
        if (rows == null) continue;
        for (final row in rows) {
          if (row['id'] == id) return ProjectModel.fromJson(row).toEntity();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheOrg(String orgId) => _cacheProjects(
    orgId,
    _db.projects.values.where((row) => row['org_id'] == orgId).toList(),
  );

  Future<void> _cacheProjects(
    String orgId,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      final snapshot = rows.map((row) {
        final counts = _countsFor(row['id'] as String);
        return <String, dynamic>{...row, 'task_count': counts.total};
      }).toList();
      await HiveService.cacheList(
        HiveService.projectsBox,
        _cacheKey(orgId),
        snapshot,
      );
    } catch (_) {
      // A cache miss must never fail the read it was piggy-backing on.
    }
  }

  static String _cacheKey(String orgId) => 'projects_$orgId';

  // ─── Helpers ────────────────────────────────────────────────────────────

  Project _buildProject(Map<String, dynamic> raw) {
    final counts = _countsFor(raw['id'] as String);
    return ProjectModel.fromJson(raw).toEntity(
      totalTasks: counts.total,
      todoTasks: counts.todo,
      inProgressTasks: counts.inProgress,
      reviewTasks: counts.review,
      completedTasks: counts.done,
    );
  }

  _TaskCounts _countsFor(String projectId) {
    var total = 0, todo = 0, inProgress = 0, review = 0, done = 0;
    for (final task in _db.tasks.values) {
      if (task['project_id'] != projectId) continue;
      total++;
      switch (task['status']) {
        case 'todo':
          todo++;
        case 'in_progress':
          inProgress++;
        case 'review':
          review++;
        case 'done':
          done++;
      }
    }
    return _TaskCounts(
      total: total,
      todo: todo,
      inProgress: inProgress,
      review: review,
      done: done,
    );
  }
}

class _TaskCounts {
  final int total;
  final int todo;
  final int inProgress;
  final int review;
  final int done;

  const _TaskCounts({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.review,
    required this.done,
  });
}

abstract final class AppProjectStatus {
  static const active = 'active';
  static const completed = 'completed';
  static const archived = 'archived';
  static const all = <String>[active, completed, archived];

  static bool isValid(String value) => all.contains(value);
}
