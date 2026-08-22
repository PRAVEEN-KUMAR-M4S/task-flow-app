import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/mock/error_simulator.dart';
import 'package:task_flow/core/mock/mock_database.dart';
import 'package:task_flow/core/network/mock_datasource_mixin.dart';
import 'package:task_flow/core/storage/hive_service.dart';
import 'package:task_flow/features/notifications/data/models/notification_model.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class NotificationLocalDatasource {
  Future<List<NotificationEntity>> getNotifications(String userId);
  Future<NotificationEntity> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  List<NotificationEntity>? getCachedNotifications(String userId);
}

// ─── Implementation ───────────────────────────────────────────────────────────

class NotificationLocalDatasourceImpl
    with MockDatasourceMixin
    implements NotificationLocalDatasource {
  final MockDatabase _db;

  @override
  final ErrorSimulator errorSimulator;

  NotificationLocalDatasourceImpl({
    required MockDatabase database,
    required this.errorSimulator,
  }) : _db = database;

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(userId);

    final rows = _db.notifications.values
        .where((row) => row['user_id'] == userId)
        .toList(growable: false);

    await _cache(userId, rows);

    return rows.map(_build).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<NotificationEntity> markAsRead(String notificationId) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(notificationId);

    final existing = _db.notifications[notificationId];
    if (existing == null) {
      throw NotFoundException(
        message: 'Notification "$notificationId" no longer exists.',
      );
    }

    // The flag is `read`; writing `is_read` added a key nothing reads back,
    // which made this a silent no-op.
    final updated = <String, dynamic>{...existing, 'read': true};
    _db.notifications[notificationId] = updated;
    await _cacheUser(updated['user_id'] as String);
    return _build(updated);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _db.ensureLoaded();
    await simulatedDelay();
    checkForSimulatedError(userId);

    for (final entry in _db.notifications.entries.toList()) {
      if (entry.value['user_id'] != userId) continue;
      _db.notifications[entry.key] = <String, dynamic>{
        ...entry.value,
        'read': true,
      };
    }
    await _cacheUser(userId);
  }

  // ─── Cache ──────────────────────────────────────────────────────────────

  @override
  List<NotificationEntity>? getCachedNotifications(String userId) {
    try {
      final cached = HiveService.readList(
        HiveService.notificationsBox,
        _cacheKey(userId),
      );
      if (cached == null || cached.isEmpty) return null;
      return cached.map(_build).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(String userId) => _cache(
        userId,
        _db.notifications.values
            .where((row) => row['user_id'] == userId)
            .toList(),
      );

  Future<void> _cache(String userId, List<Map<String, dynamic>> rows) async {
    try {
      await HiveService.cacheList(
        HiveService.notificationsBox,
        _cacheKey(userId),
        rows,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  static String _cacheKey(String userId) => 'notifications_$userId';

  NotificationEntity _build(Map<String, dynamic> raw) =>
      NotificationModel.fromJson(raw).toEntity();
}
