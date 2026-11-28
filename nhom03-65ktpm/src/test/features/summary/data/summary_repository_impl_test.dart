import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/summary/data/datasources/remote/ai_summary_remote_data_source.dart';
import 'package:smart_note/features/summary/data/repositories/summary_repository_impl.dart';
import 'package:smart_note/features/summary/domain/entities/summary_mode.dart';

class _FakeDataSource implements AiSummaryRemoteDataSource {
  _FakeDataSource(this._handler);

  final Future<String> Function() _handler;
  int calls = 0;
  String? lastText;
  String? lastTitle;
  String? lastNoteId;
  SummaryMode? lastMode;

  @override
  Future<String> requestSummary({
    required String noteId,
    required String title,
    required String text,
    required SummaryMode mode,
  }) {
    calls++;
    lastNoteId = noteId;
    lastTitle = title;
    lastText = text;
    lastMode = mode;
    return _handler();
  }
}

SummaryRepositoryImpl _repository(Future<String> Function() handler) {
  return SummaryRepositoryImpl(_FakeDataSource(handler));
}

void main() {
  test('đóng gói kết quả thành NoteSummary và chuyển đúng tham số', () async {
    final dataSource = _FakeDataSource(() async => '  Ý chính.  ');
    final repository = SummaryRepositoryImpl(dataSource);

    final summary = await repository.summarize(
      noteId: 'note-1',
      title: 'Giải tích',
      content: 'Nội dung dài',
      mode: SummaryMode.bullets,
    );

    expect(summary.noteId, 'note-1');
    expect(summary.mode, SummaryMode.bullets);
    expect(summary.content, 'Ý chính.');
    expect(summary.wordCount, 2);
    expect(dataSource.lastMode, SummaryMode.bullets);
    expect(dataSource.lastTitle, 'Giải tích');
    expect(dataSource.lastText, 'Nội dung dài');
  });

  test('kết quả rỗng thành AiFailure badResponse', () async {
    final repository = _repository(() async => '   ');

    await expectLater(
      repository.summarize(
        noteId: 'n',
        title: 't',
        content: 'c',
        mode: SummaryMode.short,
      ),
      throwsA(
        isA<AiFailure>().having(
          (AiFailure failure) => failure.kind,
          'kind',
          AiFailureKind.badResponse,
        ),
      ),
    );
  });

  test('AiFailure từ data source được giữ nguyên', () async {
    final repository = _repository(() async {
      throw const AiFailure(
        'Hết lượt gọi AI.',
        kind: AiFailureKind.quotaExceeded,
      );
    });

    await expectLater(
      repository.summarize(
        noteId: 'n',
        title: 't',
        content: 'c',
        mode: SummaryMode.short,
      ),
      throwsA(
        isA<AiFailure>().having(
          (AiFailure failure) => failure.kind,
          'kind',
          AiFailureKind.quotaExceeded,
        ),
      ),
    );
  });

  test('lỗi lạ được bọc thành UnexpectedFailure', () async {
    final repository = _repository(() async {
      throw StateError('boom');
    });

    await expectLater(
      repository.summarize(
        noteId: 'n',
        title: 't',
        content: 'c',
        mode: SummaryMode.short,
      ),
      throwsA(isA<UnexpectedFailure>()),
    );
  });
}
