import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/subjects/domain/entities/classified_note.dart';
import 'package:smart_note/features/subjects/domain/entities/note_filter.dart';

void main() {
  const toan = ClassifiedNote(
    id: 'n1',
    title: 'Đạo hàm',
    subjectId: 'toan',
    tags: <String>['ôn thi', 'bài tập'],
  );
  const van = ClassifiedNote(
    id: 'n2',
    title: 'Bài thơ',
    subjectId: 'van',
    tags: <String>['ôn thi'],
  );
  const trong = ClassifiedNote(id: 'n3', title: 'Việc cần làm');

  group('NoteFilter.matches', () {
    test('bộ lọc rỗng nhận mọi ghi chú', () {
      expect(
        NoteFilter.all.apply(<ClassifiedNote>[toan, van, trong]),
        hasLength(3),
      );
    });

    test('lọc theo môn chỉ nhận ghi chú của môn đó', () {
      const filter = NoteFilter(subjectId: 'toan');
      expect(filter.matches(toan), isTrue);
      expect(filter.matches(van), isFalse);
      expect(filter.matches(trong), isFalse);
    });

    test('chưa phân loại chỉ nhận ghi chú chưa gán môn', () {
      final filter = NoteFilter.all.withUnclassifiedOnly();
      expect(filter.matches(trong), isTrue);
      expect(filter.matches(toan), isFalse);
    });

    test('lọc tag yêu cầu có đủ các tag đã chọn', () {
      final onThi = NoteFilter.all.toggleTag('ôn thi');
      expect(onThi.apply(<ClassifiedNote>[toan, van, trong]), <ClassifiedNote>[
        toan,
        van,
      ]);

      final caHai = onThi.toggleTag('bài tập');
      expect(caHai.apply(<ClassifiedNote>[toan, van, trong]), <ClassifiedNote>[
        toan,
      ]);
    });

    test('kết hợp môn học và tag', () {
      final filter = const NoteFilter(subjectId: 'van').toggleTag('bài tập');
      expect(filter.apply(<ClassifiedNote>[toan, van, trong]), isEmpty);
    });
  });

  group('Thao tác trên bộ lọc', () {
    test('bấm lại một tag thì bỏ tag đó', () {
      final filter = NoteFilter.all.toggleTag('ôn thi').toggleTag('ôn thi');
      expect(filter.isEmpty, isTrue);
    });

    test('đổi môn giữ nguyên các tag đang lọc', () {
      final filter = NoteFilter.all.toggleTag('ôn thi').withSubject('toan');
      expect(filter.subjectId, 'toan');
      expect(filter.tags, <String>{'ôn thi'});
    });

    test('chọn chưa phân loại thì bỏ môn đang chọn', () {
      final filter = const NoteFilter(subjectId: 'toan').withUnclassifiedOnly();
      expect(filter.subjectId, isNull);
      expect(filter.unclassifiedOnly, isTrue);
    });

    test('bỏ lọc tag', () {
      final filter = const NoteFilter(subjectId: 'toan')
          .toggleTag('a')
          .clearTags();
      expect(filter, const NoteFilter(subjectId: 'toan'));
    });

    test('bỏ khỏi bộ lọc môn và tag đã không còn', () {
      final filter = const NoteFilter(subjectId: 'toan')
          .toggleTag('ôn thi')
          .toggleTag('bài tập')
          .retainExisting(<String>{'van'}, <String>{'ôn thi'});
      expect(filter.subjectId, isNull);
      expect(filter.tags, <String>{'ôn thi'});
    });
  });
}
