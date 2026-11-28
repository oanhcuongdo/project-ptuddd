import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/summary_mode.dart';
import '../../domain/usecases/summarize_note.dart';
import 'summary_state.dart';

/// Điều khiển màn tóm tắt AI: chọn kiểu, gọi use case, giữ kết quả và lỗi.
///
/// Widget không gọi HTTP trực tiếp — mọi thứ đi qua cubit này.
class SummaryCubit extends Cubit<SummaryState> {
  SummaryCubit({
    required this.summarizeNote,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
  }) : super(const SummaryState());

  final SummarizeNote summarizeNote;
  final String noteId;
  final String noteTitle;
  final String noteContent;

  /// Gọi tóm tắt theo [SummaryState.mode] hiện tại.
  Future<void> summarize() async {
    if (state.isLoading) {
      return;
    }
    if (noteContent.trim().isEmpty) {
      emit(
        state.copyWith(
          status: SummaryStatus.empty,
          result: null,
          errorMessage: null,
          isNetworkError: false,
          elapsed: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SummaryStatus.loading,
        result: null,
        errorMessage: null,
        isNetworkError: false,
        elapsed: null,
      ),
    );

    final stopwatch = Stopwatch()..start();
    try {
      final result = await summarizeNote(
        noteId: noteId,
        title: noteTitle,
        content: noteContent,
        mode: state.mode,
      );
      stopwatch.stop();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: SummaryStatus.success,
          result: result,
          errorMessage: null,
          isNetworkError: false,
          elapsed: stopwatch.elapsed,
        ),
      );
    } on Failure catch (failure) {
      stopwatch.stop();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: SummaryStatus.failure,
          result: null,
          errorMessage: failure.message,
          isNetworkError: failure is AiFailure && failure.isNetworkError,
          elapsed: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      stopwatch.stop();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: SummaryStatus.failure,
          result: null,
          errorMessage: 'Không tóm tắt được ghi chú: $error',
          isNetworkError: false,
          elapsed: stopwatch.elapsed,
        ),
      );
    }
  }

  /// Đổi kiểu tóm tắt; nếu đã có kết quả thì tóm tắt lại ngay.
  Future<void> selectMode(SummaryMode mode) async {
    if (mode == state.mode) {
      return;
    }
    final shouldRerun = state.status == SummaryStatus.success;
    emit(
      state.copyWith(
        mode: mode,
        status: SummaryStatus.idle,
        result: null,
        errorMessage: null,
        isNetworkError: false,
        elapsed: null,
      ),
    );
    if (shouldRerun) {
      await summarize();
    }
  }
}
