// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistItem {

 String get id; String get tripId; String get title; String? get description; ChecklistPhase get phase; ChecklistScope get scope; String? get ownerId; String? get assigneeId; String? get assigneeName;@NullableTimestampConverter() DateTime? get dueDate; bool get isCompleted;@NullableTimestampConverter() DateTime? get completedAt; String? get completedBy; String? get proofImageUrl; String? get proofStoragePath; int get sortOrder; String get createdBy;@TimestampConverter() DateTime get createdAt;
/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistItemCopyWith<ChecklistItem> get copyWith => _$ChecklistItemCopyWithImpl<ChecklistItem>(this as ChecklistItem, _$identity);

  /// Serializes this ChecklistItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.assigneeName, assigneeName) || other.assigneeName == assigneeName)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.proofImageUrl, proofImageUrl) || other.proofImageUrl == proofImageUrl)&&(identical(other.proofStoragePath, proofStoragePath) || other.proofStoragePath == proofStoragePath)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,phase,scope,ownerId,assigneeId,assigneeName,dueDate,isCompleted,completedAt,completedBy,proofImageUrl,proofStoragePath,sortOrder,createdBy,createdAt);

@override
String toString() {
  return 'ChecklistItem(id: $id, tripId: $tripId, title: $title, description: $description, phase: $phase, scope: $scope, ownerId: $ownerId, assigneeId: $assigneeId, assigneeName: $assigneeName, dueDate: $dueDate, isCompleted: $isCompleted, completedAt: $completedAt, completedBy: $completedBy, proofImageUrl: $proofImageUrl, proofStoragePath: $proofStoragePath, sortOrder: $sortOrder, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChecklistItemCopyWith<$Res>  {
  factory $ChecklistItemCopyWith(ChecklistItem value, $Res Function(ChecklistItem) _then) = _$ChecklistItemCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String title, String? description, ChecklistPhase phase, ChecklistScope scope, String? ownerId, String? assigneeId, String? assigneeName,@NullableTimestampConverter() DateTime? dueDate, bool isCompleted,@NullableTimestampConverter() DateTime? completedAt, String? completedBy, String? proofImageUrl, String? proofStoragePath, int sortOrder, String createdBy,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$ChecklistItemCopyWithImpl<$Res>
    implements $ChecklistItemCopyWith<$Res> {
  _$ChecklistItemCopyWithImpl(this._self, this._then);

  final ChecklistItem _self;
  final $Res Function(ChecklistItem) _then;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = freezed,Object? phase = null,Object? scope = null,Object? ownerId = freezed,Object? assigneeId = freezed,Object? assigneeName = freezed,Object? dueDate = freezed,Object? isCompleted = null,Object? completedAt = freezed,Object? completedBy = freezed,Object? proofImageUrl = freezed,Object? proofStoragePath = freezed,Object? sortOrder = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChecklistPhase,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ChecklistScope,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,assigneeName: freezed == assigneeName ? _self.assigneeName : assigneeName // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedBy: freezed == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String?,proofImageUrl: freezed == proofImageUrl ? _self.proofImageUrl : proofImageUrl // ignore: cast_nullable_to_non_nullable
as String?,proofStoragePath: freezed == proofStoragePath ? _self.proofStoragePath : proofStoragePath // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistItem].
extension ChecklistItemPatterns on ChecklistItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistItem value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistItem value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String title,  String? description,  ChecklistPhase phase,  ChecklistScope scope,  String? ownerId,  String? assigneeId,  String? assigneeName, @NullableTimestampConverter()  DateTime? dueDate,  bool isCompleted, @NullableTimestampConverter()  DateTime? completedAt,  String? completedBy,  String? proofImageUrl,  String? proofStoragePath,  int sortOrder,  String createdBy, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.phase,_that.scope,_that.ownerId,_that.assigneeId,_that.assigneeName,_that.dueDate,_that.isCompleted,_that.completedAt,_that.completedBy,_that.proofImageUrl,_that.proofStoragePath,_that.sortOrder,_that.createdBy,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String title,  String? description,  ChecklistPhase phase,  ChecklistScope scope,  String? ownerId,  String? assigneeId,  String? assigneeName, @NullableTimestampConverter()  DateTime? dueDate,  bool isCompleted, @NullableTimestampConverter()  DateTime? completedAt,  String? completedBy,  String? proofImageUrl,  String? proofStoragePath,  int sortOrder,  String createdBy, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ChecklistItem():
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.phase,_that.scope,_that.ownerId,_that.assigneeId,_that.assigneeName,_that.dueDate,_that.isCompleted,_that.completedAt,_that.completedBy,_that.proofImageUrl,_that.proofStoragePath,_that.sortOrder,_that.createdBy,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String title,  String? description,  ChecklistPhase phase,  ChecklistScope scope,  String? ownerId,  String? assigneeId,  String? assigneeName, @NullableTimestampConverter()  DateTime? dueDate,  bool isCompleted, @NullableTimestampConverter()  DateTime? completedAt,  String? completedBy,  String? proofImageUrl,  String? proofStoragePath,  int sortOrder,  String createdBy, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistItem() when $default != null:
return $default(_that.id,_that.tripId,_that.title,_that.description,_that.phase,_that.scope,_that.ownerId,_that.assigneeId,_that.assigneeName,_that.dueDate,_that.isCompleted,_that.completedAt,_that.completedBy,_that.proofImageUrl,_that.proofStoragePath,_that.sortOrder,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistItem extends ChecklistItem {
  const _ChecklistItem({required this.id, required this.tripId, required this.title, this.description, this.phase = ChecklistPhase.before14d, this.scope = ChecklistScope.group, this.ownerId, this.assigneeId, this.assigneeName, @NullableTimestampConverter() this.dueDate, this.isCompleted = false, @NullableTimestampConverter() this.completedAt, this.completedBy, this.proofImageUrl, this.proofStoragePath, this.sortOrder = 0, required this.createdBy, @TimestampConverter() required this.createdAt}): super._();
  factory _ChecklistItem.fromJson(Map<String, dynamic> json) => _$ChecklistItemFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String title;
@override final  String? description;
@override@JsonKey() final  ChecklistPhase phase;
@override@JsonKey() final  ChecklistScope scope;
@override final  String? ownerId;
@override final  String? assigneeId;
@override final  String? assigneeName;
@override@NullableTimestampConverter() final  DateTime? dueDate;
@override@JsonKey() final  bool isCompleted;
@override@NullableTimestampConverter() final  DateTime? completedAt;
@override final  String? completedBy;
@override final  String? proofImageUrl;
@override final  String? proofStoragePath;
@override@JsonKey() final  int sortOrder;
@override final  String createdBy;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistItemCopyWith<_ChecklistItem> get copyWith => __$ChecklistItemCopyWithImpl<_ChecklistItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.assigneeName, assigneeName) || other.assigneeName == assigneeName)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.proofImageUrl, proofImageUrl) || other.proofImageUrl == proofImageUrl)&&(identical(other.proofStoragePath, proofStoragePath) || other.proofStoragePath == proofStoragePath)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,title,description,phase,scope,ownerId,assigneeId,assigneeName,dueDate,isCompleted,completedAt,completedBy,proofImageUrl,proofStoragePath,sortOrder,createdBy,createdAt);

@override
String toString() {
  return 'ChecklistItem(id: $id, tripId: $tripId, title: $title, description: $description, phase: $phase, scope: $scope, ownerId: $ownerId, assigneeId: $assigneeId, assigneeName: $assigneeName, dueDate: $dueDate, isCompleted: $isCompleted, completedAt: $completedAt, completedBy: $completedBy, proofImageUrl: $proofImageUrl, proofStoragePath: $proofStoragePath, sortOrder: $sortOrder, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ChecklistItemCopyWith<$Res> implements $ChecklistItemCopyWith<$Res> {
  factory _$ChecklistItemCopyWith(_ChecklistItem value, $Res Function(_ChecklistItem) _then) = __$ChecklistItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String title, String? description, ChecklistPhase phase, ChecklistScope scope, String? ownerId, String? assigneeId, String? assigneeName,@NullableTimestampConverter() DateTime? dueDate, bool isCompleted,@NullableTimestampConverter() DateTime? completedAt, String? completedBy, String? proofImageUrl, String? proofStoragePath, int sortOrder, String createdBy,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$ChecklistItemCopyWithImpl<$Res>
    implements _$ChecklistItemCopyWith<$Res> {
  __$ChecklistItemCopyWithImpl(this._self, this._then);

  final _ChecklistItem _self;
  final $Res Function(_ChecklistItem) _then;

/// Create a copy of ChecklistItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? title = null,Object? description = freezed,Object? phase = null,Object? scope = null,Object? ownerId = freezed,Object? assigneeId = freezed,Object? assigneeName = freezed,Object? dueDate = freezed,Object? isCompleted = null,Object? completedAt = freezed,Object? completedBy = freezed,Object? proofImageUrl = freezed,Object? proofStoragePath = freezed,Object? sortOrder = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_ChecklistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChecklistPhase,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as ChecklistScope,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,assigneeName: freezed == assigneeName ? _self.assigneeName : assigneeName // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedBy: freezed == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String?,proofImageUrl: freezed == proofImageUrl ? _self.proofImageUrl : proofImageUrl // ignore: cast_nullable_to_non_nullable
as String?,proofStoragePath: freezed == proofStoragePath ? _self.proofStoragePath : proofStoragePath // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
