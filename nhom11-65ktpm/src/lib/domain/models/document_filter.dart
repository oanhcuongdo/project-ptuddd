import 'document_type.dart';

enum DocumentSortBy {
  modifiedDesc,
  createdDesc,
  titleAsc,
  priorityDesc,
}

class DocumentFilter {
  final String searchQuery;
  final String? subjectFk;
  final DocumentType? docType;
  final String? status;
  final DocumentSortBy sortBy;

  const DocumentFilter({
    this.searchQuery = '',
    this.subjectFk,
    this.docType,
    this.status,
    this.sortBy = DocumentSortBy.modifiedDesc,
  });

  DocumentFilter copyWith({
    String? searchQuery,
    String? subjectFk,
    bool clearSubject = false,
    DocumentType? docType,
    bool clearDocType = false,
    String? status,
    bool clearStatus = false,
    DocumentSortBy? sortBy,
  }) {
    return DocumentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      subjectFk: clearSubject ? null : (subjectFk ?? this.subjectFk),
      docType: clearDocType ? null : (docType ?? this.docType),
      status: clearStatus ? null : (status ?? this.status),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilter =>
      searchQuery.isNotEmpty || subjectFk != null || docType != null || status != null;
}
