// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InviteCode {

 String get code; String get tripId; String get tripTitle; String get createdBy; bool get isActive;@NullableTimestampConverter() DateTime? get expiresAt;@TimestampConverter() DateTime get createdAt;
/// Create a copy of InviteCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCodeCopyWith<InviteCode> get copyWith => _$InviteCodeCopyWithImpl<InviteCode>(this as InviteCode, _$identity);

  /// Serializes this InviteCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteCode&&(identical(other.code, code) || other.code == code)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripTitle, tripTitle) || other.tripTitle == tripTitle)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,tripId,tripTitle,createdBy,isActive,expiresAt,createdAt);

@override
String toString() {
  return 'InviteCode(code: $code, tripId: $tripId, tripTitle: $tripTitle, createdBy: $createdBy, isActive: $isActive, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InviteCodeCopyWith<$Res>  {
  factory $InviteCodeCopyWith(InviteCode value, $Res Function(InviteCode) _then) = _$InviteCodeCopyWithImpl;
@useResult
$Res call({
 String code, String tripId, String tripTitle, String createdBy, bool isActive,@NullableTimestampConverter() DateTime? expiresAt,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$InviteCodeCopyWithImpl<$Res>
    implements $InviteCodeCopyWith<$Res> {
  _$InviteCodeCopyWithImpl(this._self, this._then);

  final InviteCode _self;
  final $Res Function(InviteCode) _then;

/// Create a copy of InviteCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? tripId = null,Object? tripTitle = null,Object? createdBy = null,Object? isActive = null,Object? expiresAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,tripTitle: null == tripTitle ? _self.tripTitle : tripTitle // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteCode].
extension InviteCodePatterns on InviteCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteCode value)  $default,){
final _that = this;
switch (_that) {
case _InviteCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteCode value)?  $default,){
final _that = this;
switch (_that) {
case _InviteCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String tripId,  String tripTitle,  String createdBy,  bool isActive, @NullableTimestampConverter()  DateTime? expiresAt, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteCode() when $default != null:
return $default(_that.code,_that.tripId,_that.tripTitle,_that.createdBy,_that.isActive,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String tripId,  String tripTitle,  String createdBy,  bool isActive, @NullableTimestampConverter()  DateTime? expiresAt, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InviteCode():
return $default(_that.code,_that.tripId,_that.tripTitle,_that.createdBy,_that.isActive,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String tripId,  String tripTitle,  String createdBy,  bool isActive, @NullableTimestampConverter()  DateTime? expiresAt, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InviteCode() when $default != null:
return $default(_that.code,_that.tripId,_that.tripTitle,_that.createdBy,_that.isActive,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteCode implements InviteCode {
  const _InviteCode({required this.code, required this.tripId, required this.tripTitle, required this.createdBy, this.isActive = true, @NullableTimestampConverter() this.expiresAt, @TimestampConverter() required this.createdAt});
  factory _InviteCode.fromJson(Map<String, dynamic> json) => _$InviteCodeFromJson(json);

@override final  String code;
@override final  String tripId;
@override final  String tripTitle;
@override final  String createdBy;
@override@JsonKey() final  bool isActive;
@override@NullableTimestampConverter() final  DateTime? expiresAt;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of InviteCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCodeCopyWith<_InviteCode> get copyWith => __$InviteCodeCopyWithImpl<_InviteCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteCode&&(identical(other.code, code) || other.code == code)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripTitle, tripTitle) || other.tripTitle == tripTitle)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,tripId,tripTitle,createdBy,isActive,expiresAt,createdAt);

@override
String toString() {
  return 'InviteCode(code: $code, tripId: $tripId, tripTitle: $tripTitle, createdBy: $createdBy, isActive: $isActive, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InviteCodeCopyWith<$Res> implements $InviteCodeCopyWith<$Res> {
  factory _$InviteCodeCopyWith(_InviteCode value, $Res Function(_InviteCode) _then) = __$InviteCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, String tripId, String tripTitle, String createdBy, bool isActive,@NullableTimestampConverter() DateTime? expiresAt,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$InviteCodeCopyWithImpl<$Res>
    implements _$InviteCodeCopyWith<$Res> {
  __$InviteCodeCopyWithImpl(this._self, this._then);

  final _InviteCode _self;
  final $Res Function(_InviteCode) _then;

/// Create a copy of InviteCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? tripId = null,Object? tripTitle = null,Object? createdBy = null,Object? isActive = null,Object? expiresAt = freezed,Object? createdAt = null,}) {
  return _then(_InviteCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,tripTitle: null == tripTitle ? _self.tripTitle : tripTitle // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
