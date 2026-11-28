import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/utils/timestamp_converter.dart';

part 'invite_code.freezed.dart';
part 'invite_code.g.dart';

@freezed
abstract class InviteCode with _$InviteCode {
  const factory InviteCode({
    required String code,
    required String tripId,
    required String tripTitle,
    required String createdBy,
    @Default(true) bool isActive,
    @NullableTimestampConverter() DateTime? expiresAt,
    @TimestampConverter() required DateTime createdAt,
  }) = _InviteCode;

  factory InviteCode.fromJson(Map<String, dynamic> json) =>
      _$InviteCodeFromJson(json);
}
