class StudyRoom {
  final String id;
  final String courseId;
  final String mentorId;
  final String name;
  final String? description;
  final String roomCode;
  final bool isOpen;

  const StudyRoom({
    required this.id,
    required this.courseId,
    required this.mentorId,
    required this.name,
    required this.roomCode,
    this.description,
    this.isOpen = true,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> json) => StudyRoom(
        id: json['id'] as String,
        courseId: json['course_id'] as String,
        mentorId: json['mentor_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        roomCode: json['room_code'] as String,
        isOpen: json['is_open'] as bool? ?? true,
      );
}
