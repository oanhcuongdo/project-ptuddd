// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripModel {

 String get id; String get title; String get destination; double? get destinationLat; double? get destinationLng; TripType get tripType; String? get coverImageUrl; String? get coverStoragePath;@TimestampConverter() DateTime get startDate;@TimestampConverter() DateTime get endDate; String get hostId; List<String> get memberIds; String get inviteCode; TripStatus get status; int get targetBudget; int get perMemberTarget; String get savingFrequency; int get checklistTotal; int get checklistCompleted; int get totalSavedAmount; int get totalPlannedItineraryCost; int get totalSpentAmount;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;
/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripModelCopyWith<TripModel> get copyWith => _$TripModelCopyWithImpl<TripModel>(this as TripModel, _$identity);

  /// Serializes this TripModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.tripType, tripType) || other.tripType == tripType)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.coverStoragePath, coverStoragePath) || other.coverStoragePath == coverStoragePath)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&const DeepCollectionEquality().equals(other.memberIds, memberIds)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.targetBudget, targetBudget) || other.targetBudget == targetBudget)&&(identical(other.perMemberTarget, perMemberTarget) || other.perMemberTarget == perMemberTarget)&&(identical(other.savingFrequency, savingFrequency) || other.savingFrequency == savingFrequency)&&(identical(other.checklistTotal, checklistTotal) || other.checklistTotal == checklistTotal)&&(identical(other.checklistCompleted, checklistCompleted) || other.checklistCompleted == checklistCompleted)&&(identical(other.totalSavedAmount, totalSavedAmount) || other.totalSavedAmount == totalSavedAmount)&&(identical(other.totalPlannedItineraryCost, totalPlannedItineraryCost) || other.totalPlannedItineraryCost == totalPlannedItineraryCost)&&(identical(other.totalSpentAmount, totalSpentAmount) || other.totalSpentAmount == totalSpentAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,destination,destinationLat,destinationLng,tripType,coverImageUrl,coverStoragePath,startDate,endDate,hostId,const DeepCollectionEquality().hash(memberIds),inviteCode,status,targetBudget,perMemberTarget,savingFrequency,checklistTotal,checklistCompleted,totalSavedAmount,totalPlannedItineraryCost,totalSpentAmount,createdAt,updatedAt]);

@override
String toString() {
  return 'TripModel(id: $id, title: $title, destination: $destination, destinationLat: $destinationLat, destinationLng: $destinationLng, tripType: $tripType, coverImageUrl: $coverImageUrl, coverStoragePath: $coverStoragePath, startDate: $startDate, endDate: $endDate, hostId: $hostId, memberIds: $memberIds, inviteCode: $inviteCode, status: $status, targetBudget: $targetBudget, perMemberTarget: $perMemberTarget, savingFrequency: $savingFrequency, checklistTotal: $checklistTotal, checklistCompleted: $checklistCompleted, totalSavedAmount: $totalSavedAmount, totalPlannedItineraryCost: $totalPlannedItineraryCost, totalSpentAmount: $totalSpentAmount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TripModelCopyWith<$Res>  {
  factory $TripModelCopyWith(TripModel value, $Res Function(TripModel) _then) = _$TripModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String destination, double? destinationLat, double? destinationLng, TripType tripType, String? coverImageUrl, String? coverStoragePath,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, String hostId, List<String> memberIds, String inviteCode, TripStatus status, int targetBudget, int perMemberTarget, String savingFrequency, int checklistTotal, int checklistCompleted, int totalSavedAmount, int totalPlannedItineraryCost, int totalSpentAmount,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$TripModelCopyWithImpl<$Res>
    implements $TripModelCopyWith<$Res> {
  _$TripModelCopyWithImpl(this._self, this._then);

  final TripModel _self;
  final $Res Function(TripModel) _then;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? destination = null,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? tripType = null,Object? coverImageUrl = freezed,Object? coverStoragePath = freezed,Object? startDate = null,Object? endDate = null,Object? hostId = null,Object? memberIds = null,Object? inviteCode = null,Object? status = null,Object? targetBudget = null,Object? perMemberTarget = null,Object? savingFrequency = null,Object? checklistTotal = null,Object? checklistCompleted = null,Object? totalSavedAmount = null,Object? totalPlannedItineraryCost = null,Object? totalSpentAmount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,tripType: null == tripType ? _self.tripType : tripType // ignore: cast_nullable_to_non_nullable
as TripType,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,coverStoragePath: freezed == coverStoragePath ? _self.coverStoragePath : coverStoragePath // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,targetBudget: null == targetBudget ? _self.targetBudget : targetBudget // ignore: cast_nullable_to_non_nullable
as int,perMemberTarget: null == perMemberTarget ? _self.perMemberTarget : perMemberTarget // ignore: cast_nullable_to_non_nullable
as int,savingFrequency: null == savingFrequency ? _self.savingFrequency : savingFrequency // ignore: cast_nullable_to_non_nullable
as String,checklistTotal: null == checklistTotal ? _self.checklistTotal : checklistTotal // ignore: cast_nullable_to_non_nullable
as int,checklistCompleted: null == checklistCompleted ? _self.checklistCompleted : checklistCompleted // ignore: cast_nullable_to_non_nullable
as int,totalSavedAmount: null == totalSavedAmount ? _self.totalSavedAmount : totalSavedAmount // ignore: cast_nullable_to_non_nullable
as int,totalPlannedItineraryCost: null == totalPlannedItineraryCost ? _self.totalPlannedItineraryCost : totalPlannedItineraryCost // ignore: cast_nullable_to_non_nullable
as int,totalSpentAmount: null == totalSpentAmount ? _self.totalSpentAmount : totalSpentAmount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripModel].
extension TripModelPatterns on TripModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripModel value)  $default,){
final _that = this;
switch (_that) {
case _TripModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripModel value)?  $default,){
final _that = this;
switch (_that) {
case _TripModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String destination,  double? destinationLat,  double? destinationLng,  TripType tripType,  String? coverImageUrl,  String? coverStoragePath, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  String hostId,  List<String> memberIds,  String inviteCode,  TripStatus status,  int targetBudget,  int perMemberTarget,  String savingFrequency,  int checklistTotal,  int checklistCompleted,  int totalSavedAmount,  int totalPlannedItineraryCost,  int totalSpentAmount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripModel() when $default != null:
return $default(_that.id,_that.title,_that.destination,_that.destinationLat,_that.destinationLng,_that.tripType,_that.coverImageUrl,_that.coverStoragePath,_that.startDate,_that.endDate,_that.hostId,_that.memberIds,_that.inviteCode,_that.status,_that.targetBudget,_that.perMemberTarget,_that.savingFrequency,_that.checklistTotal,_that.checklistCompleted,_that.totalSavedAmount,_that.totalPlannedItineraryCost,_that.totalSpentAmount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String destination,  double? destinationLat,  double? destinationLng,  TripType tripType,  String? coverImageUrl,  String? coverStoragePath, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  String hostId,  List<String> memberIds,  String inviteCode,  TripStatus status,  int targetBudget,  int perMemberTarget,  String savingFrequency,  int checklistTotal,  int checklistCompleted,  int totalSavedAmount,  int totalPlannedItineraryCost,  int totalSpentAmount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TripModel():
return $default(_that.id,_that.title,_that.destination,_that.destinationLat,_that.destinationLng,_that.tripType,_that.coverImageUrl,_that.coverStoragePath,_that.startDate,_that.endDate,_that.hostId,_that.memberIds,_that.inviteCode,_that.status,_that.targetBudget,_that.perMemberTarget,_that.savingFrequency,_that.checklistTotal,_that.checklistCompleted,_that.totalSavedAmount,_that.totalPlannedItineraryCost,_that.totalSpentAmount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String destination,  double? destinationLat,  double? destinationLng,  TripType tripType,  String? coverImageUrl,  String? coverStoragePath, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate,  String hostId,  List<String> memberIds,  String inviteCode,  TripStatus status,  int targetBudget,  int perMemberTarget,  String savingFrequency,  int checklistTotal,  int checklistCompleted,  int totalSavedAmount,  int totalPlannedItineraryCost,  int totalSpentAmount, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripModel() when $default != null:
return $default(_that.id,_that.title,_that.destination,_that.destinationLat,_that.destinationLng,_that.tripType,_that.coverImageUrl,_that.coverStoragePath,_that.startDate,_that.endDate,_that.hostId,_that.memberIds,_that.inviteCode,_that.status,_that.targetBudget,_that.perMemberTarget,_that.savingFrequency,_that.checklistTotal,_that.checklistCompleted,_that.totalSavedAmount,_that.totalPlannedItineraryCost,_that.totalSpentAmount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripModel extends TripModel {
  const _TripModel({required this.id, required this.title, required this.destination, this.destinationLat, this.destinationLng, this.tripType = TripType.other, this.coverImageUrl, this.coverStoragePath, @TimestampConverter() required this.startDate, @TimestampConverter() required this.endDate, required this.hostId, final  List<String> memberIds = const <String>[], required this.inviteCode, this.status = TripStatus.planning, this.targetBudget = 0, this.perMemberTarget = 0, this.savingFrequency = 'weekly', this.checklistTotal = 0, this.checklistCompleted = 0, this.totalSavedAmount = 0, this.totalPlannedItineraryCost = 0, this.totalSpentAmount = 0, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt}): _memberIds = memberIds,super._();
  factory _TripModel.fromJson(Map<String, dynamic> json) => _$TripModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String destination;
@override final  double? destinationLat;
@override final  double? destinationLng;
@override@JsonKey() final  TripType tripType;
@override final  String? coverImageUrl;
@override final  String? coverStoragePath;
@override@TimestampConverter() final  DateTime startDate;
@override@TimestampConverter() final  DateTime endDate;
@override final  String hostId;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override final  String inviteCode;
@override@JsonKey() final  TripStatus status;
@override@JsonKey() final  int targetBudget;
@override@JsonKey() final  int perMemberTarget;
@override@JsonKey() final  String savingFrequency;
@override@JsonKey() final  int checklistTotal;
@override@JsonKey() final  int checklistCompleted;
@override@JsonKey() final  int totalSavedAmount;
@override@JsonKey() final  int totalPlannedItineraryCost;
@override@JsonKey() final  int totalSpentAmount;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripModelCopyWith<_TripModel> get copyWith => __$TripModelCopyWithImpl<_TripModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.destinationLat, destinationLat) || other.destinationLat == destinationLat)&&(identical(other.destinationLng, destinationLng) || other.destinationLng == destinationLng)&&(identical(other.tripType, tripType) || other.tripType == tripType)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.coverStoragePath, coverStoragePath) || other.coverStoragePath == coverStoragePath)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.targetBudget, targetBudget) || other.targetBudget == targetBudget)&&(identical(other.perMemberTarget, perMemberTarget) || other.perMemberTarget == perMemberTarget)&&(identical(other.savingFrequency, savingFrequency) || other.savingFrequency == savingFrequency)&&(identical(other.checklistTotal, checklistTotal) || other.checklistTotal == checklistTotal)&&(identical(other.checklistCompleted, checklistCompleted) || other.checklistCompleted == checklistCompleted)&&(identical(other.totalSavedAmount, totalSavedAmount) || other.totalSavedAmount == totalSavedAmount)&&(identical(other.totalPlannedItineraryCost, totalPlannedItineraryCost) || other.totalPlannedItineraryCost == totalPlannedItineraryCost)&&(identical(other.totalSpentAmount, totalSpentAmount) || other.totalSpentAmount == totalSpentAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,destination,destinationLat,destinationLng,tripType,coverImageUrl,coverStoragePath,startDate,endDate,hostId,const DeepCollectionEquality().hash(_memberIds),inviteCode,status,targetBudget,perMemberTarget,savingFrequency,checklistTotal,checklistCompleted,totalSavedAmount,totalPlannedItineraryCost,totalSpentAmount,createdAt,updatedAt]);

@override
String toString() {
  return 'TripModel(id: $id, title: $title, destination: $destination, destinationLat: $destinationLat, destinationLng: $destinationLng, tripType: $tripType, coverImageUrl: $coverImageUrl, coverStoragePath: $coverStoragePath, startDate: $startDate, endDate: $endDate, hostId: $hostId, memberIds: $memberIds, inviteCode: $inviteCode, status: $status, targetBudget: $targetBudget, perMemberTarget: $perMemberTarget, savingFrequency: $savingFrequency, checklistTotal: $checklistTotal, checklistCompleted: $checklistCompleted, totalSavedAmount: $totalSavedAmount, totalPlannedItineraryCost: $totalPlannedItineraryCost, totalSpentAmount: $totalSpentAmount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripModelCopyWith<$Res> implements $TripModelCopyWith<$Res> {
  factory _$TripModelCopyWith(_TripModel value, $Res Function(_TripModel) _then) = __$TripModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String destination, double? destinationLat, double? destinationLng, TripType tripType, String? coverImageUrl, String? coverStoragePath,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate, String hostId, List<String> memberIds, String inviteCode, TripStatus status, int targetBudget, int perMemberTarget, String savingFrequency, int checklistTotal, int checklistCompleted, int totalSavedAmount, int totalPlannedItineraryCost, int totalSpentAmount,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$TripModelCopyWithImpl<$Res>
    implements _$TripModelCopyWith<$Res> {
  __$TripModelCopyWithImpl(this._self, this._then);

  final _TripModel _self;
  final $Res Function(_TripModel) _then;

/// Create a copy of TripModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? destination = null,Object? destinationLat = freezed,Object? destinationLng = freezed,Object? tripType = null,Object? coverImageUrl = freezed,Object? coverStoragePath = freezed,Object? startDate = null,Object? endDate = null,Object? hostId = null,Object? memberIds = null,Object? inviteCode = null,Object? status = null,Object? targetBudget = null,Object? perMemberTarget = null,Object? savingFrequency = null,Object? checklistTotal = null,Object? checklistCompleted = null,Object? totalSavedAmount = null,Object? totalPlannedItineraryCost = null,Object? totalSpentAmount = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TripModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,destinationLat: freezed == destinationLat ? _self.destinationLat : destinationLat // ignore: cast_nullable_to_non_nullable
as double?,destinationLng: freezed == destinationLng ? _self.destinationLng : destinationLng // ignore: cast_nullable_to_non_nullable
as double?,tripType: null == tripType ? _self.tripType : tripType // ignore: cast_nullable_to_non_nullable
as TripType,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,coverStoragePath: freezed == coverStoragePath ? _self.coverStoragePath : coverStoragePath // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,targetBudget: null == targetBudget ? _self.targetBudget : targetBudget // ignore: cast_nullable_to_non_nullable
as int,perMemberTarget: null == perMemberTarget ? _self.perMemberTarget : perMemberTarget // ignore: cast_nullable_to_non_nullable
as int,savingFrequency: null == savingFrequency ? _self.savingFrequency : savingFrequency // ignore: cast_nullable_to_non_nullable
as String,checklistTotal: null == checklistTotal ? _self.checklistTotal : checklistTotal // ignore: cast_nullable_to_non_nullable
as int,checklistCompleted: null == checklistCompleted ? _self.checklistCompleted : checklistCompleted // ignore: cast_nullable_to_non_nullable
as int,totalSavedAmount: null == totalSavedAmount ? _self.totalSavedAmount : totalSavedAmount // ignore: cast_nullable_to_non_nullable
as int,totalPlannedItineraryCost: null == totalPlannedItineraryCost ? _self.totalPlannedItineraryCost : totalPlannedItineraryCost // ignore: cast_nullable_to_non_nullable
as int,totalSpentAmount: null == totalSpentAmount ? _self.totalSpentAmount : totalSpentAmount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
