import 'package:equatable/equatable.dart';
import 'package:task_flow/core/constants/app_constants.dart';

/// Domain entity for a task.
///
/// `createdBy` and `updatedAt` are nullable because the seeded rows in
/// `mock-data.json` carry neither — only tasks created or edited in-session do.
class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status; // 'todo' | 'in_progress' | 'review' | 'done'
  final String priority; // 'low' | 'medium' | 'high' | 'urgent'
  final String? assigneeId;
  final String? createdBy;

  /// Date-only in the source data (`"2026-01-05"`), so the time component is
  /// always midnight local and must not be shown.
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;

  // Joined from the `users` table by the data layer.
  final String? assigneeName;
  final String? assigneeAvatarUrl;

  const TaskEntity({
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
    this.assigneeName,
    this.assigneeAvatarUrl,
  });

  bool get isDone => status == 'done';

  bool get isAssigned => assigneeId != null && assigneeId!.isNotEmpty;

  /// Most recent activity timestamp — creation time when never edited.
  DateTime get lastActivityAt => updatedAt ?? createdAt;

  /// True when the due date has passed and the task is not yet done.
  /// Compared date-to-date so a task due today is never "overdue".
  bool get isOverdue {
    final due = dueDate;
    if (due == null || isDone) return false;
    final today = DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  String get statusLabel => AppConstants.humanize(status);

  String get priorityLabel => AppConstants.humanize(priority);

  TaskEntity copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    bool clearAssignee = false,
    String? createdBy,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? assigneeName,
    String? assigneeAvatarUrl,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      createdBy: createdBy ?? this.createdBy,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      assigneeName: clearAssignee ? null : (assigneeName ?? this.assigneeName),
      assigneeAvatarUrl:
          clearAssignee ? null : (assigneeAvatarUrl ?? this.assigneeAvatarUrl),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        status,
        priority,
        assigneeId,
        createdBy,
        dueDate,
        createdAt,
        updatedAt,
        tags,
        assigneeName,
        assigneeAvatarUrl,
      ];
}
