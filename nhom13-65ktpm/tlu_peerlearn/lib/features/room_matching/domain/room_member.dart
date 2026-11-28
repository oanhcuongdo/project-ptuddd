class RoomMember {
  final String id;
  final String roomId;
  final String userId;
  final String role;
  final String? fullName;
  final String? studentId;

  const RoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    this.fullName,
    this.studentId,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    final profile = json['ck_profiles'] as Map<String, dynamic>?;
    return RoomMember(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      fullName: profile?['full_name'] as String?,
      studentId: profile?['student_id'] as String?,
    );
  }
}
