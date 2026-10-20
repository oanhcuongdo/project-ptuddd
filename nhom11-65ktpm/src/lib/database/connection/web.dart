import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor constructDb({String dbName = 'study_materials'}) {
  // ignore: deprecated_member_use
  return WebDatabase(dbName);
}
