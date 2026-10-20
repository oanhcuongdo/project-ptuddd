import 'dart:convert';
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../database/daos/document_dao.dart';
import '../../database/daos/subject_dao.dart';
import '../../database/daos/delete_log_dao.dart';

class BackupRestoreService {
  final DocumentDao _documentDao;
  final SubjectDao _subjectDao;
  final DeleteLogDao _deleteLogDao;

  BackupRestoreService({
    required DocumentDao documentDao,
    required SubjectDao subjectDao,
    required DeleteLogDao deleteLogDao,
  })  : _documentDao = documentDao,
        _subjectDao = subjectDao,
        _deleteLogDao = deleteLogDao;

  /// Xuất dữ liệu ra chuỗi JSON Snapshot (theo nguyên lý Backup của Cashew)
  Future<String> exportBackupJson() async {
    final subjects = await _subjectDao.getAllSubjects();
    final documents = await _documentDao.getAllDocuments();
    final deleteLogs = await _deleteLogDao.getAllDeleteLogs();

    final data = {
      'app': 'Cashew Study Material Manager',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'subjects': subjects.map((s) => {
        'subjectPk': s.subjectPk,
        'code': s.code,
        'name': s.name,
        'lecturer': s.lecturer,
        'semester': s.semester,
        'colorHex': s.colorHex,
        'dateTimeModified': s.dateTimeModified.toIso8601String(),
      }).toList(),
      'documents': documents.map((d) => {
        'documentPk': d.documentPk,
        'title': d.title,
        'subjectFk': d.subjectFk,
        'docType': d.docType,
        'content': d.content,
        'fileUrl': d.fileUrl,
        'priority': d.priority,
        'status': d.status,
        'dateTimeCreated': d.dateTimeCreated.toIso8601String(),
        'dateTimeModified': d.dateTimeModified.toIso8601String(),
      }).toList(),
      'deleteLogs': deleteLogs.map((l) => {
        'deleteLogPk': l.deleteLogPk,
        'entryPk': l.entryPk,
        'itemType': l.itemType,
        'dateTimeModified': l.dateTimeModified.toIso8601String(),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Khôi phục dữ liệu từ JSON Snapshot với xử lý Tombstone (DeleteLogs)
  Future<int> importBackupJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    final subjectsList = (data['subjects'] as List<dynamic>? ?? []);
    final documentsList = (data['documents'] as List<dynamic>? ?? []);
    final deleteLogsList = (data['deleteLogs'] as List<dynamic>? ?? []);

    // 1. Nhập Môn học
    for (final item in subjectsList) {
      final companion = SubjectsCompanion(
        subjectPk: Value(item['subjectPk']),
        code: Value(item['code']),
        name: Value(item['name']),
        lecturer: Value(item['lecturer']),
        semester: Value(item['semester']),
        colorHex: Value(item['colorHex'] ?? '#1E88E5'),
        dateTimeModified: Value(DateTime.parse(item['dateTimeModified'])),
      );
      final existing = await _subjectDao.getSubjectById(item['subjectPk']);
      if (existing == null) {
        await _subjectDao.insertSubject(companion);
      } else if (existing.dateTimeModified.isBefore(DateTime.parse(item['dateTimeModified']))) {
        await _subjectDao.updateSubject(companion);
      }
    }

    // 2. Nhập DeleteLogs
    final Set<String> deletedPks = {};
    for (final item in deleteLogsList) {
      deletedPks.add(item['entryPk']);
      await _deleteLogDao.insertDeleteLog(
        DeleteLogsCompanion(
          deleteLogPk: Value(item['deleteLogPk']),
          entryPk: Value(item['entryPk']),
          itemType: Value(item['itemType']),
          dateTimeModified: Value(DateTime.parse(item['dateTimeModified'])),
        ),
      );
    }

    // 3. Nhập Tài liệu (Kiểm tra Tombstone để không import lại bản ghi đã bị xóa)
    int importedDocs = 0;
    for (final item in documentsList) {
      final docPk = item['documentPk'];
      if (deletedPks.contains(docPk)) {
        continue; // Bỏ qua nếu có Tombstone
      }

      final companion = DocumentsCompanion(
        documentPk: Value(docPk),
        title: Value(item['title']),
        subjectFk: Value(item['subjectFk']),
        docType: Value(item['docType']),
        content: Value(item['content']),
        fileUrl: Value(item['fileUrl']),
        priority: Value(item['priority'] ?? 1),
        status: Value(item['status'] ?? 'active'),
        dateTimeCreated: Value(DateTime.parse(item['dateTimeCreated'])),
        dateTimeModified: Value(DateTime.parse(item['dateTimeModified'])),
      );

      final existing = await _documentDao.getDocumentById(docPk);
      if (existing == null) {
        await _documentDao.insertDocument(companion);
        importedDocs++;
      } else if (existing.dateTimeModified.isBefore(DateTime.parse(item['dateTimeModified']))) {
        await _documentDao.updateDocument(companion);
        importedDocs++;
      }
    }

    return importedDocs;
  }
}
