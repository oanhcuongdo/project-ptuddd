import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/classified_note.dart';
import '../../domain/entities/note_filter.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/note_classification_repository.dart';
import '../../domain/repositories/subject_repository.dart';
import '../../domain/usecases/classification_rules.dart';
import 'subjects_state.dart';

/// Quản lý môn học, tag, việc gán cho ghi chú và bộ lọc danh sách.
///
/// Các thao tác trả về thông báo lỗi để hiển thị, hoặc `null` nếu thành công.
class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit(this._subjects, this._notes) : super(const SubjectsState());

  final SubjectRepository _subjects;
  final NoteClassificationRepository _notes;
  final List<StreamSubscription<Object>> _subscriptions =
      <StreamSubscription<Object>>[];

  /// Bắt đầu theo dõi môn học và ghi chú, rồi đối chiếu môn với máy chủ;
  /// gọi một lần khi mở màn hình. Lỗi đồng bộ chỉ báo, dữ liệu trên máy vẫn dùng được.
  Future<void> load() async {
    emit(state.copyWith(status: SubjectsStatus.loading));
    await _cancelSubscriptions();
    _subscriptions
      ..add(_subjects.watchSubjects().listen(_onSubjects, onError: _onError))
      ..add(_notes.watchNotes().listen(_onNotes, onError: _onError));
    final error = await _run(_subjects.syncWithServer);
    if (error != null && !isClosed) {
      emit(state.copyWith(errorMessage: error));
    }
  }

  void setFilter(NoteFilter filter) => emit(state.copyWith(filter: filter));

  Future<String?> addSubject(String name, {String? color}) => _run(() {
    final now = DateTime.now();
    return _subjects.createSubject(
      Subject(
        // UUID vì `notes.subject_id` trên Supabase là khoá ngoại kiểu `uuid`.
        id: const Uuid().v4(),
        name: ClassificationRules.validateSubjectName(name, state.subjects),
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  Future<String?> updateSubject(
    Subject subject, {
    String? name,
    String? color,
  }) => _run(() {
    final newName = name == null
        ? subject.name
        : ClassificationRules.validateSubjectName(
            name,
            state.subjects,
            exceptId: subject.id,
          );
    return _subjects.updateSubject(
      subject.copyWith(name: newName, color: color, updatedAt: DateTime.now()),
    );
  });

  /// Xoá môn rồi chuyển các ghi chú của môn đó về "chưa phân loại".
  Future<String?> deleteSubject(String id) => _run(() async {
    await _subjects.deleteSubject(id);
    await _notes.clearSubject(id);
  });

  /// Lưu môn học ([subjectId] = `null` để bỏ gán) và danh sách tag cho ghi chú.
  Future<String?> classifyNote(
    String noteId, {
    required String? subjectId,
    required List<String> tags,
  }) => _run(
    () => _notes.classifyNote(
      noteId,
      subjectId: subjectId,
      tags: ClassificationRules.normalizeTagList(tags),
    ),
  );

  Future<String?> renameTag(String from, String to) =>
      _run(() => _notes.renameTag(from, ClassificationRules.validateTag(to)));

  Future<String?> deleteTag(String tag) => _run(() => _notes.deleteTag(tag));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on Failure catch (failure) {
      return failure.message;
    }
  }

  void _onSubjects(List<Subject> subjects) {
    _emitData(subjects: subjects);
  }

  void _onNotes(List<ClassifiedNote> notes) {
    _emitData(notes: notes);
  }

  /// Cập nhật dữ liệu và bỏ khỏi bộ lọc những môn/tag không còn tồn tại.
  void _emitData({List<Subject>? subjects, List<ClassifiedNote>? notes}) {
    final next = state.copyWith(
      status: SubjectsStatus.success,
      subjects: subjects,
      notes: notes,
    );
    emit(
      next.copyWith(
        filter: next.filter.retainExisting(
          next.subjects.map((Subject s) => s.id).toSet(),
          next.tags.toSet(),
        ),
      ),
    );
  }

  void _onError(Object error) {
    emit(
      state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: error is Failure ? error.message : '$error',
      ),
    );
  }

  Future<void> _cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
