import 'dart:async';

import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/subjects/domain/entities/classified_note.dart';
import 'package:smart_note/features/subjects/domain/entities/subject.dart';
import 'package:smart_note/features/subjects/domain/repositories/note_classification_repository.dart';
import 'package:smart_note/features/subjects/domain/repositories/subject_repository.dart';

/// Bản giả của [SubjectRepository] lưu trong bộ nhớ, dùng cho widget test.
class FakeSubjectRepository implements SubjectRepository {
  FakeSubjectRepository([List<Subject> subjects = const <Subject>[]])
    : _subjects = List<Subject>.of(subjects);

  final List<Subject> _subjects;
  final StreamController<List<Subject>> _controller =
      StreamController<List<Subject>>.broadcast();

  /// Số lần màn hình gọi đối chiếu với máy chủ.
  int syncCount = 0;

  @override
  Stream<List<Subject>> watchSubjects() async* {
    yield List<Subject>.unmodifiable(_subjects);
    yield* _controller.stream;
  }

  @override
  Future<void> createSubject(Subject subject) async {
    _subjects.add(subject);
    _emit();
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((Subject s) => s.id == subject.id);
    if (index < 0) throw const DatabaseFailure('Không tìm thấy môn học');
    _subjects[index] = subject;
    _emit();
  }

  @override
  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((Subject s) => s.id == id);
    _emit();
  }

  @override
  Future<void> syncWithServer() async {
    syncCount++;
  }

  void _emit() => _controller.add(List<Subject>.unmodifiable(_subjects));

  Future<void> dispose() => _controller.close();
}

/// Bản giả của [NoteClassificationRepository] lưu trong bộ nhớ.
class FakeNoteClassificationRepository implements NoteClassificationRepository {
  FakeNoteClassificationRepository(List<ClassifiedNote> notes)
    : _notes = List<ClassifiedNote>.of(notes);

  final List<ClassifiedNote> _notes;
  final StreamController<List<ClassifiedNote>> _controller =
      StreamController<List<ClassifiedNote>>.broadcast();

  ClassifiedNote byId(String id) =>
      _notes.firstWhere((ClassifiedNote n) => n.id == id);

  @override
  Stream<List<ClassifiedNote>> watchNotes() async* {
    yield List<ClassifiedNote>.unmodifiable(_notes);
    yield* _controller.stream;
  }

  @override
  Future<void> classifyNote(
    String noteId, {
    required String? subjectId,
    required List<String> tags,
  }) async {
    _replaceWhere(
      (ClassifiedNote n) => n.id == noteId,
      (ClassifiedNote n) => _copy(n, subjectId: subjectId, tags: tags),
    );
  }

  @override
  Future<void> renameTag(String from, String to) async {
    _replaceWhere(
      (ClassifiedNote n) => n.tags.contains(from),
      (ClassifiedNote n) => _copy(
        n,
        subjectId: n.subjectId,
        tags: <String>{for (final t in n.tags) t == from ? to : t}.toList(),
      ),
    );
  }

  @override
  Future<void> deleteTag(String tag) async {
    _replaceWhere(
      (ClassifiedNote n) => n.tags.contains(tag),
      (ClassifiedNote n) => _copy(
        n,
        subjectId: n.subjectId,
        tags: n.tags.where((String t) => t != tag).toList(),
      ),
    );
  }

  @override
  Future<void> clearSubject(String subjectId) async {
    _replaceWhere(
      (ClassifiedNote n) => n.subjectId == subjectId,
      (ClassifiedNote n) => _copy(n, subjectId: null, tags: n.tags),
    );
  }

  void _replaceWhere(
    bool Function(ClassifiedNote note) test,
    ClassifiedNote Function(ClassifiedNote note) replace,
  ) {
    for (var i = 0; i < _notes.length; i++) {
      if (test(_notes[i])) _notes[i] = replace(_notes[i]);
    }
    _controller.add(List<ClassifiedNote>.unmodifiable(_notes));
  }

  ClassifiedNote _copy(
    ClassifiedNote note, {
    required String? subjectId,
    required List<String> tags,
  }) {
    return ClassifiedNote(
      id: note.id,
      title: note.title,
      subjectId: subjectId,
      tags: tags,
    );
  }

  Future<void> dispose() => _controller.close();
}
