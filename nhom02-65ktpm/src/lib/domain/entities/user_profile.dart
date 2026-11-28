import '../enums.dart';

/// Hồ sơ người dùng `users/{uid}`.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.goal,
    this.birthYear,
    this.ageConfirmed = false,
    this.baseline = const BaselineHabits(),
    this.reminders = const ReminderSettings(),
    this.themeMode = AppThemeMode.system,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final int? birthYear;

  /// Người dùng đã xác nhận đủ 18 tuổi. Chưa xác nhận thì không vào app.
  final bool ageConfirmed;
  final Goal goal;
  final BaselineHabits baseline;
  final ReminderSettings reminders;
  final AppThemeMode themeMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Đã hoàn tất onboarding (đủ điều kiện dùng app).
  bool get isOnboarded => ageConfirmed;

  UserProfile copyWith({
    String? displayName,
    int? birthYear,
    bool? ageConfirmed,
    Goal? goal,
    BaselineHabits? baseline,
    ReminderSettings? reminders,
    AppThemeMode? themeMode,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      birthYear: birthYear ?? this.birthYear,
      ageConfirmed: ageConfirmed ?? this.ageConfirmed,
      goal: goal ?? this.goal,
      baseline: baseline ?? this.baseline,
      reminders: reminders ?? this.reminders,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Thói quen ban đầu người dùng tự khai báo khi onboarding.
class BaselineHabits {
  const BaselineHabits({this.sugaryDrinksPerWeek = 0, this.eatOutPerWeek = 0});

  final int sugaryDrinksPerWeek;
  final int eatOutPerWeek;
}

/// Cài đặt nhắc ghi bữa.
class ReminderSettings {
  const ReminderSettings({this.enabled = true, this.times = const ['07:30', '11:45', '18:30']});

  final bool enabled;

  /// Danh sách giờ nhắc "HH:mm" theo giờ Việt Nam.
  final List<String> times;

  ReminderSettings copyWith({bool? enabled, List<String>? times}) =>
      ReminderSettings(enabled: enabled ?? this.enabled, times: times ?? this.times);

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.times.length == times.length &&
      _sameTimes(other.times, times);

  static bool _sameTimes(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(times));
}
