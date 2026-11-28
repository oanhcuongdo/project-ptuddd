import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/utils/timestamp_converter.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

enum TripType { beach, trekking, motorbike, backpacking, other }

enum TripStatus { planning, ongoing, completed, cancelled }

@freezed
abstract class TripModel with _$TripModel {
  const TripModel._();

  const factory TripModel({
    required String id,
    required String title,
    required String destination,
    double? destinationLat,
    double? destinationLng,
    @Default(TripType.other) TripType tripType,
    String? coverImageUrl,
    String? coverStoragePath,
    @TimestampConverter() required DateTime startDate,
    @TimestampConverter() required DateTime endDate,
    required String hostId,
    @Default(<String>[]) List<String> memberIds,
    required String inviteCode,
    @Default(TripStatus.planning) TripStatus status,
    @Default(0) int targetBudget,
    @Default(0) int perMemberTarget,
    @Default('weekly') String savingFrequency,
    @Default(0) int checklistTotal,
    @Default(0) int checklistCompleted,
    @Default(0) int totalSavedAmount,
    @Default(0) int totalPlannedItineraryCost,
    @Default(0) int totalSpentAmount,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);

  int daysUntilStart([DateTime? from]) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.difference(today).inDays;
  }

  double get fundProgress =>
      targetBudget <= 0 ? 0.0 : (totalSavedAmount / targetBudget).clamp(0.0, 1.0);

  double get checklistProgress => checklistTotal <= 0
      ? 0.0
      : (checklistCompleted / checklistTotal).clamp(0.0, 1.0);
}
