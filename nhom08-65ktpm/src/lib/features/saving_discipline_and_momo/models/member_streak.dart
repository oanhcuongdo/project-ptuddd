import 'package:cloud_firestore/cloud_firestore.dart';

class MemberStreak {
  final String memberId;
  final String tripId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastDepositDate;
  final List<String> depositDates; // ISO format: ['YYYY-MM-DD']
  final int totalDisciplinedDays;

  const MemberStreak({
    required this.memberId,
    required this.tripId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastDepositDate,
    this.depositDates = const [],
    this.totalDisciplinedDays = 0,
  });

  factory MemberStreak.fromMap(Map<String, dynamic> map, {String? memberId, String? tripId}) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rawList = map['depositDates'];
    List<String> dates = [];
    if (rawList is List) {
      dates = rawList.map((e) => e.toString()).toList();
    }

    return MemberStreak(
      memberId: memberId ?? (map['memberId'] as String? ?? ''),
      tripId: tripId ?? (map['tripId'] as String? ?? ''),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastDepositDate: parseNullableDate(map['lastDepositDate']),
      depositDates: dates,
      totalDisciplinedDays: (map['totalDisciplinedDays'] as num?)?.toInt() ?? dates.length,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'tripId': tripId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastDepositDate != null) 'lastDepositDate': Timestamp.fromDate(lastDepositDate!),
      'depositDates': depositDates,
      'totalDisciplinedDays': totalDisciplinedDays,
    };
  }

  MemberStreak copyWith({
    String? memberId,
    String? tripId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastDepositDate,
    List<String>? depositDates,
    int? totalDisciplinedDays,
  }) {
    return MemberStreak(
      memberId: memberId ?? this.memberId,
      tripId: tripId ?? this.tripId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastDepositDate: lastDepositDate ?? this.lastDepositDate,
      depositDates: depositDates ?? this.depositDates,
      totalDisciplinedDays: totalDisciplinedDays ?? this.totalDisciplinedDays,
    );
  }
}
