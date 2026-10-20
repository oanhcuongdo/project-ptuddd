import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:study_material_manager/database/app_database.dart';
import 'package:study_material_manager/domain/services/backup_restore_service.dart';

void main() {
  late AppDatabase db;
  late BackupRestoreService backupService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backupService = BackupRestoreService(
      documentDao: db.documentDao,
      subjectDao: db.subjectDao,
      deleteLogDao: db.deleteLogDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Tầng Sao lưu & Phục hồi - BackupRestoreService Tests', () {
    test('Xuất JSON Snapshot và Khôi phục đầy đủ', () async {
      final now = DateTime.now();

      // Thêm môn học và tài liệu
      await db.subjectDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 's1',
          code: 'SE101',
          name: 'Nhập môn Phần mềm',
          dateTimeModified: now,
        ),
      );

      await db.documentDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'd1',
          title: 'Slide 1',
          subjectFk: const Value('s1'),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      // Xuất JSON
      final jsonOutput = await backupService.exportBackupJson();
      final parsed = jsonDecode(jsonOutput);

      expect(parsed['app'], equals('Cashew Study Material Manager'));
      expect((parsed['subjects'] as List).length, equals(1));
      expect((parsed['documents'] as List).length, equals(1));

      // Mở một database mới và Import dữ liệu
      final newDb = AppDatabase(NativeDatabase.memory());
      final newBackupService = BackupRestoreService(
        documentDao: newDb.documentDao,
        subjectDao: newDb.subjectDao,
        deleteLogDao: newDb.deleteLogDao,
      );

      final imported = await newBackupService.importBackupJson(jsonOutput);
      expect(imported, equals(1));

      final docs = await newDb.documentDao.getAllDocuments();
      expect(docs.length, equals(1));
      expect(docs.first.title, equals('Slide 1'));

      await newDb.close();
    });

    test('Xử lý Tombstone khi Import: Không khôi phục tài liệu đã bị ghi nhận trong DeleteLogs', () async {
      final now = DateTime.now();

      // Giả lập chuỗi JSON sao lưu chứa 1 tài liệu d1 và 1 Tombstone cho chính d1
      final backupData = {
        'subjects': [],
        'deleteLogs': [
          {
            'deleteLogPk': 'log-1',
            'entryPk': 'd-deleted',
            'itemType': 'document',
            'dateTimeModified': now.toIso8601String(),
          }
        ],
        'documents': [
          {
            'documentPk': 'd-deleted',
            'title': 'Tài liệu đã xóa trước đó',
            'subjectFk': null,
            'docType': 'lecture',
            'content': null,
            'fileUrl': null,
            'priority': 1,
            'status': 'active',
            'dateTimeCreated': now.toIso8601String(),
            'dateTimeModified': now.toIso8601String(),
          },
          {
            'documentPk': 'd-valid',
            'title': 'Tài liệu hợp lệ',
            'subjectFk': null,
            'docType': 'lecture',
            'content': null,
            'fileUrl': null,
            'priority': 1,
            'status': 'active',
            'dateTimeCreated': now.toIso8601String(),
            'dateTimeModified': now.toIso8601String(),
          },
        ]
      };

      final jsonStr = jsonEncode(backupData);
      final importedCount = await backupService.importBackupJson(jsonStr);

      // Chỉ có d-valid được import, d-deleted bị bỏ qua do có Tombstone trong DeleteLogs
      expect(importedCount, equals(1));

      final allDocs = await db.documentDao.getAllDocuments();
      expect(allDocs.length, equals(1));
      expect(allDocs.first.documentPk, equals('d-valid'));
    });
  });
}
