// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  avatarStoragePath: json['avatarStoragePath'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  tripIds:
      (json['tripIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'avatarStoragePath': instance.avatarStoragePath,
  'phoneNumber': instance.phoneNumber,
  'tripIds': instance.tripIds,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
};
