import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:study_material_manager/database/app_database.dart';
import 'package:study_material_manager/domain/services/document_service.dart';

void main() {
  late AppDatabase db;
  late DocumentService documentService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    documentService = DocumentService(
      documentDao: db.documentDao,
      deleteLogDao: db.deleteLogDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Tầng Logic Nghiệp vụ - DocumentService Tests', () {
    test('Xác thực tính hợp lệ (Validation): Tiêu đề rỗng phải ném ArgumentError', () async {
      expect(
        () => documentService.createDocument(
          title: '   ',
          docType: 'lecture',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Xác thực tiêu đề quá dài (> 200 ký tự) phải ném ArgumentError', () async {
      final longTitle = 'A' * 201;
      expect(
        () => documentService.createDocument(
          title: longTitle,
          docType: 'lecture',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Tạo tài liệu hợp lệ: Tự động gán UUID và thời gian tạo/sửa', () async {
      final doc = await documentService.createDocument(
        title: 'Bài giảng Hệ điều hành',
        docType: 'lecture',
        content: 'Khái niệm Tiến trình và Luồng',
        priority: 2,
      );

      expect(doc.documentPk, isNotEmpty);
      expect(doc.title, equals('Bài giảng Hệ điều hành'));
      expect(doc.priority, equals(2));
      expect(doc.dateTimeCreated, isNotNull);
      expect(doc.dateTimeModified, isNotNull);
      expect(doc.status, equals('active'));
    });

    test('Cập nhật tài liệu: Tự động cập nhật dateTimeModified (Last-Write-Wins)', () async {
      final created = await documentService.createDocument(
        title: 'Phiên bản gốc',
        docType: 'lecture',
      );

      // Chờ nhẹ để timestamp khác biệt
      await Future.delayed(const Duration(milliseconds: 20));

      final updated = await documentService.updateDocument(
        documentPk: created.documentPk,
        title: 'Phiên bản sửa đổi',
        docType: 'assignment',
        priority: 2,
      );

      expect(updated.title, equals('Phiên bản sửa đổi'));
      expect(updated.docType, equals('assignment'));
      expect(updated.dateTimeCreated, equals(created.dateTimeCreated));
      expect(updated.dateTimeModified.isAfter(created.dateTimeModified) || updated.dateTimeModified.isAtSameMomentAs(created.dateTimeModified), isTrue);
    });

    test('Xóa tài liệu: Phải xóa khỏi Documents và tự động tạo DeleteLog Tombstone', () async {
      final doc = await documentService.createDocument(
        title: 'Tài liệu chuẩn bị xóa',
        docType: 'reference',
      );

      final docPk = doc.documentPk;

      // Thực hiện xóa
      await documentService.deleteDocument(docPk);

      // 1. Kiểm tra tài liệu đã bị xóa khỏi bảng Documents
      final found = await documentService.getDocumentById(docPk);
      expect(found, isNull);

      // 2. Kiểm tra bản ghi Tombstone đã được ghi nhận trong DeleteLogs
      final deleteLogs = await db.deleteLogDao.getAllDeleteLogs();
      expect(deleteLogs.length, equals(1));
      expect(deleteLogs.first.entryPk, equals(docPk));
      expect(deleteLogs.first.itemType, equals('document'));
    });
  });
}
