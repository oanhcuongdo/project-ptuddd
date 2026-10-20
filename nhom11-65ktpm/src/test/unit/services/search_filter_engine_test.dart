import 'package:flutter_test/flutter_test.dart';
import 'package:study_material_manager/database/app_database.dart';
import 'package:study_material_manager/domain/models/document_filter.dart';
import 'package:study_material_manager/domain/models/document_type.dart';
import 'package:study_material_manager/domain/services/search_filter_engine.dart';

void main() {
  final now = DateTime.now();

  final doc1 = Document(
    documentPk: '1',
    title: 'Bài giảng Kiến trúc Vi dịch vụ (Microservices)',
    subjectFk: 'sub-se',
    docType: 'lecture',
    content: 'Thiết kế Event-Driven và API Gateway',
    fileUrl: null,
    priority: 2,
    status: 'active',
    dateTimeCreated: now.subtract(const Duration(days: 3)),
    dateTimeModified: now.subtract(const Duration(days: 1)),
  );

  final doc2 = Document(
    documentPk: '2',
    title: 'Bài tập Thiết kế Cơ sở Dữ liệu Phân tán',
    subjectFk: 'sub-db',
    docType: 'assignment',
    content: 'Cài đặt Sharding và Replication trên MongoDB',
    fileUrl: null,
    priority: 1,
    status: 'completed',
    dateTimeCreated: now.subtract(const Duration(days: 2)),
    dateTimeModified: now.subtract(const Duration(hours: 2)),
  );

  final doc3 = Document(
    documentPk: '3',
    title: 'Tài liệu Tham khảo: Clean Architecture & DDD',
    subjectFk: 'sub-se',
    docType: 'reference',
    content: 'Sách của Robert C. Martin về phân lớp phần mềm',
    fileUrl: null,
    priority: 0,
    status: 'active',
    dateTimeCreated: now.subtract(const Duration(days: 1)),
    dateTimeModified: now,
  );

  final allDocs = [doc1, doc2, doc3];

  final subjects = {
    'sub-se': Subject(
      subjectPk: 'sub-se',
      code: 'SE310',
      name: 'Kiến trúc Phần mềm',
      lecturer: 'TS. Nguyễn Văn A',
      semester: 'HK1',
      colorHex: '#1E88E5',
      dateTimeModified: now,
    ),
    'sub-db': Subject(
      subjectPk: 'sub-db',
      code: 'DB302',
      name: 'Cơ sở Dữ liệu Nâng cao',
      lecturer: 'ThS. Trần B',
      semester: 'HK1',
      colorHex: '#43A047',
      dateTimeModified: now,
    ),
  };

  group('Tầng Logic Nghiệp vụ - SearchFilterEngine Tests (Pure Logic)', () {
    test('Lọc theo Môn học (Subject)', () {
      const filter = DocumentFilter(subjectFk: 'sub-se');
      final result = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: filter,
        subjectMap: subjects,
      );

      expect(result.length, equals(2));
      expect(result.map((d) => d.documentPk), containsAll(['1', '3']));
    });

    test('Lọc theo Loại tài liệu (DocumentType)', () {
      const filter = DocumentFilter(docType: DocumentType.assignment);
      final result = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: filter,
        subjectMap: subjects,
      );

      expect(result.length, equals(1));
      expect(result.first.documentPk, equals('2'));
    });

    test('Lọc theo Trạng thái học tập (Status)', () {
      const filter = DocumentFilter(status: 'completed');
      final result = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: filter,
        subjectMap: subjects,
      );

      expect(result.length, equals(1));
      expect(result.first.documentPk, equals('2'));
    });

    test('Tìm kiếm từ khóa qua Tiêu đề, Nội dung hoặc Tên giảng viên', () {
      // 1. Khớp từ khóa trong nội dung
      final res1 = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: const DocumentFilter(searchQuery: 'Event-Driven'),
        subjectMap: subjects,
      );
      expect(res1.length, equals(1));
      expect(res1.first.documentPk, equals('1'));

      // 2. Khớp tên Giảng viên qua subjectMap
      final res2 = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: const DocumentFilter(searchQuery: 'Nguyễn Văn A'),
        subjectMap: subjects,
      );
      expect(res2.length, equals(2));
      expect(res2.map((d) => d.documentPk), containsAll(['1', '3']));
    });

    test('Sắp xếp theo độ ưu tiên (Priority Descending)', () {
      const filter = DocumentFilter(sortBy: DocumentSortBy.priorityDesc);
      final result = SearchFilterEngine.applyFilter(
        documents: allDocs,
        filter: filter,
        subjectMap: subjects,
      );

      expect(result.first.priority, equals(2)); // doc1
      expect(result[1].priority, equals(1));   // doc2
      expect(result.last.priority, equals(0));  // doc3
    });
  });
}
