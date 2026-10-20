import 'package:flutter/foundation.dart';
import '../domain/exceptions/permission_denied_exception.dart';
import '../domain/models/cloud_document.dart';
import '../domain/models/document_permission.dart';
import '../domain/services/supabase_document_service.dart';

class SupabaseProvider extends ChangeNotifier {
  final SupabaseDocumentService _service;

  late UserProfile _activeUser;
  List<CloudDocument> _documents = [];
  String _searchQuery = '';
  String _filterScope = 'ALL'; // 'ALL', 'OWNED', 'SHARED'
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastActionMessage;

  SupabaseProvider({SupabaseDocumentService? service})
      : _service = service ?? SupabaseDocumentService() {
    final profiles = _service.getAllUserProfiles();
    _activeUser = profiles.isNotEmpty
        ? profiles.first
        : const UserProfile(
            id: 'user-alice-uid-001',
            email: 'alice@nhom11.edu.vn',
            displayName: 'Nguyễn Thị Alice',
          );
    refreshDocuments();
  }

  UserProfile get activeUser => _activeUser;
  List<UserProfile> get availableTestAccounts => _service.getAllUserProfiles();
  List<CloudDocument> get documents => _documents;
  String get searchQuery => _searchQuery;
  String get filterScope => _filterScope;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastActionMessage => _lastActionMessage;

  /// Chuyển đổi tài khoản người dùng đang hoạt động (Phục vụ kiểm thử 3 tài khoản hoặc đồng bộ từ Google Auth)
  Future<void> switchActiveAccount(UserProfile profile) async {
    _activeUser = await _service.upsertUserProfile(
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
    );
    _errorMessage = null;
    _lastActionMessage = 'Đã chuyển sang tài khoản: ${_activeUser.email}';
    await refreshDocuments();
  }

  /// Đồng bộ tài khoản Google đăng nhập từ Firebase Auth sang Supabase Profile
  Future<void> syncGoogleUserToSupabase({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final profile = await _service.upsertUserProfile(
      id: uid,
      email: email,
      displayName: displayName,
      avatarUrl: photoUrl,
    );
    _activeUser = profile;
    await refreshDocuments();
  }

  /// Tải lại danh sách tài liệu theo quyền RLS của người dùng hiện tại
  Future<void> refreshDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _service.searchDocuments(
        userId: _activeUser.id,
        userEmail: _activeUser.email,
        query: _searchQuery,
        filterScope: _filterScope,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshDocuments();
  }

  void setFilterScope(String scope) {
    _filterScope = scope;
    refreshDocuments();
  }

  /// Tạo tài liệu mới trên Supabase
  Future<bool> createDocument({
    required String title,
    String docType = 'LECTURE',
    String? content,
    String? fileUrl,
    String? subjectCode,
    String? subjectName,
    int priority = 0,
    String status = 'NOT_STARTED',
  }) async {
    _errorMessage = null;
    try {
      await _service.createDocument(
        ownerId: _activeUser.id,
        ownerEmail: _activeUser.email,
        title: title,
        docType: docType,
        content: content,
        fileUrl: fileUrl,
        subjectCode: subjectCode,
        subjectName: subjectName,
        priority: priority,
        status: status,
      );
      _lastActionMessage = 'Đã tạo tài liệu "$title" thành công!';
      await refreshDocuments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật tài liệu (Kiểm tra RLS: Chỉ Owner hoặc Editor mới được phép)
  Future<bool> updateDocument({
    required String documentId,
    String? title,
    String? docType,
    String? content,
    String? fileUrl,
    String? subjectCode,
    String? subjectName,
    int? priority,
    String? status,
  }) async {
    _errorMessage = null;
    try {
      await _service.updateDocument(
        documentId: documentId,
        currentUserId: _activeUser.id,
        currentUserEmail: _activeUser.email,
        title: title,
        docType: docType,
        content: content,
        fileUrl: fileUrl,
        subjectCode: subjectCode,
        subjectName: subjectName,
        priority: priority,
        status: status,
      );
      _lastActionMessage = 'Đã cập nhật tài liệu thành công!';
      await refreshDocuments();
      return true;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa tài liệu (Kiểm tra RLS: Chỉ Owner mới được phép)
  Future<bool> deleteDocument(String documentId) async {
    _errorMessage = null;
    try {
      await _service.deleteDocument(
        documentId: documentId,
        currentUserId: _activeUser.id,
        currentUserEmail: _activeUser.email,
      );
      _lastActionMessage = 'Đã xóa tài liệu thành công!';
      await refreshDocuments();
      return true;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Chia sẻ tài liệu cho người dùng khác với quyền VIEW hoặc EDIT
  Future<bool> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permissionLevel,
  }) async {
    _errorMessage = null;
    try {
      await _service.shareDocument(
        documentId: documentId,
        currentUserId: _activeUser.id,
        currentUserEmail: _activeUser.email,
        targetEmail: targetEmail,
        permissionLevel: permissionLevel,
      );
      _lastActionMessage = 'Đã cấp quyền ${permissionLevel.label} cho $targetEmail!';
      await refreshDocuments();
      return true;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Thu hồi quyền chia sẻ
  Future<bool> revokePermission({
    required String documentId,
    required String permissionId,
  }) async {
    _errorMessage = null;
    try {
      await _service.revokePermission(
        documentId: documentId,
        permissionId: permissionId,
        currentUserId: _activeUser.id,
        currentUserEmail: _activeUser.email,
      );
      _lastActionMessage = 'Đã thu hồi quyền truy cập!';
      await refreshDocuments();
      return true;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
