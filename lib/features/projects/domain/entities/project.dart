import 'package:equatable/equatable.dart';

/// Domain entity for a project.
///
/// `createdBy` and `updatedAt` are nullable: the seeded rows in `mock-data.json`
/// carry neither, only projects created or edited in-session have them.
class Project extends Equatable {
  final String id;
  final String orgId;
  final String name;
  final String description;
  final String status; // 'active' | 'completed' | 'archived'
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Per-status task counts, computed from the tasks table by the data layer so
  /// they stay correct after tasks are added, moved or deleted.
  final int totalTasks;
  final int todoTasks;
  final int inProgressTasks;
  final int reviewTasks;
  final int completedTasks;

  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.totalTasks = 0,
    this.todoTasks = 0,
    this.inProgressTasks = 0,
    this.reviewTasks = 0,
    this.completedTasks = 0,
  });

  /// Most recent activity timestamp — falls back to creation when the project
  /// has never been edited.
  DateTime get lastActivityAt => updatedAt ?? createdAt;

  double get completionPercentage =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  Project copyWith({
    String? id,
    String? orgId,
    String? name,
    String? description,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalTasks,
    int? todoTasks,
    int? inProgressTasks,
    int? reviewTasks,
    int? completedTasks,
  }) {
    return Project(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalTasks: totalTasks ?? this.totalTasks,
      todoTasks: todoTasks ?? this.todoTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      reviewTasks: reviewTasks ?? this.reviewTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orgId,
        name,
        description,
        status,
        createdBy,
        createdAt,
        updatedAt,
        totalTasks,
        todoTasks,
        inProgressTasks,
        reviewTasks,
        completedTasks,
      ];
}
