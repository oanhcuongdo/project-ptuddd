import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:study_material_manager/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Sử dụng in-memory database để kiểm thử cô lập tầng Data
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Tầng Data Layer - DocumentDao Tests', () {
    test('CRUD cơ bản trên bảng Documents', () async {
      final now = DateTime.now();
      const docPk = 'doc-test-1';

      // 1. Thêm mới tài liệu
      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: docPk,
          title: 'Tài liệu Kiến trúc Máy tính',
          docType: const Value('lecture'),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      // 2. Đọc lại tài liệu
      var doc = await db.documentDao.getDocumentById(docPk);
      expect(doc, isNotNull);
      expect(doc!.title, equals('Tài liệu Kiến trúc Máy tính'));
      expect(doc.docType, equals('lecture'));

      // 3. Cập nhật tài liệu
      final updatedTime = now.add(const Duration(minutes: 5));
      await db.documentDao.updateDocument(
        DocumentsCompanion(
          documentPk: const Value(docPk),
          title: const Value('Tài liệu Kiến trúc Máy tính Nâng cao'),
          docType: const Value('lecture'),
          dateTimeCreated: Value(now),
          dateTimeModified: Value(updatedTime),
        ),
      );

      doc = await db.documentDao.getDocumentById(docPk);
      expect(doc!.title, equals('Tài liệu Kiến trúc Máy tính Nâng cao'));
      expect(doc.dateTimeModified.difference(updatedTime).inSeconds.abs() <= 1, isTrue);

      // 4. Xóa tài liệu
      final deleteCount = await db.documentDao.deleteDocumentById(docPk);
      expect(deleteCount, equals(1));

      doc = await db.documentDao.getDocumentById(docPk);
      expect(doc, isNull);
    });

    test('Kiểm thử tính phản ứng thời gian thực (Reactive Stream Watcher)', () async {
      final now = DateTime.now();

      // Đăng ký lắng nghe Stream
      final stream = db.documentDao.watchAllDocuments();

      // Kiểm tra stream phát ra các danh sách tài liệu phản ứng
      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
          hasLength(2),
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      // Thêm bản ghi 1 -> stream tự động phát sự kiện mới
      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'doc-reactive-1',
          title: 'Bài giảng 1',
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      // Thêm bản ghi 2 -> stream tự động phát sự kiện mới
      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'doc-reactive-2',
          title: 'Bài giảng 2',
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      await expectation;
    });

    test('Tìm kiếm tài liệu bằng LIKE query trong DAO', () async {
      final now = DateTime.now();
      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'd1',
          title: 'Học lập trình Flutter',
          content: const Value('Nội dung về Widget và State'),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'd2',
          title: 'Lý thuyết Cơ sở Dữ liệu',
          content: const Value('Chỉ mục B-Tree và Khóa ngoại'),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      final searchFlutter = await db.documentDao.searchDocuments('Flutter');
      expect(searchFlutter.length, equals(1));
      expect(searchFlutter.first.documentPk, equals('d1'));

      final searchBTree = await db.documentDao.searchDocuments('B-Tree');
      expect(searchBTree.length, equals(1));
      expect(searchBTree.first.documentPk, equals('d2'));
    });
  });
}
