import 'package:json_annotation/json_annotation.dart';
import 'package:task_flow/features/tasks/domain/entities/task_comment.dart';

part 'task_comment_model.g.dart';

/// Mirrors a row of the `comments` table in the mock data:
/// `{ id, task_id, author_id, body, created_at }`.
///
/// The author key is `author_id`, not `user_id`.
@JsonSerializable()
class TaskCommentModel {
  final String id;
  @JsonKey(name: 'task_id')
  final String taskId;
  @JsonKey(name: 'author_id')
  final String authorId;
  @JsonKey(defaultValue: '')
  final String body;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) =>
      _$TaskCommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCommentModelToJson(this);

  TaskComment toEntity({String? authorName, String? authorAvatarUrl}) {
    return TaskComment(
      id: id,
      taskId: taskId,
      authorId: authorId,
      body: body,
      createdAt: DateTime.parse(createdAt),
      authorName: authorName ?? 'Unknown user',
      authorAvatarUrl: authorAvatarUrl,
    );
  }
}
