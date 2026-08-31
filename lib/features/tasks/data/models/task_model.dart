import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

part 'task_model.g.dart';

/// Mirrors a row of the `tasks` table in the mock data:
/// `{ id, project_id, title, description, status, priority, assignee_id,
///    due_date, created_at }`.
///
/// `created_by`, `updated_at` and `tags` are absent from the seeded rows, so all
/// three are optional — they only appear on tasks created or edited in-session.
@JsonSerializable()
class TaskModel {
  final String id;
  @JsonKey(name: 'project_id')
  final String projectId;
  final String title;
  @JsonKey(defaultValue: '')
  final String description;
  final String status;
  final String priority;
  @JsonKey(name: 'assignee_id')
  final String? assigneeId;
  @JsonKey(name: 'created_by', includeIfNull: false)
  final String? createdBy;

  /// Date-only string, `yyyy-MM-dd`, matching the source format.
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final String? updatedAt;
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  @JsonKey(name: 'is_favorite', defaultValue: false)
  final bool isFavorite;
  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.createdBy,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.isFavorite = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  /// Formats a [DateTime] as the date-only string the mock data uses.
  static String formatDueDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  TaskEntity toEntity({String? assigneeName, String? assigneeAvatarUrl}) {
    return TaskEntity(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      createdBy: createdBy,
      dueDate: dueDate == null ? null : DateTime.tryParse(dueDate!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt!),
      tags: tags,
      assigneeName: assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl,
      isFavorite: isFavorite,
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      assigneeId: entity.assigneeId,
      createdBy: entity.createdBy,
      dueDate: entity.dueDate == null ? null : formatDueDate(entity.dueDate!),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt?.toIso8601String(),
      tags: entity.tags,
      isFavorite: entity.isFavorite,
    );
  }
}
