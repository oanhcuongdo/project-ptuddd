import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/data/sync/note_sync_rules.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';

Note note({
  String id = 'n1',
  String title = 'Ghi chú',
  String content = 'nội dung',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final DateTime created = DateTime(2026, 11, 20, 8);
  return Note(
    id: id,
    title: title,
    content: content,
    kind: NoteKind.note,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    deletedAt: deletedAt,
  );
}

void main() {
  final DateTime t1 = DateTime(2026, 11, 25, 9);
  final DateTime t2 = DateTime(2026, 11, 25, 10);

  group('notesToApplyLocally', () {
    test('bản trên máy chủ mới hơn thì ghi đè xuống máy', () {
      final result = notesToApplyLocally(
        local: <Note>[note(title: 'cũ', updatedAt: t1)],
        remote: <Note>[note(title: 'mới', updatedAt: t2)],
      );

      expect(result, hasLength(1));
      expect(result.single.title, 'mới');
    });

    test('bản trên máy mới hơn thì KHÔNG bị ghi đè', () {
      final result = notesToApplyLocally(
        local: <Note>[note(title: 'máy', updatedAt: t2)],
        remote: <Note>[note(title: 'chậm', updatedAt: t1)],
      );

      expect(result, isEmpty);
    });

    test('cùng mốc thời gian, nội dung khác nhau thì máy chủ thắng', () {
      final result = notesToApplyLocally(
        local: <Note>[note(title: 'máy', updatedAt: t1)],
        remote: <Note>[note(title: 'chủ', updatedAt: t1)],
      );

      expect(result.single.title, 'chủ');
    });

    test('cùng mốc thời gian, cùng nội dung thì không ghi gì', () {
      final result = notesToApplyLocally(
        local: <Note>[note(updatedAt: t1)],
        remote: <Note>[note(updatedAt: t1)],
      );

      expect(result, isEmpty);
    });

    test('ghi chú chỉ có trên máy chủ thì được thêm xuống máy', () {
      final result = notesToApplyLocally(
        local: const <Note>[],
        remote: <Note>[note(id: 'remote-only', updatedAt: t1)],
      );

      expect(result.single.id, 'remote-only');
    });

    test('tombstone mới hơn thì xoá ghi chú trên máy (không hồi sinh)', () {
      final result = notesToApplyLocally(
        local: <Note>[note(updatedAt: t1)],
        remote: <Note>[note(updatedAt: t2, deletedAt: t2)],
      );

      expect(result.single.deletedAt, t2);
    });
  });

  group('notesToPush', () {
    test('ghi chú mới trên máy được đẩy lên', () {
      final result = notesToPush(
        local: <Note>[note(id: 'local-only', updatedAt: t1)],
        remote: const <Note>[],
      );

      expect(result.single.id, 'local-only');
    });

    test('bản máy mới hơn được đẩy lên', () {
      final result = notesToPush(
        local: <Note>[note(title: 'máy', updatedAt: t2)],
        remote: <Note>[note(title: 'chủ', updatedAt: t1)],
      );

      expect(result.single.title, 'máy');
    });

    test('bản máy cũ hơn thì không đẩy ngược lên', () {
      final result = notesToPush(
        local: <Note>[note(title: 'máy', updatedAt: t1)],
        remote: <Note>[note(title: 'chủ', updatedAt: t2)],
      );

      expect(result, isEmpty);
    });

    test('hoà mốc thời gian thì không đẩy để tránh ping-pong', () {
      final result = notesToPush(
        local: <Note>[note(title: 'máy', updatedAt: t1)],
        remote: <Note>[note(title: 'chủ', updatedAt: t1)],
      );

      expect(result, isEmpty);
    });
  });

  test('hai chiều không làm mất dữ liệu: mỗi bản mới nhất thắng một lần', () {
    final List<Note> local = <Note>[
      note(id: 'a', title: 'A-máy', updatedAt: t2),
      note(id: 'b', title: 'B-cũ', updatedAt: t1),
    ];
    final List<Note> remote = <Note>[
      note(id: 'a', title: 'A-chủ', updatedAt: t1),
      note(id: 'b', title: 'B-chủ', updatedAt: t2),
      note(id: 'c', title: 'C-chủ', updatedAt: t1),
    ];

    expect(
      notesToPush(local: local, remote: remote).map((Note n) => n.id),
      <String>['a'],
    );
    expect(
      notesToApplyLocally(local: local, remote: remote).map((Note n) => n.id),
      <String>['b', 'c'],
    );
  });
}
