/// Yêu cầu xin tham gia phòng học nhóm đang ở trạng thái `pending`
class RoomJoinRequest {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String proficiencyLevel;
  final DateTime? requestedAt;

  const RoomJoinRequest({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.proficiencyLevel = 'A1',
    this.requestedAt,
  });
}
