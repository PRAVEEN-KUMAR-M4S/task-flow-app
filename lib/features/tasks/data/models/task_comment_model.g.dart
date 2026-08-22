// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskCommentModel _$TaskCommentModelFromJson(Map<String, dynamic> json) =>
    TaskCommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$TaskCommentModelToJson(TaskCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'task_id': instance.taskId,
      'author_id': instance.authorId,
      'body': instance.body,
      'created_at': instance.createdAt,
    };
