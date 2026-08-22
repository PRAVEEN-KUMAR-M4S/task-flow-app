import 'package:equatable/equatable.dart';

/// Domain entity for an in-app notification.
///
/// Mirrors what the mock data actually provides: a `type`, a human-readable
/// `message` and an optional `taskId` to deep-link to. There is no separate
/// title/body pair in the payload, so the heading is derived from [type].
class NotificationEntity extends Equatable {
  final String id;
  final String userId;

  /// 'task_assigned' | 'task_status_changed' | 'task_comment' | …
  final String type;
  final String message;
  final String? taskId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.taskId,
    required this.isRead,
    required this.createdAt,
  });

  /// Heading shown above [message], derived from [type] since the payload has
  /// no title column.
  String get title => switch (type) {
        'task_assigned' => 'Task assigned',
        'task_status_changed' => 'Status changed',
        'task_comment' => 'New comment',
        'task_due_soon' => 'Task due soon',
        _ => 'Notification',
      };

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    String? taskId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      taskId: taskId ?? this.taskId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, message, taskId, isRead, createdAt];
}
