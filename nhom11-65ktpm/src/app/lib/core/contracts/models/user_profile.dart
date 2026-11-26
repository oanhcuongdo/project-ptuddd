/// Người dùng hiện tại, khớp `UserOut` của server (`GET /api/me`).
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? displayName;
  final String? avatarUrl;
  final String level;
  final int dailyGoalMinutes;
  final int xpTotal;
  final bool placementDone;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.displayName,
    this.avatarUrl,
    this.level = 'beginner',
    this.dailyGoalMinutes = 15,
    this.xpTotal = 0,
    this.placementDone = false,
  });

  String get shownName => displayName?.isNotEmpty == true ? displayName! : fullName;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String,
    email: j['email'] as String,
    fullName: j['full_name'] as String? ?? '',
    displayName: j['display_name'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    level: j['level'] as String? ?? 'beginner',
    dailyGoalMinutes: j['daily_goal_minutes'] as int? ?? 15,
    xpTotal: j['xp_total'] as int? ?? 0,
    placementDone: j['placement_done'] as bool? ?? false,
  );
}
