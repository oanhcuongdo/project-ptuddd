import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/subjects/domain/entities/classified_note.dart';
import 'package:smart_note/features/subjects/domain/entities/note_filter.dart';
import 'package:smart_note/features/subjects/domain/entities/subject.dart';
import 'package:smart_note/features/subjects/presentation/bloc/subjects_cubit.dart';
import 'package:smart_note/features/subjects/presentation/pages/classified_notes_page.dart';
import 'package:smart_note/features/subjects/presentation/widgets/note_filter_bar.dart';

import '../../../support/fake_classification_repositories.dart';

final DateTime _created = DateTime(2026, 11, 20);
final Subject _toan = Subject(
  id: 'toan',
  name: 'Toán',
  color: '#2F6BFF',
  createdAt: _created,
  updatedAt: _created,
);
final Subject _van = Subject(
  id: 'van',
  name: 'Ngữ văn',
  color: '#E53935',
  createdAt: _created,
  updatedAt: _created,
);

const List<ClassifiedNote> _notes = <ClassifiedNote>[
  ClassifiedNote(
    id: 'n1',
    title: 'Đạo hàm',
    subjectId: 'toan',
    tags: <String>['ôn thi', 'bài tập'],
  ),
  ClassifiedNote(
    id: 'n2',
    title: 'Phân tích bài thơ',
    subjectId: 'van',
    tags: <String>['ôn thi'],
  ),
  ClassifiedNote(id: 'n3', title: 'Việc cần làm'),
];

class _Harness {
  _Harness()
    : subjects = FakeSubjectRepository(<Subject>[_toan, _van]),
      notes = FakeNoteClassificationRepository(_notes);

  final FakeSubjectRepository subjects;
  final FakeNoteClassificationRepository notes;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SubjectsCubit>(
          create: (_) => SubjectsCubit(subjects, notes)..load(),
          child: const ClassifiedNotesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Gỡ widget để cubit huỷ subscription, rồi đóng stream giả.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await subjects.dispose();
    await notes.dispose();
  }
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey<String>(key)));
  await tester.pumpAndSettle();
}

void main() {
  group('NoteFilterBar', () {
    testWidgets('hiện chip của mọi môn học và tag, bấm chip trả bộ lọc mới', (
      WidgetTester tester,
    ) async {
      NoteFilter? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteFilterBar(
              subjects: <Subject>[_toan, _van],
              tags: const <String>['ôn thi'],
              filter: NoteFilter.all,
              onChanged: (NoteFilter value) => changed = value,
            ),
          ),
        ),
      );

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Toán'), findsOneWidget);
      expect(find.text('Chưa phân loại'), findsOneWidget);
      expect(find.text('#ôn thi'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('subject-filter-toan')),
      );
      expect(changed, const NoteFilter(subjectId: 'toan'));

      await tester.tap(find.byKey(const ValueKey<String>('tag-filter-ôn thi')));
      expect(changed, const NoteFilter(tags: <String>{'ôn thi'}));
    });
  });

  group('Lọc danh sách ghi chú', () {
    testWidgets('mặc định hiện tất cả, lọc theo môn và chưa phân loại', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      expect(find.text('Đạo hàm'), findsOneWidget);
      expect(find.text('Phân tích bài thơ'), findsOneWidget);
      expect(find.text('Việc cần làm'), findsOneWidget);

      await _tapKey(tester, 'subject-filter-van');
      expect(find.text('Phân tích bài thơ'), findsOneWidget);
      expect(find.text('Đạo hàm'), findsNothing);
      expect(find.text('Việc cần làm'), findsNothing);

      await _tapKey(tester, 'subject-filter-none');
      expect(find.text('Việc cần làm'), findsOneWidget);
      expect(find.text('Phân tích bài thơ'), findsNothing);

      await harness.dispose(tester);
    });

    testWidgets('lọc theo nhiều tag, báo trống và bỏ lọc tag', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);

      await _tapKey(tester, 'tag-filter-ôn thi');
      expect(find.text('Đạo hàm'), findsOneWidget);
      expect(find.text('Phân tích bài thơ'), findsOneWidget);
      expect(find.text('Việc cần làm'), findsNothing);

      await _tapKey(tester, 'tag-filter-bài tập');
      expect(find.text('Đạo hàm'), findsOneWidget);
      expect(find.text('Phân tích bài thơ'), findsNothing);

      await _tapKey(tester, 'subject-filter-van');
      expect(find.text('Không có ghi chú phù hợp.'), findsOneWidget);

      await _tapKey(tester, 'tag-filter-clear');
      expect(find.text('Phân tích bài thơ'), findsOneWidget);

      await harness.dispose(tester);
    });
  });

  group('Gán môn học và tag', () {
    testWidgets('chọn môn và thêm tag mới cho ghi chú', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);

      await tester.tap(find.text('Việc cần làm'));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'sheet-subject-toan');
      await tester.enterText(
        find.byKey(const ValueKey<String>('sheet-new-tag')),
        '#kiểm tra',
      );
      await _tapKey(tester, 'sheet-add-tag');
      await _tapKey(tester, 'sheet-save');

      final note = harness.notes.byId('n3');
      expect(note.subjectId, 'toan');
      expect(note.tags, <String>['kiểm tra']);
      expect(find.text('#kiểm tra'), findsWidgets);

      await harness.dispose(tester);
    });

    testWidgets('bỏ gán môn học và tag của ghi chú', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);

      await tester.tap(find.text('Đạo hàm'));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'sheet-subject-none');
      await _tapKey(tester, 'sheet-tag-ôn thi');
      await _tapKey(tester, 'sheet-save');

      final note = harness.notes.byId('n1');
      expect(note.subjectId, isNull);
      expect(note.tags, <String>['bài tập']);

      await harness.dispose(tester);
    });
  });

  group('Quản lý môn học và tag', () {
    testWidgets('thêm môn học mới, báo lỗi khi trùng tên', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      await _tapKey(tester, 'open-subject-manager');

      await _tapKey(tester, 'add-subject');
      await tester.enterText(
        find.byKey(const ValueKey<String>('name-field')),
        'Tiếng Anh',
      );
      await _tapKey(tester, 'name-save');
      expect(find.text('Tiếng Anh'), findsOneWidget);

      await _tapKey(tester, 'add-subject');
      await tester.enterText(
        find.byKey(const ValueKey<String>('name-field')),
        'toán',
      );
      await _tapKey(tester, 'name-save');
      expect(find.text('Môn học "toán" đã có.'), findsOneWidget);

      await harness.dispose(tester);
    });

    testWidgets('xoá môn học thì ghi chú về chưa phân loại', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      await _tapKey(tester, 'open-subject-manager');

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('subject-toan')),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      await _tapKey(tester, 'confirm-delete');

      expect(find.byKey(const ValueKey<String>('subject-toan')), findsNothing);
      expect(harness.notes.byId('n1').subjectId, isNull);

      await harness.dispose(tester);
    });

    testWidgets('đổi tên và xoá tag trên mọi ghi chú', (
      WidgetTester tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      await _tapKey(tester, 'open-subject-manager');
      await tester.tap(find.text('Tag'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('#ôn thi'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('name-field')),
        'ôn tập',
      );
      await _tapKey(tester, 'name-save');
      expect(harness.notes.byId('n2').tags, <String>['ôn tập']);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('tag-ôn tập')),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      await _tapKey(tester, 'confirm-delete');
      expect(harness.notes.byId('n1').tags, <String>['bài tập']);
      expect(harness.notes.byId('n2').tags, isEmpty);

      await harness.dispose(tester);
    });
  });
}
