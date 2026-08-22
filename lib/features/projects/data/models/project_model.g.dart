// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) => ProjectModel(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      taskCount: (json['task_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String,
      createdBy: json['created_by'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$ProjectModelToJson(ProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'name': instance.name,
      'description': instance.description,
      'status': instance.status,
      'task_count': instance.taskCount,
      'created_at': instance.createdAt,
      if (instance.createdBy case final value?) 'created_by': value,
      if (instance.updatedAt case final value?) 'updated_at': value,
    };
