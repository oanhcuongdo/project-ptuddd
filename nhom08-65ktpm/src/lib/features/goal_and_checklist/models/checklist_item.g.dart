// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) =>
    _ChecklistItem(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      phase:
          $enumDecodeNullable(_$ChecklistPhaseEnumMap, json['phase']) ??
          ChecklistPhase.before14d,
      scope:
          $enumDecodeNullable(_$ChecklistScopeEnumMap, json['scope']) ??
          ChecklistScope.group,
      ownerId: json['ownerId'] as String?,
      assigneeId: json['assigneeId'] as String?,
      assigneeName: json['assigneeName'] as String?,
      dueDate: const NullableTimestampConverter().fromJson(json['dueDate']),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: const NullableTimestampConverter().fromJson(
        json['completedAt'],
      ),
      completedBy: json['completedBy'] as String?,
      proofImageUrl: json['proofImageUrl'] as String?,
      proofStoragePath: json['proofStoragePath'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$ChecklistItemToJson(_ChecklistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'title': instance.title,
      'description': instance.description,
      'phase': _$ChecklistPhaseEnumMap[instance.phase]!,
      'scope': _$ChecklistScopeEnumMap[instance.scope]!,
      'ownerId': instance.ownerId,
      'assigneeId': instance.assigneeId,
      'assigneeName': instance.assigneeName,
      'dueDate': const NullableTimestampConverter().toJson(instance.dueDate),
      'isCompleted': instance.isCompleted,
      'completedAt': const NullableTimestampConverter().toJson(
        instance.completedAt,
      ),
      'completedBy': instance.completedBy,
      'proofImageUrl': instance.proofImageUrl,
      'proofStoragePath': instance.proofStoragePath,
      'sortOrder': instance.sortOrder,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$ChecklistPhaseEnumMap = {
  ChecklistPhase.before30d: 'before_30d',
  ChecklistPhase.before14d: 'before_14d',
  ChecklistPhase.before3d: 'before_3d',
  ChecklistPhase.packing: 'packing',
};

const _$ChecklistScopeEnumMap = {
  ChecklistScope.group: 'group',
  ChecklistScope.personal: 'personal',
};
