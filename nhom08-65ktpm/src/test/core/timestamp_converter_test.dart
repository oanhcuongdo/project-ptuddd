import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy/core/utils/timestamp_converter.dart';

void main() {
  group('TimestampConverter', () {
    const converter = TimestampConverter();
    const nullableConverter = NullableTimestampConverter();

    test('converts Timestamp, String, and int to DateTime', () {
      final expected = DateTime.utc(2026, 11, 27, 12, 30);
      expect(converter.fromJson(Timestamp.fromDate(expected)).toUtc(), expected);
      expect(converter.fromJson(expected.toIso8601String()).toUtc(), expected);
      expect(
        converter.fromJson(expected.millisecondsSinceEpoch).toUtc(),
        expected,
      );
      expect(converter.toJson(expected), isA<Timestamp>());
    });

    test('NullableTimestampConverter handles null safely', () {
      expect(nullableConverter.fromJson(null), isNull);
      expect(nullableConverter.toJson(null), isNull);

      final expected = DateTime.utc(2026, 12, 1, 8, 0);
      expect(
        nullableConverter.fromJson(Timestamp.fromDate(expected))?.toUtc(),
        expected,
      );
      expect(nullableConverter.toJson(expected), isA<Timestamp>());
    });
  });
}
