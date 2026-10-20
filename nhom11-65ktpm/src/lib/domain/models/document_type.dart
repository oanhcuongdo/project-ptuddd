enum DocumentType {
  lecture('lecture', 'Bài giảng'),
  assignment('assignment', 'Bài tập'),
  reference('reference', 'Tài liệu tham khảo');

  final String code;
  final String label;

  const DocumentType(this.code, this.label);

  static DocumentType fromCode(String code) {
    return DocumentType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DocumentType.lecture,
    );
  }
}
