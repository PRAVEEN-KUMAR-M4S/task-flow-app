// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrgMemberModel _$OrgMemberModelFromJson(Map<String, dynamic> json) =>
    OrgMemberModel(
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
    );

Map<String, dynamic> _$OrgMemberModelToJson(OrgMemberModel instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'role': instance.role,
    };
