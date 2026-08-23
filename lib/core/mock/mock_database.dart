import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:task_flow/core/constants/app_constants.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/storage/hive_service.dart';

/// In-memory, mutable stand-in for a remote database, seeded once from
/// `assets/mock_data/mock-data.json`.
///
/// Every data source reads and writes through this single instance so that a
/// mutation made through one feature (e.g. creating a task) is immediately
/// visible to another (e.g. a project's task counts). Previously each data
/// source parsed the asset into its own private copy, so the copies diverged.
///
/// Rows are kept as raw `Map<String, dynamic>` exactly as they appear in the
/// asset; mapping to models/entities stays in the data layer.
class MockDatabase {
  MockDatabase({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  // ─── Tables (keyed by primary key, insertion-ordered) ──────────────────────
  final Map<String, Map<String, dynamic>> organizations = {};
  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, Map<String, dynamic>> projects = {};
  final Map<String, Map<String, dynamic>> tasks = {};
  final Map<String, Map<String, dynamic>> comments = {};
  final Map<String, Map<String, dynamic>> notifications = {};

  /// `org_members` has no `id` column in the asset, so it is stored as a list
  /// keyed by the natural composite key (org_id, user_id).
  final List<Map<String, dynamic>> orgMembers = [];

  /// The `auth_mock` object: test credentials and the canned token response.
  Map<String, dynamic> authMock = const {};

  bool _isLoaded = false;
  Future<void>? _loading;

  /// Loads and seeds the tables. Safe to call concurrently and repeatedly —
  /// the asset is parsed exactly once per instance.
  Future<void> ensureLoaded() {
    if (_isLoaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final jsonString = await _bundle.loadString(AppConstants.mockDataAsset);
      // Parsing runs off the UI isolate; the asset is small but this keeps the
      // first frame smooth and mirrors how a real payload would be handled.
      final data = await compute(_decodeJson, jsonString);
      _seed(data);
      _isLoaded = true;
    } on CacheException {
      rethrow;
    } catch (error) {
      _loading = null;
      throw ServerException(
        message: 'Unable to load mock data from '
            '"${AppConstants.mockDataAsset}". ($error)',
      );
    }
  }

  static Map<String, dynamic> _decodeJson(String source) =>
      json.decode(source) as Map<String, dynamic>;

  void _seed(Map<String, dynamic> data) {
    _fill(organizations, data['organizations']);
    _fill(users, data['users']);
    _fill(projects, data['projects']);
    _fill(tasks, data['tasks']);
    _fill(comments, data['comments']);
    _fill(notifications, data['notifications']);

    orgMembers
      ..clear()
      ..addAll(_rows(data['org_members']));

    authMock = Map<String, dynamic>.from(
      (data['auth_mock'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  static void _fill(
    Map<String, Map<String, dynamic>> table,
    Object? raw,
  ) {
    table.clear();
    for (final row in _rows(raw)) {
      final id = row['id'];
      if (id is String) table[id] = row;
    }
  }

  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row.cast<String, dynamic>()))
        .toList();
  }

  // ─── Convenience lookups ──────────────────────────────────────────────────

  /// Membership row for [userId] in [orgId], or `null` if they are not a member.
  Map<String, dynamic>? membership({
    required String orgId,
    required String userId,
  }) {
    for (final row in orgMembers) {
      if (row['org_id'] == orgId && row['user_id'] == userId) return row;
    }
    return null;
  }

  /// All membership rows for [orgId].
  List<Map<String, dynamic>> membersOf(String orgId) =>
      orgMembers.where((row) => row['org_id'] == orgId).toList();

  /// The organization a project belongs to, used for org-scoped authorization.
  String? orgIdOfProject(String projectId) =>
      projects[projectId]?['org_id'] as String?;

  /// The organization a task belongs to, resolved through its project.
  String? orgIdOfTask(String taskId) {
    final projectId = tasks[taskId]?['project_id'] as String?;
    if (projectId == null) return null;
    return orgIdOfProject(projectId);
  }

  /// Test-credential rows from `auth_mock.test_credentials`.
  List<Map<String, dynamic>> get testCredentials =>
      _rows(authMock['test_credentials']);

  /// The canned token payload from `auth_mock.mock_login_response`.
  Map<String, dynamic> get mockLoginResponse {
    final raw = authMock['mock_login_response'];
    if (raw is Map) return Map<String, dynamic>.from(raw.cast<String, dynamic>());
    throw const ServerException(
      message: 'Mock data is missing "auth_mock.mock_login_response".',
    );
  }

  // ─── Hive → MockDatabase cross-datasource merge ─────────────────────────

  bool _tasksHiveMerged = false;

  /// Merges Hive-cached tasks into [tasks] so that project task counts
  /// are accurate even when [ProjectLocalDatasource] runs before
  /// [TaskLocalDatasource].  Called once per session.
  Future<void> mergeHiveTasks() async {
    if (_tasksHiveMerged) return;
    _tasksHiveMerged = true;
    try {
      final box = HiveService.tasksBox;
      for (final key in box.keys) {
        if (key is! String || !key.startsWith('tasks_')) continue;
        final rows = HiveService.readList(box, key);
        if (rows == null) continue;
        for (final row in rows) {
          final id = row['id'] as String?;
          if (id == null) continue;
          if (tasks.containsKey(id)) continue;
          final clean = Map<String, dynamic>.from(row)
            ..remove('_assignee_name')
            ..remove('_assignee_avatar_url');
          tasks[id] = clean;
        }
      }
    } catch (_) {
      // Hive cache is best-effort.
    }
  }

  /// Drops all state so the next [ensureLoaded] re-seeds from the asset.
  /// Used by tests to isolate mutations between cases.
  @visibleForTesting
  void reset() {
    _tasksHiveMerged = false;
    organizations.clear();
    users.clear();
    projects.clear();
    tasks.clear();
    comments.clear();
    notifications.clear();
    orgMembers.clear();
    authMock = const {};
    _isLoaded = false;
    _loading = null;
  }
}
