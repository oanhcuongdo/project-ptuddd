import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/user_profile.dart';
import '../domain/enums.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_profile_repository.dart';
import 'reminder_scheduler.dart';

enum SessionStatus { loading, signedOut, needsOnboarding, ready }

/// Trạng thái phiên đăng nhập dùng chung toàn app (ChangeNotifier).
///
/// - Lắng nghe Firebase Auth; khi có user thì lắng nghe hồ sơ `users/{uid}`.
/// - Quyết định màn hình: Đăng nhập / Onboarding / Ứng dụng chính.
/// - Lập lại lịch nhắc khi mở app, đăng nhập, đổi cài đặt; hủy khi đăng xuất.
class SessionService extends ChangeNotifier {
  SessionService(this._auth, this._profiles, this._reminders) {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _auth;
  final UserProfileRepository _profiles;
  final ReminderScheduler _reminders;

  StreamSubscription<AuthUser?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;
  ReminderSettings? _scheduledReminders;

  SessionStatus _status = SessionStatus.loading;
  AuthUser? _user;
  UserProfile? _profile;

  SessionStatus get status => _status;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;

  /// uid của người đang đăng nhập. Chỉ gọi khi đã đăng nhập.
  String get uid => _user!.uid;

  /// Mục tiêu hiện tại (mặc định "cân bằng" nếu chưa có hồ sơ).
  Goal get goal => _profile?.goal ?? Goal.balanced;

  void _onAuthChanged(AuthUser? user) {
    _profileSub?.cancel();
    _profileSub = null;
    _profile = null;
    _user = user;

    if (user == null) {
      _status = SessionStatus.signedOut;
      _scheduledReminders = null;
      unawaited(_reminders.cancelAll());
      notifyListeners();
      return;
    }

    _status = SessionStatus.loading;
    notifyListeners();
    _profileSub = _profiles.watchProfile(user.uid).listen(
      _onProfileChanged,
      onError: (Object e) {
        debugPrint('watchProfile error: $e');
        if (_user?.uid != user.uid) return;
        _status = SessionStatus.needsOnboarding;
        notifyListeners();
      },
    );
  }

  void _onProfileChanged(UserProfile? profile) {
    _profile = profile;
    _status = (profile != null && profile.isOnboarded)
        ? SessionStatus.ready
        : SessionStatus.needsOnboarding;
    if (profile != null && profile.isOnboarded) _syncReminders(profile.reminders);
    notifyListeners();
  }

  void _syncReminders(ReminderSettings settings) {
    if (settings == _scheduledReminders) return; // không đổi thì không lập lại
    _scheduledReminders = settings;
    unawaited(_reminders.reschedule(settings));
  }

  Future<void> saveProfile(UserProfile profile) => _profiles.saveProfile(profile);

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
