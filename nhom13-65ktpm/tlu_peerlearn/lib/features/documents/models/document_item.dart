class DocumentItem {
  final String id;
  final String roomId;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'pdf' | 'docx'
  final int fileSize; // bytes <= 5MB
  final String? topic;
  final String uploadedBy;
  final DateTime uploadedAt;

  const DocumentItem({
    required this.id,
    required this.roomId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.topic,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: (json['file_type'] as String?)?.toLowerCase() ?? 'pdf',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      topic: json['topic'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'topic': topic,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isDocx => fileType.toLowerCase() == 'docx';
}
