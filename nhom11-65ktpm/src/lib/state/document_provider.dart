import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../domain/models/document_filter.dart';
import '../domain/models/document_type.dart';
import '../domain/services/document_service.dart';
import '../domain/services/subject_service.dart';
import '../domain/services/search_filter_engine.dart';
import '../domain/services/backup_restore_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentService _documentService;
  final SubjectService _subjectService;
  final BackupRestoreService _backupRestoreService;

  StreamSubscription<List<Document>>? _docSub;
  StreamSubscription<List<Subject>>? _subjSub;

  List<Document> _documents = [];
  List<Subject> _subjects = [];
  Map<String, Subject> _subjectMap = {};

  DocumentFilter _filter = const DocumentFilter();
  bool _isLoading = true;

  DocumentProvider({
    required DocumentService documentService,
    required SubjectService subjectService,
    required BackupRestoreService backupRestoreService,
  })  : _documentService = documentService,
        _subjectService = subjectService,
        _backupRestoreService = backupRestoreService {
    _initStreams();
  }

  bool get isLoading => _isLoading;
  List<Document> get allDocuments => _documents;
  List<Subject> get subjects => _subjects;
  Map<String, Subject> get subjectMap => _subjectMap;
  DocumentFilter get filter => _filter;

  List<Document> get filteredDocuments {
    return SearchFilterEngine.applyFilter(
      documents: _documents,
      filter: _filter,
      subjectMap: _subjectMap,
    );
  }

  void _initStreams() {
    _subjSub = _subjectService.watchAllSubjects().listen((subs) {
      _subjects = subs;
      _subjectMap = {for (final s in subs) s.subjectPk: s};
      _isLoading = false;
      notifyListeners();
    });

    _docSub = _documentService.watchAllDocuments().listen((docs) {
      _documents = docs;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setSubjectFilter(String? subjectFk) {
    if (subjectFk == null) {
      _filter = _filter.copyWith(clearSubject: true);
    } else {
      _filter = _filter.copyWith(subjectFk: subjectFk);
    }
    notifyListeners();
  }

  void setDocTypeFilter(DocumentType? docType) {
    if (docType == null) {
      _filter = _filter.copyWith(clearDocType: true);
    } else {
      _filter = _filter.copyWith(docType: docType);
    }
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    if (status == null) {
      _filter = _filter.copyWith(clearStatus: true);
    } else {
      _filter = _filter.copyWith(status: status);
    }
    notifyListeners();
  }

  void setSortBy(DocumentSortBy sortBy) {
    _filter = _filter.copyWith(sortBy: sortBy);
    notifyListeners();
  }

  void clearFilters() {
    _filter = const DocumentFilter();
    notifyListeners();
  }

  Future<Document> addDocument({
    required String title,
    String? subjectFk,
    required String docType,
    String? content,
    String? fileUrl,
    int priority = 1,
    String status = 'active',
  }) {
    return _documentService.createDocument(
      title: title,
      subjectFk: subjectFk,
      docType: docType,
      content: content,
      fileUrl: fileUrl,
      priority: priority,
      status: status,
    );
  }

  Future<Document> updateDocument({
    required String documentPk,
    required String title,
    String? subjectFk,
    required String docType,
    String? content,
    String? fileUrl,
    int priority = 1,
    String status = 'active',
  }) {
    return _documentService.updateDocument(
      documentPk: documentPk,
      title: title,
      subjectFk: subjectFk,
      docType: docType,
      content: content,
      fileUrl: fileUrl,
      priority: priority,
      status: status,
    );
  }

  Future<void> deleteDocument(String documentPk) {
    return _documentService.deleteDocument(documentPk);
  }

  Future<Subject> addSubject({
    required String code,
    required String name,
    String? lecturer,
    String? semester,
    String colorHex = '#1E88E5',
  }) {
    return _subjectService.createSubject(
      code: code,
      name: name,
      lecturer: lecturer,
      semester: semester,
      colorHex: colorHex,
    );
  }

  Future<Subject> updateSubject({
    required String subjectPk,
    required String code,
    required String name,
    String? lecturer,
    String? semester,
    String colorHex = '#1E88E5',
  }) {
    return _subjectService.updateSubject(
      subjectPk: subjectPk,
      code: code,
      name: name,
      lecturer: lecturer,
      semester: semester,
      colorHex: colorHex,
    );
  }

  Future<void> deleteSubject(String subjectPk) {
    return _subjectService.deleteSubject(subjectPk);
  }

  Future<String> exportBackup() => _backupRestoreService.exportBackupJson();

  Future<int> importBackup(String json) => _backupRestoreService.importBackupJson(json);

  @override
  void dispose() {
    _docSub?.cancel();
    _subjSub?.cancel();
    super.dispose();
  }
}
