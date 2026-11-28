import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Shared JSON converter between Firestore [Timestamp] (or ISO-8601 / epoch ms)
/// and non-nullable [DateTime] for Freezed models.
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return DateTime.now();
  }

  @override
  Object toJson(DateTime date) => Timestamp.fromDate(date);
}

/// Shared JSON converter for nullable [DateTime?] fields stored as Firestore [Timestamp].
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? date) => date == null ? null : Timestamp.fromDate(date);
}
