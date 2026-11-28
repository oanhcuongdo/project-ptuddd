/// Status values used by the `buddy_matches` table.
enum BuddyMatchStatus {
  pending,
  accepted,
  rejected,
  blocked;

  static BuddyMatchStatus fromValue(Object? value) {
    if (value is String) {
      for (final status in values) {
        if (status.name == value) return status;
      }
    }

    throw FormatException('Invalid buddy match status: $value');
  }
}

/// A buddy request or an established buddy match.
///
/// Field names map to the `public.buddy_matches` table in Supabase.
class BuddyModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final BuddyMatchStatus status;
  final DateTime? matchedAt;
  final DateTime createdAt;

  const BuddyModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    this.status = BuddyMatchStatus.pending,
    this.matchedAt,
    required this.createdAt,
  });

  bool get isPending => status == BuddyMatchStatus.pending;
  bool get isAccepted => status == BuddyMatchStatus.accepted;
  bool get isRejected => status == BuddyMatchStatus.rejected;
  bool get isBlocked => status == BuddyMatchStatus.blocked;

  /// Returns the other participant's user ID, or null if [userId] is not part
  /// of this match.
  String? otherUserIdFor(String userId) {
    if (userId == requesterId) return receiverId;
    if (userId == receiverId) return requesterId;
    return null;
  }

  factory BuddyModel.fromMap(Map<String, dynamic> map) {
    final matchedAt = _parseDateTime(map['matched_at'], 'matched_at');
    final createdAt = _parseDateTime(map['created_at'], 'created_at');

    if (createdAt == null) {
      throw const FormatException('Missing required field: created_at');
    }

    return BuddyModel(
      id: _requiredString(map, 'id'),
      requesterId: _requiredString(map, 'requester_id'),
      receiverId: _requiredString(map, 'receiver_id'),
      status: BuddyMatchStatus.fromValue(map['status']),
      matchedAt: matchedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.name,
      'matched_at': matchedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing or invalid required field: $key');
}

DateTime? _parseDateTime(Object? value, String fieldName) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid date-time field: $fieldName');
}
