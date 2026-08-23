/// App-wide constants for route names, Hive box names, storage keys,
/// artificial delay configuration, and error-trigger ID conventions.
class AppConstants {
  AppConstants._();

  // ─── Route Names ─────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeProjects = '/projects';
  static const String routeProjectDetail = '/projects/:projectId';
  static const String routeProjectForm = '/projects/form';
  static const String routeTaskList = '/projects/:projectId/tasks';
  static const String routeTaskDetail = '/tasks/:taskId';
  static const String routeTaskForm = '/tasks/form';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeNotifications = '/notifications';

  // ─── Hive Box Names ───────────────────────────────────────────────────────
  static const String hiveBoxProjects = 'projects_box';
  static const String hiveBoxTasks = 'tasks_box';
  static const String hiveBoxNotifications = 'notifications_box';

  // ─── Secure Storage Keys ──────────────────────────────────────────────────
  static const String storageAccessToken = 'access_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserId = 'user_id';
  static const String storageOrgId = 'org_id';
  static const String storageTokenExpiry = 'token_expiry';
  static const String storageBiometricEnabled = 'biometric_enabled';

  // ─── Asset Paths ──────────────────────────────────────────────────────────
  static const String mockDataAsset = 'assets/mock_data/mock-data.json';

  // ─── Simulation Config ───────────────────────────────────────────────────
  /// Base artificial delay in milliseconds.
  static const int simulatedDelayBaseMs = 300;

  /// Additional random jitter in milliseconds (0 to this value).
  static const int simulatedDelayJitterMs = 500;

  /// Fallback access-token lifetime, used only when the mock login response
  /// omits `access_token_expires_in_seconds`. The real value comes from
  /// `auth_mock.mock_login_response` in the mock data.
  static const int fallbackTokenExpirySeconds = 900;

  // ─── Error-Trigger Tokens ─────────────────────────────────────────────────
  /// Any project/task whose **id, name or title** contains one of these
  /// substrings triggers the corresponding simulated error in the data layer.
  ///
  /// The shipped mock data contains no such ids, so there are two ways to
  /// trigger them (both documented in Settings → Debug & Simulation):
  ///  1. Deep link to a synthetic id, e.g. `/tasks/task_err404`.
  ///  2. Create/rename a project or task with the token in its name,
  ///     e.g. "Report errTimeout".
  /// A third, non-data-driven route is the forced-error switch in Settings,
  /// see `ErrorSimulator`.
  static const String errIdPrefix404 = 'err404';
  static const String errIdPrefixTimeout = 'errTimeout';
  static const String errIdPrefixValidation = 'errValidation';

  // ─── Domain Vocabulary ────────────────────────────────────────────────────
  static const String roleOrgAdmin = 'org_admin';
  static const String roleMember = 'member';

  /// Task statuses, in workflow order. These are exactly the values present in
  /// `mock-data.json` — note `review`, not `blocked`.
  static const List<String> taskStatuses = [
    'todo',
    'in_progress',
    'review',
    'done',
  ];

  /// Task priorities, lowest first. Again taken from the mock data — the top
  /// band is `urgent`, not `critical`.
  static const List<String> taskPriorities = [
    'low',
    'medium',
    'high',
    'urgent',
  ];

  static const List<String> projectStatuses = [
    'active',
    'completed',
    'archived',
  ];

  /// Sentinel assignee filter value meaning "no assignee". A plain `null` can't
  /// express it because `null` already means "don't filter by assignee".
  static const String assigneeUnassigned = '__unassigned__';

  /// Human-readable label for a snake_case status/priority token.
  static String humanize(String token) {
    if (token.isEmpty) return '';
    return token
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
