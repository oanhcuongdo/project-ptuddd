import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/features/summary/domain/entities/note_summary.dart';
import 'package:smart_note/features/summary/domain/entities/summary_mode.dart';
import 'package:smart_note/features/summary/domain/repositories/summary_repository.dart';
import 'package:smart_note/features/summary/presentation/pages/summary_page.dart';

class _FakeSummaryRepository implements SummaryRepository {
  _FakeSummaryRepository(this._handler);

  final Future<NoteSummary> Function(SummaryMode mode) _handler;
  int calls = 0;
  SummaryMode? lastMode;

  @override
  Future<NoteSummary> summarize({
    required String noteId,
    required String title,
    required String content,
    required SummaryMode mode,
  }) {
    calls++;
    lastMode = mode;
    return _handler(mode);
  }
}

Widget _page(
  SummaryRepository repository, {
  String content = 'Đạo hàm mô tả tốc độ thay đổi. Tích phân tính diện tích.',
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: SummaryPage(
      noteId: 'note-1',
      noteTitle: 'Giải tích – Chương 3',
      noteContent: content,
      repository: repository,
    ),
  );
}

void main() {
  testWidgets('hiện trạng thái chờ rồi kết quả tóm tắt', (tester) async {
    final completer = Completer<NoteSummary>();
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) => completer.future,
    );

    await tester.pumpWidget(_page(repository));
    await tester.pump();

    expect(find.text('Đang tóm tắt, thường dưới 15 giây…'), findsOneWidget);

    completer.complete(
      NoteSummary(
        noteId: 'note-1',
        mode: SummaryMode.short,
        content: 'Tóm tắt: đạo hàm và tích phân.',
        createdAt: DateTime(2026, 11, 25),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kết quả tóm tắt'), findsOneWidget);
    expect(find.text('Tóm tắt: đạo hàm và tích phân.'), findsOneWidget);
    expect(find.textContaining('xong trong'), findsOneWidget);
  });

  testWidgets('lỗi mạng hiện thông báo và nút thử lại', (tester) async {
    var calls = 0;
    final repository = _FakeSummaryRepository((SummaryMode mode) async {
      calls++;
      throw const AiFailure(
        'Không kết nối được máy chủ tóm tắt. Kiểm tra mạng rồi thử lại.',
        kind: AiFailureKind.network,
      );
    });

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();

    expect(find.text('Không kết nối được'), findsOneWidget);
    expect(find.textContaining('Kiểm tra mạng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('ghi chú rỗng hiện trạng thái empty', (tester) async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => throw StateError('không được gọi'),
    );

    await tester.pumpWidget(_page(repository, content: '   '));
    await tester.pumpAndSettle();

    expect(find.text('Ghi chú chưa có nội dung'), findsOneWidget);
    expect(repository.calls, 0);
  });

  testWidgets('chọn kiểu gạch ý chính đổi gợi ý dưới tiêu đề', (tester) async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => throw StateError('không được gọi'),
    );

    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gạch ý chính'));
    await tester.pumpAndSettle();

    expect(find.text('Gạch đầu dòng từng ý chính.'), findsOneWidget);
  });
}
