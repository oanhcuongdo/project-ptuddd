import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/app_database.dart';
import '../../database/daos/subject_dao.dart';
import '../../database/daos/delete_log_dao.dart';

class SubjectService {
  final SubjectDao _subjectDao;
  final DeleteLogDao _deleteLogDao;
  final Uuid _uuid;

  SubjectService({
    required SubjectDao subjectDao,
    required DeleteLogDao deleteLogDao,
    Uuid? uuid,
  })  : _subjectDao = subjectDao,
        _deleteLogDao = deleteLogDao,
        _uuid = uuid ?? const Uuid();

  Stream<List<Subject>> watchAllSubjects() => _subjectDao.watchAllSubjects();
  Future<List<Subject>> getAllSubjects() => _subjectDao.getAllSubjects();
  Future<Subject?> getSubjectById(String id) => _subjectDao.getSubjectById(id);

  /// Tạo môn học mới
  Future<Subject> createSubject({
    required String code,
    required String name,
    String? lecturer,
    String? semester,
    String colorHex = '#1E88E5',
  }) async {
    final trimmedCode = code.trim().toUpperCase();
    final trimmedName = name.trim();

    if (trimmedCode.isEmpty) {
      throw ArgumentError('Mã môn học không được để trống.');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tên môn học không được để trống.');
    }

    final now = DateTime.now();
    final pk = _uuid.v4();

    final companion = SubjectsCompanion(
      subjectPk: Value(pk),
      code: Value(trimmedCode),
      name: Value(trimmedName),
      lecturer: Value(lecturer?.trim()),
      semester: Value(semester?.trim()),
      colorHex: Value(colorHex),
      dateTimeModified: Value(now),
    );

    await _subjectDao.insertSubject(companion);
    final created = await _subjectDao.getSubjectById(pk);
    return created!;
  }

  /// Cập nhật môn học
  Future<Subject> updateSubject({
    required String subjectPk,
    required String code,
    required String name,
    String? lecturer,
    String? semester,
    String colorHex = '#1E88E5',
  }) async {
    final trimmedCode = code.trim().toUpperCase();
    final trimmedName = name.trim();

    if (trimmedCode.isEmpty || trimmedName.isEmpty) {
      throw ArgumentError('Mã và tên môn học không được để trống.');
    }

    final existing = await _subjectDao.getSubjectById(subjectPk);
    if (existing == null) {
      throw StateError('Không tìm thấy môn học: $subjectPk');
    }

    final now = DateTime.now();
    final companion = SubjectsCompanion(
      subjectPk: Value(subjectPk),
      code: Value(trimmedCode),
      name: Value(trimmedName),
      lecturer: Value(lecturer?.trim()),
      semester: Value(semester?.trim()),
      colorHex: Value(colorHex),
      dateTimeModified: Value(now),
    );

    await _subjectDao.updateSubject(companion);
    final updated = await _subjectDao.getSubjectById(subjectPk);
    return updated!;
  }

  /// Xóa môn học kèm Tombstone
  Future<void> deleteSubject(String subjectPk) async {
    final existing = await _subjectDao.getSubjectById(subjectPk);
    if (existing == null) {
      throw StateError('Không tìm thấy môn học cần xóa: $subjectPk');
    }

    final now = DateTime.now();
    await _subjectDao.deleteSubjectById(subjectPk);

    await _deleteLogDao.insertDeleteLog(
      DeleteLogsCompanion(
        deleteLogPk: Value(_uuid.v4()),
        entryPk: Value(subjectPk),
        itemType: const Value('subject'),
        dateTimeModified: Value(now),
      ),
    );
  }
}
