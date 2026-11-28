import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Phát null khi người dùng chưa có hồ sơ (chưa onboarding).
  Stream<UserProfile?> watchProfile(String uid);

  Future<void> saveProfile(UserProfile profile);
}
