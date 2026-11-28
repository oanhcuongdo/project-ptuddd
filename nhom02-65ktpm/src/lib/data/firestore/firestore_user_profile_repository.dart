import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'firestore_converters.dart';
import 'firestore_paths.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._paths);

  final FirestorePaths _paths;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _paths
        .user(uid)
        .snapshots(includeMetadataChanges: true)
        // Bỏ qua kết quả "không tồn tại" lấy từ cache trống (lần đầu cài app),
        // chờ server trả lời để không đẩy nhầm người dùng cũ vào onboarding.
        .where((snap) => snap.exists || !snap.metadata.isFromCache)
        .map((snap) => snap.exists ? _fromMap(uid, snap.data()!) : null);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final ref = _paths.user(profile.uid);
    final data = _toMap(profile)
      ..['updated_at'] = FieldValue.serverTimestamp();
    if (profile.createdAt == null) data['created_at'] = FieldValue.serverTimestamp();
    // Không await: khi offline vẫn lưu vào cache và stream cập nhật ngay.
    FirestoreConverters.fireAndForget(ref.set(data, SetOptions(merge: true)), 'saveProfile');
  }

  Map<String, dynamic> _toMap(UserProfile p) => {
        'display_name': p.displayName,
        'birth_year': p.birthYear,
        'age_confirmed': p.ageConfirmed,
        'goal': p.goal.value,
        'baseline': {
          'sugary_drinks_per_week': p.baseline.sugaryDrinksPerWeek,
          'eat_out_per_week': p.baseline.eatOutPerWeek,
        },
        'reminders': {
          'enabled': p.reminders.enabled,
          'times': p.reminders.times,
        },
        'theme_mode': p.themeMode.value,
      };

  UserProfile _fromMap(String uid, Map<String, dynamic> m) {
    final baseline = m['baseline'] is Map ? m['baseline'] as Map : const {};
    final reminders = m['reminders'] is Map ? m['reminders'] as Map : const {};
    final times = FirestoreConverters.toStringList(reminders['times']);
    return UserProfile(
      uid: uid,
      displayName: (m['display_name'] as String?) ?? '',
      birthYear: m['birth_year'] is int ? m['birth_year'] as int : null,
      ageConfirmed: m['age_confirmed'] == true,
      goal: parseWire(Goal.values, m['goal'], Goal.balanced),
      baseline: BaselineHabits(
        sugaryDrinksPerWeek: FirestoreConverters.toInt(baseline['sugary_drinks_per_week']),
        eatOutPerWeek: FirestoreConverters.toInt(baseline['eat_out_per_week']),
      ),
      reminders: ReminderSettings(
        enabled: reminders['enabled'] != false,
        times: reminders.containsKey('times') ? times : const ReminderSettings().times,
      ),
      themeMode: parseWire(AppThemeMode.values, m['theme_mode'], AppThemeMode.system),
      createdAt: FirestoreConverters.toDateTime(m['created_at']),
      updatedAt: FirestoreConverters.toDateTime(m['updated_at']),
    );
  }
}
