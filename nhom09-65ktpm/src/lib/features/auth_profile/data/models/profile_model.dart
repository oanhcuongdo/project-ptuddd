/// Ánh xạ bảng `profiles` (1 users <-> 1 hồ sơ công khai)
class ProfileModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String bio;
  final String nativeLang;
  final String targetLang;
  final String proficiencyLevel;
  final int dailyGoalMinutes;
  final int streakCount;
  final int bestStreak;
  final bool isOnline;
  final bool onboardingCompleted;

  const ProfileModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio = '',
    this.nativeLang = 'vi',
    this.targetLang = 'en',
    this.proficiencyLevel = 'A1',
    this.dailyGoalMinutes = 15,
    this.streakCount = 0,
    this.bestStreak = 0,
    this.isOnline = false,
    this.onboardingCompleted = false,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      userId: map['user_id'].toString(),
      displayName: map['display_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String? ?? '',
      nativeLang: map['native_lang'] as String? ?? 'vi',
      targetLang: map['target_lang'] as String? ?? 'en',
      proficiencyLevel: map['proficiency_level'] as String? ?? 'A1',
      dailyGoalMinutes: (map['daily_goal_minutes'] as num?)?.toInt() ?? 15,
      streakCount: (map['streak_count'] as num?)?.toInt() ?? 0,
      bestStreak: (map['best_streak'] as num?)?.toInt() ?? 0,
      isOnline: map['is_online'] as bool? ?? false,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'native_lang': nativeLang,
      'target_lang': targetLang,
      'proficiency_level': proficiencyLevel,
      'daily_goal_minutes': dailyGoalMinutes,
      'streak_count': streakCount,
      'best_streak': bestStreak,
      'is_online': isOnline,
      'onboarding_completed': onboardingCompleted,
    };
  }
}
