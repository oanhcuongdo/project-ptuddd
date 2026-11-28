import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/subjects_dao.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/subjects/data/datasources/remote/subjects_remote_data_source.dart';
import 'package:smart_note/features/subjects/data/models/subject_remote_mapper.dart';
import 'package:smart_note/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:smart_note/features/subjects/domain/entities/subject.dart';

/// Máy chủ giả lưu môn trong bộ nhớ; có thể bật lỗi mạng.
class _FakeRemote implements SubjectsRemoteDataSource {
  final Map<String, Subject> saved = <String, Subject>{};
  bool offline = false;

  @override
  Future<List<Subject>> fetchSubjects(String userId) async {
    if (offline) throw Exception('mất mạng');
    return saved.values.toList();
  }

  @override
  Future<void> upsertSubject(String userId, Subject subject) async {
    if (offline) throw Exception('mất mạng');
    saved[subject.id] = subject;
  }
}

Subject _subject(String id, String name, DateTime updatedAt) => Subject(
  id: id,
  name: name,
  color: '#43A047',
  createdAt: DateTime(2026, 11, 1),
  updatedAt: updatedAt,
);

void main() {
  late AppDatabase database;
  late _FakeRemote remote;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
  });

  tearDown(() async {
    await database.close();
  });

  SubjectRepositoryImpl repository({bool withRemote = true}) =>
      SubjectRepositoryImpl(
        dao: () => SubjectsDao(database),
        remote: withRemote ? remote : null,
        currentUserId: () => 'uid-1',
      );

  group('Chỉ lưu trên máy', () {
    test('thêm, sửa, xoá môn học', () async {
      final repo = repository(withRemote: false);
      await repo.createSubject(_subject('s1', 'Toan', DateTime(2026, 11, 1)));
      await repo.updateSubject(_subject('s1', 'Toán', DateTime(2026, 11, 2)));
      expect((await repo.watchSubjects().first).single.name, 'Toán');

      await repo.deleteSubject('s1');
      expect(await repo.watchSubjects().first, isEmpty);
    });

    test('sửa hoặc xoá môn không tồn tại báo lỗi', () async {
      final repo = repository(withRemote: false);
      expect(
        () => repo.updateSubject(_subject('x', 'X', DateTime(2026, 11, 1))),
        throwsA(isA<DatabaseFailure>()),
      );
      expect(() => repo.deleteSubject('x'), throwsA(isA<DatabaseFailure>()));
    });

    test('không có máy chủ thì đồng bộ không làm gì', () async {
      await repository(withRemote: false).syncWithServer();
    });
  });

  group('Đồng bộ với máy chủ', () {
    test('thêm, sửa, xoá môn thì đẩy lên máy chủ', () async {
      final repo = repository();
      await repo.createSubject(_subject('s1', 'Toán', DateTime(2026, 11, 1)));
      expect(remote.saved['s1']!.name, 'Toán');

      await repo.deleteSubject('s1');
      expect(remote.saved['s1']!.isDeleted, isTrue);
    });

    test('mất mạng vẫn lưu trên máy và báo chưa đồng bộ', () async {
      final repo = repository();
      remote.offline = true;

      await expectLater(
        repo.createSubject(_subject('s1', 'Toán', DateTime(2026, 11, 1))),
        throwsA(isA<DatabaseFailure>()),
      );
      expect((await repo.watchSubjects().first).single.name, 'Toán');

      // Có mạng lại: môn chỉ có trên máy được đẩy lên.
      remote.offline = false;
      await repo.syncWithServer();
      expect(remote.saved.keys, <String>['s1']);
    });

    test('bản mới hơn thắng khi đối chiếu', () async {
      final repo = repository(withRemote: false);
      await repo.createSubject(
        _subject('a', 'Cũ trên máy', DateTime(2026, 11, 1)),
      );
      await repo.createSubject(
        _subject('b', 'Mới trên máy', DateTime(2026, 11, 5)),
      );
      remote.saved['a'] = _subject(
        'a',
        'Mới trên máy chủ',
        DateTime(2026, 11, 3),
      );
      remote.saved['b'] = _subject(
        'b',
        'Cũ trên máy chủ',
        DateTime(2026, 11, 2),
      );
      remote.saved['c'] = _subject(
        'c',
        'Chỉ có trên máy chủ',
        DateTime(2026, 11, 2),
      );

      await repository().syncWithServer();

      final names = (await repo.watchSubjects().first).map(
        (Subject s) => s.name,
      );
      expect(
        names,
        containsAll(<String>[
          'Mới trên máy chủ',
          'Mới trên máy',
          'Chỉ có trên máy chủ',
        ]),
      );
      expect(remote.saved['b']!.name, 'Mới trên máy');
    });

    test('môn bị xoá ở máy khác thì ẩn trên máy này', () async {
      final repo = repository(withRemote: false);
      await repo.createSubject(_subject('a', 'Toán', DateTime(2026, 11, 1)));
      remote.saved['a'] = _subject(
        'a',
        'Toán',
        DateTime(2026, 11, 2),
      ).copyWith(deletedAt: DateTime(2026, 11, 2));

      await repository().syncWithServer();

      expect(await repo.watchSubjects().first, isEmpty);
    });

    test('lỗi mạng khi đối chiếu được báo bằng DatabaseFailure', () async {
      remote.offline = true;
      expect(repository().syncWithServer, throwsA(isA<DatabaseFailure>()));
    });
  });

  test('ánh xạ dòng Supabase và payload gửi lên', () {
    final subject = _subject('s1', 'Toán', DateTime.utc(2026, 11, 2));
    final json = subjectToRemoteJson(userId: 'uid-1', subject: subject);
    expect(json['user_id'], 'uid-1');
    expect(json['deleted_at'], isNull);

    final back = subjectFromRemoteRow(json);
    expect(back.name, 'Toán');
    expect(back.color, '#43A047');
    expect(back.updatedAt.toUtc(), DateTime.utc(2026, 11, 2));
  });
}
