// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InviteCode _$InviteCodeFromJson(Map<String, dynamic> json) => _InviteCode(
  code: json['code'] as String,
  tripId: json['tripId'] as String,
  tripTitle: json['tripTitle'] as String,
  createdBy: json['createdBy'] as String,
  isActive: json['isActive'] as bool? ?? true,
  expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$InviteCodeToJson(
  _InviteCode instance,
) => <String, dynamic>{
  'code': instance.code,
  'tripId': instance.tripId,
  'tripTitle': instance.tripTitle,
  'createdBy': instance.createdBy,
  'isActive': instance.isActive,
  'expiresAt': const NullableTimestampConverter().toJson(instance.expiresAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};
