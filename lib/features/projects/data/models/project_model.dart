import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';

part 'project_model.g.dart';

/// Mirrors a row of the `projects` table in the mock data:
/// `{ id, org_id, name, description, task_count, status, created_at }`.
///
/// `created_by` and `updated_at` are absent from the seeded rows, so both are
/// optional — they are only populated for projects created or edited in-session.
@JsonSerializable()
class ProjectModel {
  final String id;
  @JsonKey(name: 'org_id')
  final String orgId;
  final String name;
  @JsonKey(defaultValue: '')
  final String description;
  final String status;

  /// The count carried by the payload. Kept so the serialized row round-trips
  /// (and so the offline cache stays faithful), but the per-status breakdown
  /// shown in the UI is recomputed from the tasks table.
  @JsonKey(name: 'task_count', defaultValue: 0)
  final int taskCount;

  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'created_by', includeIfNull: false)
  final String? createdBy;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final String? updatedAt;

  const ProjectModel({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.status,
    this.taskCount = 0,
    required this.createdAt,
    this.createdBy,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectModelToJson(this);

  /// Converts to the domain entity.
  ///
  /// Callers that have the tasks table available pass the computed breakdown;
  /// callers that do not (e.g. reading a cached row in isolation) fall back to
  /// the payload's own `task_count` for the total.
  Project toEntity({
    int? totalTasks,
    int todoTasks = 0,
    int inProgressTasks = 0,
    int reviewTasks = 0,
    int completedTasks = 0,
  }) {
    return Project(
      id: id,
      orgId: orgId,
      name: name,
      description: description,
      status: status,
      createdBy: createdBy,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt!),
      totalTasks: totalTasks ?? taskCount,
      todoTasks: todoTasks,
      inProgressTasks: inProgressTasks,
      reviewTasks: reviewTasks,
      completedTasks: completedTasks,
    );
  }

  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      orgId: project.orgId,
      name: project.name,
      description: project.description,
      status: project.status,
      taskCount: project.totalTasks,
      createdAt: project.createdAt.toIso8601String(),
      createdBy: project.createdBy,
      updatedAt: project.updatedAt?.toIso8601String(),
    );
  }
}
