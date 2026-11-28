import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/utils/timestamp_converter.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required String email,
    required String displayName,
    String? avatarUrl,
    String? avatarStoragePath,
    String? phoneNumber,
    @Default(<String>[]) List<String> tripIds,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TB';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
  }
}
