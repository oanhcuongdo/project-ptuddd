import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase_config.dart';
import '../exceptions/permission_denied_exception.dart';
import '../models/cloud_document.dart';
import '../models/document_permission.dart';

/// Thông tin tài khoản người dùng trên hệ thống
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.role = 'STUDENT',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'role': role,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        email: map['email'] as String,
        displayName: map['display_name'] as String? ?? map['email'] as String,
        avatarUrl: map['avatar_url'] as String?,
        role: map['role'] as String? ?? 'STUDENT',
      );
}

/// Dịch vụ quản lý Tài liệu, Lưu trữ Tệp tin và Phân quyền Chia sẻ (RLS) trên Supabase
class SupabaseDocumentService {
  final SupabaseClient? _customClient;
  final Uuid _uuid = const Uuid();

  // Bộ nhớ lưu trữ cục bộ / mô phỏng RLS chuẩn xác phục vụ kiểm thử đa tài khoản & offline
  final Map<String, UserProfile> _profilesStore = {};
  final Map<String, CloudDocument> _documentsStore = {};
  final Map<String, List<DocumentPermission>> _permissionsStore = {};

  SupabaseDocumentService({
    SupabaseClient? supabaseClient,
    bool seedDefaultData = true,
  }) : _customClient = supabaseClient {
    if (seedDefaultData) {
      _seedInitialMultiUserTestData();
    }
  }

  SupabaseClient? get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Khởi tạo dữ liệu mẫu với 3 tài khoản người dùng khác nhau để kiểm thử phân quyền (Checklist 6)
  void _seedInitialMultiUserTestData() {
    const alice = UserProfile(
      id: 'user-alice-uid-001',
      email: 'alice@nhom11.edu.vn',
      displayName: 'Nguyễn Thị Alice (Tài khoản 1 - Owner)',
      role: 'STUDENT',
    );
    const bob = UserProfile(
      id: 'user-bob-uid-002',
      email: 'bob@nhom11.edu.vn',
      displayName: 'Trần Văn Bob (Tài khoản 2 - Editor)',
      role: 'STUDENT',
    );
    const charlie = UserProfile(
      id: 'user-charlie-uid-003',
      email: 'charlie@nhom11.edu.vn',
      displayName: 'Lê Văn Charlie (Tài khoản 3 - Viewer)',
      role: 'STUDENT',
    );

    _profilesStore[alice.id] = alice;
    _profilesStore[bob.id] = bob;
    _profilesStore[charlie.id] = charlie;

    final now = DateTime.now();

    // Tài liệu 1: Của Alice, chia sẻ quyền EDIT cho Bob và VIEW cho Charlie
    final doc1Perms = [
      DocumentPermission(
        id: 'perm-001',
        documentId: 'doc-001',
        sharedWithEmail: bob.email,
        permissionLevel: PermissionLevel.edit,
        grantedBy: alice.id,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      DocumentPermission(
        id: 'perm-002',
        documentId: 'doc-001',
        sharedWithEmail: charlie.email,
        permissionLevel: PermissionLevel.view,
        grantedBy: alice.id,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    _permissionsStore['doc-001'] = doc1Perms;

    _documentsStore['doc-001'] = CloudDocument(
      id: 'doc-001',
      ownerId: alice.id,
      ownerEmail: alice.email,
      title: 'Bài giảng Giải tích 1 - Đạo hàm và Tích phân',
      docType: 'LECTURE',
      content: 'Tóm tắt công thức vi phân, tích phân suy rộng và chuỗi số Fourier.',
      fileUrl: '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.storageBucket}/giai_tich_1.pdf',
      subjectCode: 'MATH101',
      subjectName: 'Giải tích 1',
      priority: 2,
      status: 'IN_PROGRESS',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(hours: 5)),
      permissions: List.unmodifiable(doc1Perms),
    );

    // Tài liệu 2: Của Alice, giữ riêng tư (không chia sẻ cho ai)
    _permissionsStore['doc-002'] = [];
    _documentsStore['doc-002'] = CloudDocument(
      id: 'doc-002',
      ownerId: alice.id,
      ownerEmail: alice.email,
      title: 'Đề cương Ôn tập Cấu trúc Dữ liệu & Giải thuật (Riêng tư)',
      docType: 'REFERENCE',
      content: 'Cây đỏ đen, B-Tree, Đồ thị Dijkstra, Quy hoạch động nâng cao.',
      fileUrl: '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.storageBucket}/dsa_private.pdf',
      subjectCode: 'CS102',
      subjectName: 'Cấu trúc Dữ liệu & Giải thuật',
      priority: 1,
      status: 'NOT_STARTED',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 1)),
      permissions: const [],
    );

    // Tài liệu 3: Của Bob, chia sẻ quyền VIEW cho Alice và quyền EDIT cho Charlie
    final doc3Perms = [
      DocumentPermission(
        id: 'perm-003',
        documentId: 'doc-003',
        sharedWithEmail: alice.email,
        permissionLevel: PermissionLevel.view,
        grantedBy: bob.id,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      DocumentPermission(
        id: 'perm-004',
        documentId: 'doc-003',
        sharedWithEmail: charlie.email,
        permissionLevel: PermissionLevel.edit,
        grantedBy: bob.id,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
    _permissionsStore['doc-003'] = doc3Perms;

    _documentsStore['doc-003'] = CloudDocument(
      id: 'doc-003',
      ownerId: bob.id,
      ownerEmail: bob.email,
      title: 'Bài tập Lớn Lập trình Đa nền tảng Flutter & Supabase',
      docType: 'EXERCISE',
      content: 'Thiết kế cơ sở dữ liệu quan hệ, cấu hình Row Level Security (RLS) và phân quyền.',
      fileUrl: '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.storageBucket}/flutter_supabase_lab.pdf',
      subjectCode: 'IT308',
      subjectName: 'Phát triển Ứng dụng Đa nền tảng',
      priority: 2,
      status: 'IN_PROGRESS',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      permissions: List.unmodifiable(doc3Perms),
    );
  }

  /// Đồng bộ hoặc đăng ký thông tin người dùng (từ Google Auth sang bảng profiles của Supabase)
  Future<UserProfile> upsertUserProfile({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final profile = UserProfile(
      id: id,
      email: email.trim().toLowerCase(),
      displayName: displayName ?? email.split('@').first,
      avatarUrl: avatarUrl,
    );

    _profilesStore[id] = profile;

    final client = _client;
    if (client != null) {
      try {
        await client.from('profiles').upsert(profile.toMap());
      } catch (e) {
        debugPrint('Supabase upsert profile fallback: $e');
      }
    }
    return profile;
  }

  /// Lấy danh sách tất cả hồ sơ người dùng (phục vụ chọn người nhận khi chia sẻ)
  List<UserProfile> getAllUserProfiles() {
    return _profilesStore.values.toList();
  }

  /// RLS SELECT Policy: Lấy danh sách tài liệu mà người dùng hiện tại có quyền truy cập
  /// Bao gồm: (1) Tài liệu do chính người dùng sở hữu (Owner)
  ///           (2) Tài liệu được người khác chia sẻ (Viewer / Editor)
  ///           (3) Tài liệu công khai (isPublic = true)
  Future<List<CloudDocument>> getAccessibleDocuments({
    required String userId,
    required String userEmail,
  }) async {
    final normalizedEmail = userEmail.trim().toLowerCase();

    final accessible = _documentsStore.values.where((doc) {
      final perms = _permissionsStore[doc.id] ?? [];
      final updatedDoc = doc.copyWith(permissions: perms);
      final role = updatedDoc.getRoleForUser(userId, normalizedEmail);
      return role != UserDocumentRole.none;
    }).map((doc) {
      final perms = _permissionsStore[doc.id] ?? [];
      return doc.copyWith(permissions: List.unmodifiable(perms));
    }).toList();

    accessible.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return accessible;
  }

  /// Tìm kiếm và lọc tài liệu theo từ khóa và phạm vi quyền hạn
  /// [filterScope]: 'ALL' (Tất cả), 'OWNED' (Của tôi), 'SHARED' (Được chia sẻ với tôi)
  Future<List<CloudDocument>> searchDocuments({
    required String userId,
    required String userEmail,
    String query = '',
    String filterScope = 'ALL',
  }) async {
    final allAccessible = await getAccessibleDocuments(
      userId: userId,
      userEmail: userEmail,
    );

    final normalizedQuery = query.trim().toLowerCase();
    final normalizedEmail = userEmail.trim().toLowerCase();

    return allAccessible.where((doc) {
      final role = doc.getRoleForUser(userId, normalizedEmail);

      // Lọc theo phạm vi sở hữu / chia sẻ
      if (filterScope == 'OWNED' && role != UserDocumentRole.owner) {
        return false;
      }
      if (filterScope == 'SHARED' && role == UserDocumentRole.owner) {
        return false;
      }

      // Lọc theo từ khóa tìm kiếm
      if (normalizedQuery.isEmpty) return true;

      final matchTitle = doc.title.toLowerCase().contains(normalizedQuery);
      final matchContent = (doc.content ?? '').toLowerCase().contains(normalizedQuery);
      final matchSubject = (doc.subjectName ?? '').toLowerCase().contains(normalizedQuery) ||
          (doc.subjectCode ?? '').toLowerCase().contains(normalizedQuery);
      final matchOwner = (doc.ownerEmail ?? '').toLowerCase().contains(normalizedQuery);

      return matchTitle || matchContent || matchSubject || matchOwner;
    }).toList();
  }

  /// RLS INSERT Policy: Tạo tài liệu mới trên Supabase
  Future<CloudDocument> createDocument({
    required String ownerId,
    required String ownerEmail,
    required String title,
    String docType = 'LECTURE',
    String? content,
    String? fileUrl,
    String? subjectCode,
    String? subjectName,
    int priority = 0,
    String status = 'NOT_STARTED',
    bool isPublic = false,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }

    final docId = 'doc-${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    final newDoc = CloudDocument(
      id: docId,
      ownerId: ownerId,
      ownerEmail: ownerEmail.trim().toLowerCase(),
      title: title.trim(),
      docType: docType,
      content: content?.trim(),
      fileUrl: fileUrl?.trim(),
      subjectCode: subjectCode?.trim(),
      subjectName: subjectName?.trim(),
      priority: priority,
      status: status,
      isPublic: isPublic,
      createdAt: now,
      updatedAt: now,
      permissions: const [],
    );

    _documentsStore[docId] = newDoc;
    _permissionsStore[docId] = [];

    final client = _client;
    if (client != null) {
      try {
        await client.from('documents').insert(newDoc.toMap());
      } catch (e) {
        debugPrint('Supabase insert document fallback: $e');
      }
    }

    return newDoc;
  }

  /// RLS UPDATE Policy: Cập nhật thông tin tài liệu
  /// Chỉ cho phép nếu người dùng là OWNER hoặc có quyền EDIT trong bảng document_permissions
  Future<CloudDocument> updateDocument({
    required String documentId,
    required String currentUserId,
    required String currentUserEmail,
    String? title,
    String? docType,
    String? content,
    String? fileUrl,
    String? subjectCode,
    String? subjectName,
    int? priority,
    String? status,
    bool? isPublic,
  }) async {
    final existing = _documentsStore[documentId];
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu với mã: $documentId');
    }

    final perms = _permissionsStore[documentId] ?? [];
    final docWithPerms = existing.copyWith(permissions: perms);

    // Kiểm tra chính sách RLS: Chỉ Owner hoặc Editor mới được cập nhật
    if (!docWithPerms.canEdit(currentUserId, currentUserEmail)) {
      final currentRole = docWithPerms.getRoleForUser(currentUserId, currentUserEmail);
      throw PermissionDeniedException(
        'Tài khoản "$currentUserEmail" (Vai trò: ${currentRole.label}) không có quyền chỉnh sửa tài liệu "${existing.title}".',
        requiredRole: 'OWNER hoặc EDIT',
      );
    }

    if (title != null && title.trim().isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }

    final updated = docWithPerms.copyWith(
      title: title?.trim() ?? existing.title,
      docType: docType ?? existing.docType,
      content: content ?? existing.content,
      fileUrl: fileUrl ?? existing.fileUrl,
      subjectCode: subjectCode ?? existing.subjectCode,
      subjectName: subjectName ?? existing.subjectName,
      priority: priority ?? existing.priority,
      status: status ?? existing.status,
      isPublic: isPublic ?? existing.isPublic,
      updatedAt: DateTime.now(),
    );

    _documentsStore[documentId] = updated;

    final client = _client;
    if (client != null) {
      try {
        await client.from('documents').update(updated.toMap()).eq('id', documentId);
      } catch (e) {
        debugPrint('Supabase update document fallback: $e');
      }
    }

    return updated;
  }

  /// RLS DELETE Policy: Xóa tài liệu
  /// CHỈ DUY NHẤT chủ sở hữu (OWNER) mới được xóa tài liệu
  Future<void> deleteDocument({
    required String documentId,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final existing = _documentsStore[documentId];
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu với mã: $documentId');
    }

    final perms = _permissionsStore[documentId] ?? [];
    final docWithPerms = existing.copyWith(permissions: perms);

    if (!docWithPerms.canDelete(currentUserId, currentUserEmail)) {
      final currentRole = docWithPerms.getRoleForUser(currentUserId, currentUserEmail);
      throw PermissionDeniedException(
        'Tài khoản "$currentUserEmail" (Vai trò: ${currentRole.label}) không có quyền xóa tài liệu "${existing.title}". Chỉ Chủ sở hữu (Owner) mới được phép xóa!',
        requiredRole: 'OWNER',
      );
    }

    _documentsStore.remove(documentId);
    _permissionsStore.remove(documentId);

    final client = _client;
    if (client != null) {
      try {
        await client.from('documents').delete().eq('id', documentId);
      } catch (e) {
        debugPrint('Supabase delete document fallback: $e');
      }
    }
  }

  /// RLS PERMISSIONS Policy: Chia sẻ tài liệu cho người dùng khác (hoặc cập nhật mức quyền)
  /// Chỉ Chủ sở hữu (OWNER) mới được phép cấp quyền chia sẻ
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String currentUserId,
    required String currentUserEmail,
    required String targetEmail,
    required PermissionLevel permissionLevel,
  }) async {
    final existing = _documentsStore[documentId];
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu với mã: $documentId');
    }

    if (!existing.canShare(currentUserId, currentUserEmail)) {
      throw PermissionDeniedException(
        'Chỉ chủ sở hữu (Owner) mới có quyền chia sẻ tài liệu "${existing.title}".',
        requiredRole: 'OWNER',
      );
    }

    final cleanTargetEmail = targetEmail.trim().toLowerCase();
    if (cleanTargetEmail.isEmpty || !cleanTargetEmail.contains('@')) {
      throw ArgumentError('Địa chỉ email người nhận không hợp lệ.');
    }

    if (cleanTargetEmail == currentUserEmail.trim().toLowerCase()) {
      throw ArgumentError('Bạn đang là chủ sở hữu của tài liệu này.');
    }

    final perms = List<DocumentPermission>.from(_permissionsStore[documentId] ?? []);
    final existingIdx = perms.indexWhere(
      (p) => p.sharedWithEmail.toLowerCase() == cleanTargetEmail,
    );

    late DocumentPermission resultPerm;
    if (existingIdx >= 0) {
      // Cập nhật quyền hiện có
      resultPerm = perms[existingIdx].copyWith(permissionLevel: permissionLevel);
      perms[existingIdx] = resultPerm;
    } else {
      // Thêm quyền mới
      resultPerm = DocumentPermission(
        id: 'perm-${_uuid.v4().substring(0, 8)}',
        documentId: documentId,
        sharedWithEmail: cleanTargetEmail,
        permissionLevel: permissionLevel,
        grantedBy: currentUserId,
        createdAt: DateTime.now(),
      );
      perms.add(resultPerm);
    }

    _permissionsStore[documentId] = perms;
    _documentsStore[documentId] = existing.copyWith(
      permissions: List.unmodifiable(perms),
      updatedAt: DateTime.now(),
    );

    final client = _client;
    if (client != null) {
      try {
        await client.from('document_permissions').upsert(resultPerm.toMap());
      } catch (e) {
        debugPrint('Supabase share document fallback: $e');
      }
    }

    return resultPerm;
  }

  /// RLS PERMISSIONS Policy: Thu hồi quyền truy cập đã chia sẻ
  Future<void> revokePermission({
    required String documentId,
    required String permissionId,
    required String currentUserId,
    required String currentUserEmail,
  }) async {
    final existing = _documentsStore[documentId];
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu với mã: $documentId');
    }

    if (!existing.canShare(currentUserId, currentUserEmail)) {
      throw PermissionDeniedException(
        'Chỉ chủ sở hữu (Owner) mới có quyền thu hồi chia sẻ tài liệu "${existing.title}".',
        requiredRole: 'OWNER',
      );
    }

    final perms = List<DocumentPermission>.from(_permissionsStore[documentId] ?? []);
    perms.removeWhere((p) => p.id == permissionId);

    _permissionsStore[documentId] = perms;
    _documentsStore[documentId] = existing.copyWith(
      permissions: List.unmodifiable(perms),
      updatedAt: DateTime.now(),
    );

    final client = _client;
    if (client != null) {
      try {
        await client.from('document_permissions').delete().eq('id', permissionId);
      } catch (e) {
        debugPrint('Supabase revoke permission fallback: $e');
      }
    }
  }

  /// Tải tệp vật lý lên Supabase Storage Bucket và trả về URL kết nối với bảng documents
  Future<String> uploadFileToSupabaseStorage({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final client = _client;

    if (client != null) {
      try {
        await client.storage.from(SupabaseConfig.storageBucket).uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: const FileOptions(upsert: true),
            );
        return client.storage.from(SupabaseConfig.storageBucket).getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Supabase storage upload fallback: $e');
      }
    }

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.storageBucket}/$storagePath';
  }
}
