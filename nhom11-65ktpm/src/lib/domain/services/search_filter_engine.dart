import '../../database/app_database.dart';
import '../models/document_filter.dart';

class SearchFilterEngine {
  /// Bộ lọc và tìm kiếm thuần túy (Pure Business Logic)
  /// Có thể kiểm thử độc lập mà không cần kết nối Database hay Flutter UI
  static List<Document> applyFilter({
    required List<Document> documents,
    required DocumentFilter filter,
    Map<String, Subject>? subjectMap,
  }) {
    var result = documents.where((doc) {
      // 1. Lọc theo Môn học
      if (filter.subjectFk != null && doc.subjectFk != filter.subjectFk) {
        return false;
      }

      // 2. Lọc theo Loại tài liệu (Bài giảng / Bài tập / Tài liệu tham khảo)
      if (filter.docType != null && doc.docType != filter.docType!.code) {
        return false;
      }

      // 3. Lọc theo Trạng thái học tập
      if (filter.status != null && doc.status != filter.status) {
        return false;
      }

      // 4. Tìm kiếm theo từ khóa (Tiêu đề, Nội dung, Tên môn học, Giảng viên)
      if (filter.searchQuery.trim().isNotEmpty) {
        final query = filter.searchQuery.trim().toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(query);
        final matchContent = doc.content?.toLowerCase().contains(query) ?? false;
        
        bool matchSubject = false;
        if (subjectMap != null && doc.subjectFk != null) {
          final subj = subjectMap[doc.subjectFk];
          if (subj != null) {
            matchSubject = subj.name.toLowerCase().contains(query) ||
                subj.code.toLowerCase().contains(query) ||
                (subj.lecturer?.toLowerCase().contains(query) ?? false);
          }
        }

        if (!matchTitle && !matchContent && !matchSubject) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sắp xếp danh sách
    switch (filter.sortBy) {
      case DocumentSortBy.modifiedDesc:
        result.sort((a, b) => b.dateTimeModified.compareTo(a.dateTimeModified));
        break;
      case DocumentSortBy.createdDesc:
        result.sort((a, b) => b.dateTimeCreated.compareTo(a.dateTimeCreated));
        break;
      case DocumentSortBy.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case DocumentSortBy.priorityDesc:
        result.sort((a, b) => b.priority.compareTo(a.priority));
        break;
    }

    return result;
  }
}
