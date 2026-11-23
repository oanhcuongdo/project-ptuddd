import 'package:flutter/foundation.dart';

import '../../data/models/profile_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Quản lý trạng thái đăng nhập (Auth State) cho toàn ứng dụng
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentProfile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
    String? avatarUrl,
    String nativeLang = 'vi',
    String targetLang = 'en',
    String proficiencyLevel = 'A2',
    int dailyGoalMinutes = 20,
  }) async {
    return _runAuthAction(
      () => _repository.registerWithEmail(
        displayName: displayName,
        email: email,
        password: password,
        avatarUrl: avatarUrl,
        nativeLang: nativeLang,
        targetLang: targetLang,
        proficiencyLevel: proficiencyLevel,
        dailyGoalMinutes: dailyGoalMinutes,
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(_repository.signInWithGoogle);
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
