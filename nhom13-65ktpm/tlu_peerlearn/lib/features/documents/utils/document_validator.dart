class DocumentValidator {
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB in bytes (BR-04)
  static const allowedExtensions = ['pdf', 'docx'];

  /// Validates file extension against allowed types: pdf, docx
  static String? validateFileType(String fileName) {
    if (fileName.trim().isEmpty) {
      return 'Tên tệp không được để trống';
    }

    final ext = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Chỉ chấp nhận tệp định dạng .pdf hoặc .docx';
    }
    return null;
  }

  /// Validates file size in bytes against 5MB maximum limit (BR-04)
  static String? validateFileSize(int sizeInBytes) {
    if (sizeInBytes <= 0) {
      return 'Tệp tin không có nội dung (0 bytes)';
    }
    if (sizeInBytes > maxFileSize) {
      return 'Dung lượng tệp vượt quá giới hạn tối đa 5MB';
    }
    return null;
  }

  /// Validates document upload inputs
  static String? validateUpload({
    required String fileName,
    required int sizeInBytes,
    String? topic,
  }) {
    final typeError = validateFileType(fileName);
    if (typeError != null) return typeError;

    final sizeError = validateFileSize(sizeInBytes);
    if (sizeError != null) return sizeError;

    return null;
  }
}
