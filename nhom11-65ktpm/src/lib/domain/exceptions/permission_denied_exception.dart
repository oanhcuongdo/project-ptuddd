class PermissionDeniedException implements Exception {
  final String message;
  final String? requiredRole;

  PermissionDeniedException(this.message, {this.requiredRole});

  @override
  String toString() => 'PermissionDeniedException: $message${requiredRole != null ? ' (Yêu cầu quyền: $requiredRole)' : ''}';
}
