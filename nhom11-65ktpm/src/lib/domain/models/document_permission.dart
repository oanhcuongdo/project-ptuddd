/// Mô hình phân quyền chia sẻ tài liệu trên Supabase
enum PermissionLevel {
  view('VIEW', 'Chỉ xem'),
  edit('EDIT', 'Được chỉnh sửa');

  final String code;
  final String label;
  const PermissionLevel(this.code, this.label);

  static PermissionLevel fromCode(String code) {
    if (code.toUpperCase() == 'EDIT') return PermissionLevel.edit;
    return PermissionLevel.view;
  }
}

class DocumentPermission {
  final String id;
  final String documentId;
  final String sharedWithEmail;
  final PermissionLevel permissionLevel;
  final String grantedBy;
  final DateTime createdAt;

  DocumentPermission({
    required this.id,
    required this.documentId,
    required this.sharedWithEmail,
    required this.permissionLevel,
    required this.grantedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'shared_with_email': sharedWithEmail,
      'permission_level': permissionLevel.code,
      'granted_by': grantedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DocumentPermission.fromMap(Map<String, dynamic> map) {
    return DocumentPermission(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      sharedWithEmail: map['shared_with_email'] as String,
      permissionLevel: PermissionLevel.fromCode(map['permission_level'] as String? ?? 'VIEW'),
      grantedBy: map['granted_by'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DocumentPermission copyWith({
    String? id,
    String? documentId,
    String? sharedWithEmail,
    PermissionLevel? permissionLevel,
    String? grantedBy,
    DateTime? createdAt,
  }) {
    return DocumentPermission(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sharedWithEmail: sharedWithEmail ?? this.sharedWithEmail,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      grantedBy: grantedBy ?? this.grantedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
