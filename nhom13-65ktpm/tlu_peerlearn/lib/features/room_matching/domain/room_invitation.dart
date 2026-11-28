class RoomInvitation {
  final String id;
  final String roomId;
  final String senderId;
  final String receiverId;
  final String type;
  final String status;
  final String? roomName;

  const RoomInvitation({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.status,
    this.roomName,
  });

  factory RoomInvitation.fromJson(Map<String, dynamic> json) {
    final room = json['ck_study_rooms'] as Map<String, dynamic>?;
    return RoomInvitation(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      roomName: room?['name'] as String?,
    );
  }
}
