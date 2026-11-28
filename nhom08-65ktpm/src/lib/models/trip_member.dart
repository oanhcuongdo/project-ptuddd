import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/utils/timestamp_converter.dart';

part 'trip_member.freezed.dart';
part 'trip_member.g.dart';

enum TripRole { host, member }

@freezed
abstract class TripMember with _$TripMember {
  const TripMember._();

  const factory TripMember({
    required String userId,
    required String displayName,
    String? avatarUrl,
    @Default(TripRole.member) TripRole role,
    @Default(0) int targetContribution,
    @Default(0) int contributedAmount,
    @Default(0) int personalAdvancedAmount,
    @Default(0) int currentStreak,
    @TimestampConverter() required DateTime joinedAt,
  }) = _TripMember;

  factory TripMember.fromJson(Map<String, dynamic> json) =>
      _$TripMemberFromJson(json);

  bool get isHost => role == TripRole.host;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TV';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
  }
}
