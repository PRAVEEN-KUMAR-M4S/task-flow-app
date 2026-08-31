// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: json['id'] as String,
  projectId: json['project_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  status: json['status'] as String,
  priority: json['priority'] as String,
  assigneeId: json['assignee_id'] as String?,
  createdBy: json['created_by'] as String?,
  dueDate: json['due_date'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  isFavorite: json['is_favorite'] as bool? ?? false,
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'id': instance.id,
  'project_id': instance.projectId,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'priority': instance.priority,
  'assignee_id': instance.assigneeId,
  if (instance.createdBy case final value?) 'created_by': value,
  'due_date': instance.dueDate,
  'created_at': instance.createdAt,
  if (instance.updatedAt case final value?) 'updated_at': value,
  'tags': instance.tags,
  'is_favorite': instance.isFavorite,
};
