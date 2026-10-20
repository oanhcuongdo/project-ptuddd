import 'document_permission.dart';

/// Vai trò của người dùng đối với một tài liệu cụ thể
enum UserDocumentRole {
  owner('OWNER', 'Chủ sở hữu'),
  editor('EDIT', 'Được chỉnh sửa'),
  viewer('VIEW', 'Chỉ xem'),
  none('NONE', 'Không có quyền');

  final String code;
  final String label;
  const UserDocumentRole(this.code, this.label);
}

/// Mô hình tài liệu lưu trữ trên đám mây Supabase
class CloudDocument {
  final String id;
  final String ownerId;
  final String? ownerEmail;
  final String title;
  final String docType; // LECTURE, EXERCISE, REFERENCE, EXAM
  final String? content;
  final String? fileUrl;
  final String? subjectCode;
  final String? subjectName;
  final int priority;
  final String status;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DocumentPermission> permissions;

  CloudDocument({
    required this.id,
    required this.ownerId,
    this.ownerEmail,
    required this.title,
    this.docType = 'LECTURE',
    this.content,
    this.fileUrl,
    this.subjectCode,
    this.subjectName,
    this.priority = 0,
    this.status = 'NOT_STARTED',
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.permissions = const [],
  });

  /// Xác định vai trò của một người dùng đối với tài liệu này
  UserDocumentRole getRoleForUser(String userId, String userEmail) {
    if (ownerId == userId || (ownerEmail != null && ownerEmail!.toLowerCase() == userEmail.toLowerCase())) {
      return UserDocumentRole.owner;
    }

    final matched = permissions.where((p) =>
        p.sharedWithEmail.toLowerCase() == userEmail.toLowerCase());

    if (matched.isNotEmpty) {
      final p = matched.first;
      if (p.permissionLevel == PermissionLevel.edit) {
        return UserDocumentRole.editor;
      }
      return UserDocumentRole.viewer;
    }

    if (isPublic) {
      return UserDocumentRole.viewer;
    }

    return UserDocumentRole.none;
  }

  /// Kiểm tra xem người dùng có quyền chỉnh sửa tài liệu không
  bool canEdit(String userId, String userEmail) {
    final role = getRoleForUser(userId, userEmail);
    return role == UserDocumentRole.owner || role == UserDocumentRole.editor;
  }

  /// Kiểm tra xem người dùng có quyền xóa tài liệu không (Chỉ Owner)
  bool canDelete(String userId, String userEmail) {
    final role = getRoleForUser(userId, userEmail);
    return role == UserDocumentRole.owner;
  }

  /// Kiểm tra xem người dùng có quyền quản lý chia sẻ không (Chỉ Owner)
  bool canShare(String userId, String userEmail) {
    final role = getRoleForUser(userId, userEmail);
    return role == UserDocumentRole.owner;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'doc_type': docType,
      'content': content,
      'file_url': fileUrl,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'priority': priority,
      'status': status,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CloudDocument.fromMap(Map<String, dynamic> map, {List<DocumentPermission> permissions = const []}) {
    return CloudDocument(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      ownerEmail: map['owner_email'] as String?,
      title: map['title'] as String,
      docType: map['doc_type'] as String? ?? 'LECTURE',
      content: map['content'] as String?,
      fileUrl: map['file_url'] as String?,
      subjectCode: map['subject_code'] as String?,
      subjectName: map['subject_name'] as String?,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'NOT_STARTED',
      isPublic: map['is_public'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      permissions: permissions,
    );
  }

  CloudDocument copyWith({
    String? id,
    String? ownerId,
    String? ownerEmail,
    String? title,
    String? docType,
    String? content,
    String? fileUrl,
    String? subjectCode,
    String? subjectName,
    int? priority,
    String? status,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DocumentPermission>? permissions,
  }) {
    return CloudDocument(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      title: title ?? this.title,
      docType: docType ?? this.docType,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permissions: permissions ?? this.permissions,
    );
  }
}
