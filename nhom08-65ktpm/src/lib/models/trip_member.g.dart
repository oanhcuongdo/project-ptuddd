// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripMember _$TripMemberFromJson(Map<String, dynamic> json) => _TripMember(
  userId: json['userId'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  role: $enumDecodeNullable(_$TripRoleEnumMap, json['role']) ?? TripRole.member,
  targetContribution: (json['targetContribution'] as num?)?.toInt() ?? 0,
  contributedAmount: (json['contributedAmount'] as num?)?.toInt() ?? 0,
  personalAdvancedAmount:
      (json['personalAdvancedAmount'] as num?)?.toInt() ?? 0,
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  joinedAt: const TimestampConverter().fromJson(json['joinedAt']),
);

Map<String, dynamic> _$TripMemberToJson(_TripMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'role': _$TripRoleEnumMap[instance.role]!,
      'targetContribution': instance.targetContribution,
      'contributedAmount': instance.contributedAmount,
      'personalAdvancedAmount': instance.personalAdvancedAmount,
      'currentStreak': instance.currentStreak,
      'joinedAt': const TimestampConverter().toJson(instance.joinedAt),
    };

const _$TripRoleEnumMap = {TripRole.host: 'host', TripRole.member: 'member'};
