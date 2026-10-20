import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../domain/services/auth_service.dart';
import '../domain/services/firebase_sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseSyncService _syncService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;

  AuthProvider({
    AuthService? authService,
    FirebaseSyncService? syncService,
  })  : _authService = authService ?? AuthService(),
        _syncService = syncService ?? FirebaseSyncService() {
    _initAuthListener();
  }

  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  void _initAuthListener() {
    try {
      _currentUser = _authService.currentUser;
      _authService.authStateChanges.listen((user) {
        _currentUser = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Không thể khởi tạo Auth listener (có thể do môi trường Desktop chưa hỗ trợ native Firebase Auth): $e');
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      _currentUser = credential?.user;
    } catch (e) {
      _errorMessage = 'Đăng nhập Google thất bại: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đồng bộ toàn bộ dữ liệu tài liệu hiện có lên Cloud Firestore & Storage
  Future<bool> syncToFirebase({
    required List<Document> documents,
    required List<Subject> subjects,
  }) async {
    if (!isSignedIn) {
      _errorMessage = 'Vui lòng đăng nhập Google trước khi đồng bộ!';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _syncService.syncDocumentsToFirestore(
        userId: _currentUser!.uid,
        documents: documents,
        subjects: subjects,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Đồng bộ lên Firebase thất bại: $e';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
