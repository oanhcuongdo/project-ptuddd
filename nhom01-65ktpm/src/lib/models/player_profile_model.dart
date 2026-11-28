/// Model đại diện cho hồ sơ cầu thủ (Bảng player_profiles trên Supabase)
class PlayerProfileModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String position;
  final String preferredFoot;
  final int jerseyNumber;
  final String clubTeam;
  final DateTime? updatedAt;

  const PlayerProfileModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.position = 'Tiền đạo',
    this.preferredFoot = 'Chân phải',
    this.jerseyNumber = 10,
    this.clubTeam = 'FC 65KTPM',
    this.updatedAt,
  });

  /// Chuyển đổi dữ liệu JSON từ Supabase PostgreSQL sang Object Dart
  factory PlayerProfileModel.fromJson(Map<String, dynamic> json) {
    return PlayerProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Cầu thủ mới',
      avatarUrl: json['avatar_url'] as String?,
      position: json['position'] as String? ?? 'Tiền đạo',
      preferredFoot: json['preferred_foot'] as String? ?? 'Chân phải',
      jerseyNumber: (json['jersey_number'] as num?)?.toInt() ?? 10,
      clubTeam: json['club_team'] as String? ?? 'FC 65KTPM',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Chuyển đổi Object sang Map để gửi câu lệnh Insert / Update lên Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'position': position,
      'preferred_foot': preferredFoot,
      'jersey_number': jerseyNumber,
      'club_team': clubTeam,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Tạo bản sao Object với các trường thông tin được cập nhật mới
  PlayerProfileModel copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    String? position,
    String? preferredFoot,
    int? jerseyNumber,
    String? clubTeam,
    DateTime? updatedAt,
  }) {
    return PlayerProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      position: position ?? this.position,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      clubTeam: clubTeam ?? this.clubTeam,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PlayerProfileModel(id: $id, fullName: $fullName, position: $position, jerseyNumber: #$jerseyNumber, club: $clubTeam)';
  }
}
