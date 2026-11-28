// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripModel _$TripModelFromJson(Map<String, dynamic> json) => _TripModel(
  id: json['id'] as String,
  title: json['title'] as String,
  destination: json['destination'] as String,
  destinationLat: (json['destinationLat'] as num?)?.toDouble(),
  destinationLng: (json['destinationLng'] as num?)?.toDouble(),
  tripType:
      $enumDecodeNullable(_$TripTypeEnumMap, json['tripType']) ??
      TripType.other,
  coverImageUrl: json['coverImageUrl'] as String?,
  coverStoragePath: json['coverStoragePath'] as String?,
  startDate: const TimestampConverter().fromJson(json['startDate']),
  endDate: const TimestampConverter().fromJson(json['endDate']),
  hostId: json['hostId'] as String,
  memberIds:
      (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  inviteCode: json['inviteCode'] as String,
  status:
      $enumDecodeNullable(_$TripStatusEnumMap, json['status']) ??
      TripStatus.planning,
  targetBudget: (json['targetBudget'] as num?)?.toInt() ?? 0,
  perMemberTarget: (json['perMemberTarget'] as num?)?.toInt() ?? 0,
  savingFrequency: json['savingFrequency'] as String? ?? 'weekly',
  checklistTotal: (json['checklistTotal'] as num?)?.toInt() ?? 0,
  checklistCompleted: (json['checklistCompleted'] as num?)?.toInt() ?? 0,
  totalSavedAmount: (json['totalSavedAmount'] as num?)?.toInt() ?? 0,
  totalPlannedItineraryCost:
      (json['totalPlannedItineraryCost'] as num?)?.toInt() ?? 0,
  totalSpentAmount: (json['totalSpentAmount'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$TripModelToJson(_TripModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'destination': instance.destination,
      'destinationLat': instance.destinationLat,
      'destinationLng': instance.destinationLng,
      'tripType': _$TripTypeEnumMap[instance.tripType]!,
      'coverImageUrl': instance.coverImageUrl,
      'coverStoragePath': instance.coverStoragePath,
      'startDate': const TimestampConverter().toJson(instance.startDate),
      'endDate': const TimestampConverter().toJson(instance.endDate),
      'hostId': instance.hostId,
      'memberIds': instance.memberIds,
      'inviteCode': instance.inviteCode,
      'status': _$TripStatusEnumMap[instance.status]!,
      'targetBudget': instance.targetBudget,
      'perMemberTarget': instance.perMemberTarget,
      'savingFrequency': instance.savingFrequency,
      'checklistTotal': instance.checklistTotal,
      'checklistCompleted': instance.checklistCompleted,
      'totalSavedAmount': instance.totalSavedAmount,
      'totalPlannedItineraryCost': instance.totalPlannedItineraryCost,
      'totalSpentAmount': instance.totalSpentAmount,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$TripTypeEnumMap = {
  TripType.beach: 'beach',
  TripType.trekking: 'trekking',
  TripType.motorbike: 'motorbike',
  TripType.backpacking: 'backpacking',
  TripType.other: 'other',
};

const _$TripStatusEnumMap = {
  TripStatus.planning: 'planning',
  TripStatus.ongoing: 'ongoing',
  TripStatus.completed: 'completed',
  TripStatus.cancelled: 'cancelled',
};
