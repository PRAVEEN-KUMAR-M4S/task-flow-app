// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_credential_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestCredentialModel _$TestCredentialModelFromJson(Map<String, dynamic> json) =>
    TestCredentialModel(
      email: json['email'] as String,
      password: json['password'] as String,
      orgId: json['org_id'] as String,
      role: json['role'] as String? ?? 'member',
    );

Map<String, dynamic> _$TestCredentialModelToJson(
  TestCredentialModel instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'org_id': instance.orgId,
  'role': instance.role,
};
