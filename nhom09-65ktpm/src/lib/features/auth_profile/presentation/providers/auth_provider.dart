import 'package:flutter/foundation.dart';

import '../../data/models/language_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Quản lý trạng thái đăng nhập (Auth State) và luồng Thiết lập hồ sơ (Onboarding)
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, bool autoRestore = true})
      : _repository = repository ?? AuthRepository() {
    if (autoRestore && _repository.canRestoreSession) {
      _isInitializing = true;
      restoreSession();
    }
  }

  final AuthRepository _repository;

  ProfileModel? _currentProfile;
  bool _isInitializing = false;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null;
  bool get needsOnboarding =>
      _currentProfile != null && !_currentProfile!.onboardingCompleted;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Khôi phục phiên đăng nhập đã lưu (khi bấm F5 hoặc mở lại app)
  Future<void> restoreSession() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _currentProfile = await _repository.restoreSession();
    } catch (e) {
      debugPrint('[AuthProvider] Khong the khoi phuc phien: $e');
      _currentProfile = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  /// Đăng ký tài khoản mới (Email + Mật khẩu) rồi quay về trang Đăng nhập
  Future<bool> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.registerWithEmail(email: email, password: password);
      _currentProfile = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Bad state: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(_repository.signInWithGoogle);
  }

  /// Tải danh sách ngôn ngữ được Admin cấp phép từ bảng `languages` trên Supabase
  Future<List<LanguageModel>> fetchAllowedLanguages() {
    return _repository.fetchAllowedLanguages();
  }

  /// Lưu hoàn tất hồ sơ Onboarding lên Supabase
  Future<bool> completeOnboarding({
    required String displayName,
    String? avatarUrl,
    String? nativeLang,
    required String targetLang,
    required String proficiencyLevel,
    required int dailyGoalMinutes,
  }) async {
    final userId = _currentProfile?.userId;
    if (userId == null) return false;

    return _runAuthAction(
      () => _repository.completeOnboarding(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        nativeLang: nativeLang,
        targetLang: targetLang,
        proficiencyLevel: proficiencyLevel,
        dailyGoalMinutes: dailyGoalMinutes,
      ),
    );
  }

  Future<void> signOut() async {
    final userId = _currentProfile?.userId;
    try {
      await _repository.signOut(userId: userId);
    } finally {
      _currentProfile = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Đồng bộ chuỗi kỷ luật cá nhân trên Header ngay khi học đủ mục tiêu phút/ngày trong Meet
  void updateLocalStreak({required int streakCount, int? bestStreak}) {
    final current = _currentProfile;
    if (current == null) return;
    final nextBest = bestStreak ??
        (streakCount > current.bestStreak ? streakCount : current.bestStreak);
    if (current.streakCount == streakCount && current.bestStreak == nextBest) {
      return;
    }
    _currentProfile = current.copyWith(
      streakCount: streakCount,
      bestStreak: nextBest,
    );
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<ProfileModel> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentProfile = await action();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Bad state: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
