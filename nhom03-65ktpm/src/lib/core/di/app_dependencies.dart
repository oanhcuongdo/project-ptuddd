import 'package:drift/drift.dart';

import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../database/app_database.dart';
import '../database/notes_dao.dart';

/// Nơi duy nhất khởi tạo database và repository.
///
/// `main.dart` tạo một instance rồi truyền xuống widget tree; test có thể truyền
/// [executor] là `NativeDatabase.memory()` để chạy trong bộ nhớ.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.notesDao,
    required this.noteRepository,
  });

  factory AppDependencies.create({QueryExecutor? executor}) {
    final database = AppDatabase(executor);
    final notesDao = NotesDao(database);
    return AppDependencies._(
      database: database,
      notesDao: notesDao,
      noteRepository: NoteRepositoryImpl(notesDao),
    );
  }

  final AppDatabase database;
  final NotesDao notesDao;
  final NoteRepository noteRepository;

  Future<void> dispose() => database.close();
}
