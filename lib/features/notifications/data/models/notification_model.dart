import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/features/notifications/domain/entities/notification_entity.dart';

part 'notification_model.g.dart';

/// Mirrors a row of the `notifications` table in the mock data:
/// `{ id, user_id, type, task_id, message, read, created_at }`.
///
/// Note the read flag is `read`, not `is_read`; writing the wrong key silently
/// turned "mark as read" into a no-op.
@JsonSerializable()
class NotificationModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String type;
  @JsonKey(defaultValue: '')
  final String message;
  @JsonKey(name: 'task_id')
  final String? taskId;
  @JsonKey(name: 'read', defaultValue: false)
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.taskId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: userId,
      type: type,
      message: message,
      taskId: taskId,
      isRead: isRead,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      message: entity.message,
      taskId: entity.taskId,
      isRead: entity.isRead,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
