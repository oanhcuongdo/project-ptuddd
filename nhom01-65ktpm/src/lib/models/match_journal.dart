/// Nhật ký trận đấu / buổi tập.
/// Khớp bảng `match_journals`: date, match_type, rating, goals, assists,
/// review_content, image_url.
class MatchJournal {
  final int? id;
  final String userId;
  final DateTime date;
  final String matchType;
  final int rating;
  final int goals;
  final int assists;
  final String? reviewContent;
  final String? imageUrl;
  final DateTime? createdAt;

  static const types = ['Trận đấu', 'Buổi tập'];

  const MatchJournal({
    this.id,
    required this.userId,
    required this.date,
    this.matchType = 'Trận đấu',
    required this.rating,
    this.goals = 0,
    this.assists = 0,
    this.reviewContent,
    this.imageUrl,
    this.createdAt,
  });

  String get dateIso {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get dateLabel {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  factory MatchJournal.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString();
    return MatchJournal(
      id: (json['id'] as num?)?.toInt(),
      userId: json['user_id'] as String? ?? '',
      date: rawDate == null ? DateTime.now() : DateTime.parse(rawDate),
      matchType: json['match_type'] as String? ?? 'Trận đấu',
      rating: (json['rating'] as num?)?.toInt() ?? 1,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      reviewContent: json['review_content'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Insert/update. Bỏ `id` khi tạo mới để DB tự sinh.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': dateIso,
      'match_type': matchType,
      'rating': rating,
      'goals': goals,
      'assists': assists,
      'review_content': reviewContent,
      'image_url': imageUrl,
    };
  }
}
