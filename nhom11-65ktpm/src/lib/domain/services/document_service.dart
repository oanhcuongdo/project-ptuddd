import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/app_database.dart';
import '../../database/daos/document_dao.dart';
import '../../database/daos/delete_log_dao.dart';

class DocumentService {
  final DocumentDao _documentDao;
  final DeleteLogDao _deleteLogDao;
  final Uuid _uuid;

  DocumentService({
    required DocumentDao documentDao,
    required DeleteLogDao deleteLogDao,
    Uuid? uuid,
  })  : _documentDao = documentDao,
        _deleteLogDao = deleteLogDao,
        _uuid = uuid ?? const Uuid();

  Stream<List<Document>> watchAllDocuments() => _documentDao.watchAllDocuments();
  Future<List<Document>> getAllDocuments() => _documentDao.getAllDocuments();
  Future<Document?> getDocumentById(String id) => _documentDao.getDocumentById(id);

  /// Tạo tài liệu học tập mới
  /// - Kiểm tra tính hợp lệ dữ liệu
  /// - Tự động sinh UUID v4 cho primary key
  /// - Gán dateTimeCreated và dateTimeModified hiện tại
  Future<Document> createDocument({
    required String title,
    String? subjectFk,
    required String docType,
    String? content,
    String? fileUrl,
    int priority = 1,
    String status = 'active',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }
    if (trimmedTitle.length > 200) {
      throw ArgumentError('Tiêu đề tài liệu không được vượt quá 200 ký tự.');
    }

    final now = DateTime.now();
    final pk = _uuid.v4();

    final companion = DocumentsCompanion(
      documentPk: Value(pk),
      title: Value(trimmedTitle),
      subjectFk: Value(subjectFk),
      docType: Value(docType),
      content: Value(content?.trim()),
      fileUrl: Value(fileUrl?.trim()),
      priority: Value(priority),
      status: Value(status),
      dateTimeCreated: Value(now),
      dateTimeModified: Value(now),
    );

    await _documentDao.insertDocument(companion);
    final created = await _documentDao.getDocumentById(pk);
    return created!;
  }

  /// Cập nhật tài liệu học tập
  /// - Xác minh bản ghi tồn tại
  /// - Cập nhật dateTimeModified theo cơ chế Last-Write-Wins (LWW)
  Future<Document> updateDocument({
    required String documentPk,
    required String title,
    String? subjectFk,
    required String docType,
    String? content,
    String? fileUrl,
    int priority = 1,
    String status = 'active',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }

    final existing = await _documentDao.getDocumentById(documentPk);
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu có mã $documentPk');
    }

    final now = DateTime.now();
    final companion = DocumentsCompanion(
      documentPk: Value(documentPk),
      title: Value(trimmedTitle),
      subjectFk: Value(subjectFk),
      docType: Value(docType),
      content: Value(content?.trim()),
      fileUrl: Value(fileUrl?.trim()),
      priority: Value(priority),
      status: Value(status),
      dateTimeCreated: Value(existing.dateTimeCreated),
      dateTimeModified: Value(now),
    );

    await _documentDao.updateDocument(companion);
    final updated = await _documentDao.getDocumentById(documentPk);
    return updated!;
  }

  /// Xóa tài liệu học tập với cơ chế Tombstone (DeleteLogs) của Kiến trúc Cashew:
  /// 1. Xóa bản ghi trong bảng Documents
  /// 2. Thêm bản ghi tương ứng vào bảng DeleteLogs để phục vụ đồng bộ phân tán
  Future<void> deleteDocument(String documentPk) async {
    final existing = await _documentDao.getDocumentById(documentPk);
    if (existing == null) {
      throw StateError('Không tìm thấy tài liệu cần xóa: $documentPk');
    }

    final now = DateTime.now();

    // 1. Xóa trong bảng Documents
    await _documentDao.deleteDocumentById(documentPk);

    // 2. Ghi nhận Tombstone vào DeleteLogs
    await _deleteLogDao.insertDeleteLog(
      DeleteLogsCompanion(
        deleteLogPk: Value(_uuid.v4()),
        entryPk: Value(documentPk),
        itemType: const Value('document'),
        dateTimeModified: Value(now),
      ),
    );
  }
}
