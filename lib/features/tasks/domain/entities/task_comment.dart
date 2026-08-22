import 'package:equatable/equatable.dart';

/// A comment on a task, with the author's profile joined in from `users`.
class TaskComment extends Equatable {
  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  // Joined from the `users` table by the data layer.
  final String authorName;
  final String? authorAvatarUrl;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.authorName = 'Unknown user',
    this.authorAvatarUrl,
  });

  String get authorInitials {
    final parts = authorName.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  List<Object?> get props =>
      [id, taskId, authorId, body, createdAt, authorName, authorAvatarUrl];
}
