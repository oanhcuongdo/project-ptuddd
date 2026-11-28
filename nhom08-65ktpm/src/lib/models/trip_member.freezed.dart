// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripMember {

 String get userId; String get displayName; String? get avatarUrl; TripRole get role; int get targetContribution; int get contributedAmount; int get personalAdvancedAmount; int get currentStreak;@TimestampConverter() DateTime get joinedAt;
/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripMemberCopyWith<TripMember> get copyWith => _$TripMemberCopyWithImpl<TripMember>(this as TripMember, _$identity);

  /// Serializes this TripMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.targetContribution, targetContribution) || other.targetContribution == targetContribution)&&(identical(other.contributedAmount, contributedAmount) || other.contributedAmount == contributedAmount)&&(identical(other.personalAdvancedAmount, personalAdvancedAmount) || other.personalAdvancedAmount == personalAdvancedAmount)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarUrl,role,targetContribution,contributedAmount,personalAdvancedAmount,currentStreak,joinedAt);

@override
String toString() {
  return 'TripMember(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, role: $role, targetContribution: $targetContribution, contributedAmount: $contributedAmount, personalAdvancedAmount: $personalAdvancedAmount, currentStreak: $currentStreak, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $TripMemberCopyWith<$Res>  {
  factory $TripMemberCopyWith(TripMember value, $Res Function(TripMember) _then) = _$TripMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String? avatarUrl, TripRole role, int targetContribution, int contributedAmount, int personalAdvancedAmount, int currentStreak,@TimestampConverter() DateTime joinedAt
});




}
/// @nodoc
class _$TripMemberCopyWithImpl<$Res>
    implements $TripMemberCopyWith<$Res> {
  _$TripMemberCopyWithImpl(this._self, this._then);

  final TripMember _self;
  final $Res Function(TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? avatarUrl = freezed,Object? role = null,Object? targetContribution = null,Object? contributedAmount = null,Object? personalAdvancedAmount = null,Object? currentStreak = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TripRole,targetContribution: null == targetContribution ? _self.targetContribution : targetContribution // ignore: cast_nullable_to_non_nullable
as int,contributedAmount: null == contributedAmount ? _self.contributedAmount : contributedAmount // ignore: cast_nullable_to_non_nullable
as int,personalAdvancedAmount: null == personalAdvancedAmount ? _self.personalAdvancedAmount : personalAdvancedAmount // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripMember].
extension TripMemberPatterns on TripMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripMember value)  $default,){
final _that = this;
switch (_that) {
case _TripMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripMember value)?  $default,){
final _that = this;
switch (_that) {
case _TripMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String? avatarUrl,  TripRole role,  int targetContribution,  int contributedAmount,  int personalAdvancedAmount,  int currentStreak, @TimestampConverter()  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.role,_that.targetContribution,_that.contributedAmount,_that.personalAdvancedAmount,_that.currentStreak,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String? avatarUrl,  TripRole role,  int targetContribution,  int contributedAmount,  int personalAdvancedAmount,  int currentStreak, @TimestampConverter()  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _TripMember():
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.role,_that.targetContribution,_that.contributedAmount,_that.personalAdvancedAmount,_that.currentStreak,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String? avatarUrl,  TripRole role,  int targetContribution,  int contributedAmount,  int personalAdvancedAmount,  int currentStreak, @TimestampConverter()  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarUrl,_that.role,_that.targetContribution,_that.contributedAmount,_that.personalAdvancedAmount,_that.currentStreak,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripMember extends TripMember {
  const _TripMember({required this.userId, required this.displayName, this.avatarUrl, this.role = TripRole.member, this.targetContribution = 0, this.contributedAmount = 0, this.personalAdvancedAmount = 0, this.currentStreak = 0, @TimestampConverter() required this.joinedAt}): super._();
  factory _TripMember.fromJson(Map<String, dynamic> json) => _$TripMemberFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  TripRole role;
@override@JsonKey() final  int targetContribution;
@override@JsonKey() final  int contributedAmount;
@override@JsonKey() final  int personalAdvancedAmount;
@override@JsonKey() final  int currentStreak;
@override@TimestampConverter() final  DateTime joinedAt;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripMemberCopyWith<_TripMember> get copyWith => __$TripMemberCopyWithImpl<_TripMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.targetContribution, targetContribution) || other.targetContribution == targetContribution)&&(identical(other.contributedAmount, contributedAmount) || other.contributedAmount == contributedAmount)&&(identical(other.personalAdvancedAmount, personalAdvancedAmount) || other.personalAdvancedAmount == personalAdvancedAmount)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarUrl,role,targetContribution,contributedAmount,personalAdvancedAmount,currentStreak,joinedAt);

@override
String toString() {
  return 'TripMember(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, role: $role, targetContribution: $targetContribution, contributedAmount: $contributedAmount, personalAdvancedAmount: $personalAdvancedAmount, currentStreak: $currentStreak, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$TripMemberCopyWith<$Res> implements $TripMemberCopyWith<$Res> {
  factory _$TripMemberCopyWith(_TripMember value, $Res Function(_TripMember) _then) = __$TripMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String? avatarUrl, TripRole role, int targetContribution, int contributedAmount, int personalAdvancedAmount, int currentStreak,@TimestampConverter() DateTime joinedAt
});




}
/// @nodoc
class __$TripMemberCopyWithImpl<$Res>
    implements _$TripMemberCopyWith<$Res> {
  __$TripMemberCopyWithImpl(this._self, this._then);

  final _TripMember _self;
  final $Res Function(_TripMember) _then;

/// Create a copy of TripMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? avatarUrl = freezed,Object? role = null,Object? targetContribution = null,Object? contributedAmount = null,Object? personalAdvancedAmount = null,Object? currentStreak = null,Object? joinedAt = null,}) {
  return _then(_TripMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as TripRole,targetContribution: null == targetContribution ? _self.targetContribution : targetContribution // ignore: cast_nullable_to_non_nullable
as int,contributedAmount: null == contributedAmount ? _self.contributedAmount : contributedAmount // ignore: cast_nullable_to_non_nullable
as int,personalAdvancedAmount: null == personalAdvancedAmount ? _self.personalAdvancedAmount : personalAdvancedAmount // ignore: cast_nullable_to_non_nullable
as int,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
