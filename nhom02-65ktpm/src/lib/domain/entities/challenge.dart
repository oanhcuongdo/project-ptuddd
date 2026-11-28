import '../enums.dart';

/// Thử thách tuần `users/{uid}/challenges/{challengeId}`.
class Challenge {
  const Challenge({
    this.id,
    required this.type,
    required this.weekStart,
    required this.target,
    this.progress = 0,
    this.status = ChallengeStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final ChallengeType type;

  /// Ngày thứ Hai đầu tuần (giờ Việt Nam), dạng "yyyy-MM-dd".
  final String weekStart;
  final int target;

  /// Luôn được TÍNH LẠI từ nhật ký, không cộng dồn thủ công.
  final int progress;
  final ChallengeStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Challenge copyWith({int? target, int? progress, ChallengeStatus? status}) {
    return Challenge(
      id: id,
      type: type,
      weekStart: weekStart,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
