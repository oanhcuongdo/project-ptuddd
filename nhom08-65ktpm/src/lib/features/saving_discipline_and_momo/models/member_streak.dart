import 'package:cloud_firestore/cloud_firestore.dart';

class MemberStreak {
  final String memberId;
  final String tripId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastDepositDate;
  final List<String> depositDates; // ISO format: ['YYYY-MM-DD']
  final int totalDisciplinedDays;
  final Map<String, ({String emoji, String note})> journalEntries;

  const MemberStreak({
    required this.memberId,
    required this.tripId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastDepositDate,
    this.depositDates = const [],
    this.totalDisciplinedDays = 0,
    this.journalEntries = const {},
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

    final rawJournals = map['journalEntries'];
    final journals = <String, ({String emoji, String note})>{};
    if (rawJournals is Map) {
      for (final entry in rawJournals.entries) {
        final val = entry.value;
        if (val is Map) {
          final emoji = val['emoji']?.toString() ?? '';
          final note = val['note']?.toString() ?? '';
          if (emoji.isNotEmpty || note.isNotEmpty) {
            journals[entry.key.toString()] = (emoji: emoji, note: note);
          }
        }
      }
    }

    return MemberStreak(
      memberId: memberId ?? (map['memberId'] as String? ?? ''),
      tripId: tripId ?? (map['tripId'] as String? ?? ''),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastDepositDate: parseNullableDate(map['lastDepositDate']),
      depositDates: dates,
      totalDisciplinedDays: (map['totalDisciplinedDays'] as num?)?.toInt() ?? dates.length,
      journalEntries: journals,
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
      if (journalEntries.isNotEmpty)
        'journalEntries': {
          for (final entry in journalEntries.entries)
            entry.key: {
              'emoji': entry.value.emoji,
              'note': entry.value.note,
            },
        },
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
    Map<String, ({String emoji, String note})>? journalEntries,
  }) {
    return MemberStreak(
      memberId: memberId ?? this.memberId,
      tripId: tripId ?? this.tripId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastDepositDate: lastDepositDate ?? this.lastDepositDate,
      depositDates: depositDates ?? this.depositDates,
      totalDisciplinedDays: totalDisciplinedDays ?? this.totalDisciplinedDays,
      journalEntries: journalEntries ?? this.journalEntries,
    );
  }
}
