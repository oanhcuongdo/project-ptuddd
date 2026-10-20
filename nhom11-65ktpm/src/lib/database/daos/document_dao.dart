import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/documents_table.dart';
import '../tables/subjects_table.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [Documents, Subjects])
class DocumentDao extends DatabaseAccessor<AppDatabase> with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Stream<List<Document>> watchAllDocuments() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<Document>> getAllDocuments() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Document?> getDocumentById(String id) {
    return (select(documents)..where((tbl) => tbl.documentPk.equals(id))).getSingleOrNull();
  }

  Stream<List<Document>> watchDocumentsBySubject(String subjectFk) {
    return (select(documents)
          ..where((tbl) => tbl.subjectFk.equals(subjectFk))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<Document>> watchDocumentsByType(String docType) {
    return (select(documents)
          ..where((tbl) => tbl.docType.equals(docType))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> insertDocument(Insertable<Document> doc) => into(documents).insert(doc);

  Future<bool> updateDocument(Insertable<Document> doc) => update(documents).replace(doc);

  Future<int> deleteDocumentById(String id) {
    return (delete(documents)..where((tbl) => tbl.documentPk.equals(id))).go();
  }

  Future<List<Document>> searchDocuments(String query) {
    final cleanQuery = '%$query%';
    return (select(documents)
          ..where((tbl) => tbl.title.like(cleanQuery) | tbl.content.like(cleanQuery))
          ..orderBy([(t) => OrderingTerm(expression: t.dateTimeModified, mode: OrderingMode.desc)]))
        .get();
  }
}
