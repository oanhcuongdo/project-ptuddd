class CompatibilityMatch {
  final String userId;
  final String fullName;
  final String role;
  final String courseId;
  final double score;
  final double timeScore;
  final double academicScore;
  final double capacityScore;
  final List<int> availableSlots;
  final double? courseGrade;

  const CompatibilityMatch({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.courseId,
    required this.score,
    required this.timeScore,
    required this.academicScore,
    required this.capacityScore,
    this.availableSlots = const [],
    this.courseGrade,
  });

  int get percentage {
    if (!score.isFinite) return 0;
    return (score.clamp(0.0, 1.0) * 100).round();
  }
}
