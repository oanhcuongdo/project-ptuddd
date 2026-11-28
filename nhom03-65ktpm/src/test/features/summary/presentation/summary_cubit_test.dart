import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/summary/domain/entities/note_summary.dart';
import 'package:smart_note/features/summary/domain/entities/summary_mode.dart';
import 'package:smart_note/features/summary/domain/repositories/summary_repository.dart';
import 'package:smart_note/features/summary/domain/usecases/summarize_note.dart';
import 'package:smart_note/features/summary/presentation/bloc/summary_cubit.dart';
import 'package:smart_note/features/summary/presentation/bloc/summary_state.dart';

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

NoteSummary _summary(SummaryMode mode) {
  return NoteSummary(
    noteId: 'note-1',
    mode: mode,
    content: 'Bản tóm tắt ${mode.name}',
    createdAt: DateTime(2026, 11, 25),
  );
}

SummaryCubit _cubit(
  _FakeSummaryRepository repository, {
  String content = 'Nội dung ghi chú đủ dài để tóm tắt.',
}) {
  return SummaryCubit(
    summarizeNote: SummarizeNote(repository),
    noteId: 'note-1',
    noteTitle: 'Giải tích',
    noteContent: content,
  );
}

Future<List<SummaryState>> _collect(SummaryCubit cubit) async {
  final states = <SummaryState>[];
  final subscription = cubit.stream.listen(states.add);
  await cubit.summarize();
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return states;
}

void main() {
  test('tóm tắt thành công: loading rồi success', () async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => _summary(mode),
    );
    final cubit = _cubit(repository);

    final states = await _collect(cubit);

    expect(states.first.status, SummaryStatus.loading);
    expect(states.last.status, SummaryStatus.success);
    expect(states.last.result?.content, 'Bản tóm tắt short');
    expect(states.last.elapsed, isNotNull);
    expect(repository.calls, 1);
    expect(cubit.state.status, SummaryStatus.success);
  });

  test('lỗi mạng giữ thông báo tiếng Việt và cờ isNetworkError', () async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => throw const AiFailure(
        'Không kết nối được máy chủ tóm tắt.',
        kind: AiFailureKind.network,
      ),
    );
    final cubit = _cubit(repository);

    final states = await _collect(cubit);

    expect(states.last.status, SummaryStatus.failure);
    expect(states.last.errorMessage, contains('Không kết nối'));
    expect(states.last.isNetworkError, isTrue);
    expect(states.last.result, isNull);
  });

  test(
    'ghi chú rỗng chuyển sang trạng thái empty, không gọi repository',
    () async {
      final repository = _FakeSummaryRepository(
        (SummaryMode mode) async => _summary(mode),
      );
      final cubit = _cubit(repository, content: '   ');

      final states = await _collect(cubit);

      expect(states.single.status, SummaryStatus.empty);
      expect(repository.calls, 0);
    },
  );

  test('đổi kiểu khi đã có kết quả thì tóm tắt lại theo kiểu mới', () async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => _summary(mode),
    );
    final cubit = _cubit(repository);
    await cubit.summarize();

    await cubit.selectMode(SummaryMode.bullets);
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, 2);
    expect(repository.lastMode, SummaryMode.bullets);
    expect(cubit.state.mode, SummaryMode.bullets);
    expect(cubit.state.result?.mode, SummaryMode.bullets);
  });

  test('đổi kiểu khi chưa có kết quả thì chỉ đổi lựa chọn', () async {
    final repository = _FakeSummaryRepository(
      (SummaryMode mode) async => _summary(mode),
    );
    final cubit = _cubit(repository);

    await cubit.selectMode(SummaryMode.long);

    expect(repository.calls, 0);
    expect(cubit.state.mode, SummaryMode.long);
    expect(cubit.state.status, SummaryStatus.idle);
  });
}
