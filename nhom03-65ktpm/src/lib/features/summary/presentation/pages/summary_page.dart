import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/repositories/summary_repository.dart';
import '../../domain/usecases/summarize_note.dart';
import '../bloc/summary_cubit.dart';
import '../bloc/summary_state.dart';
import '../widgets/summary_mode_labels.dart';
import '../widgets/summary_mode_selector.dart';
import '../widgets/summary_result_card.dart';

/// Màn kết quả tóm tắt AI (#12).
///
/// Nhận chuỗi thuần (`noteId`/`noteTitle`/`noteContent`) thay vì entity `Note`
/// để không import chéo feature. Bố cục theo Notion (vùng đọc rộng, tiêu đề
/// tách khỏi nội dung) — `docs/ui_ux.md` mục 9.
class SummaryPage extends StatelessWidget {
  const SummaryPage({
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.repository,
    this.isDemo = false,
    super.key,
  });

  final String noteId;
  final String noteTitle;
  final String noteContent;
  final SummaryRepository repository;
  final bool isDemo;

  static Route<void> route({
    required String noteId,
    required String noteTitle,
    required String noteContent,
    required SummaryRepository repository,
    bool isDemo = false,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => SummaryPage(
        noteId: noteId,
        noteTitle: noteTitle,
        noteContent: noteContent,
        repository: repository,
        isDemo: isDemo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SummaryCubit>(
      create: (_) => SummaryCubit(
        summarizeNote: SummarizeNote(repository),
        noteId: noteId,
        noteTitle: noteTitle,
        noteContent: noteContent,
      )..summarize(),
      child: _SummaryView(noteTitle: noteTitle, isDemo: isDemo),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.noteTitle, required this.isDemo});

  final String noteTitle;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryCubit, SummaryState>(
      builder: (BuildContext context, SummaryState state) {
        final cubit = context.read<SummaryCubit>();
        return AppScaffold(
          eyebrow: isDemo ? 'Tóm tắt demo trên thiết bị' : 'Tóm tắt AI',
          title: noteTitle,
          subtitle: state.mode.hint,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SummaryModeSelector(
                  selected: state.mode,
                  onSelected: cubit.selectMode,
                ),
              ),
              Expanded(child: _buildBody(state, cubit)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: AppPrimaryButton(
                  label: state.status == SummaryStatus.success
                      ? 'Tóm tắt lại'
                      : 'Tóm tắt',
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ? null : cubit.summarize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(SummaryState state, SummaryCubit cubit) {
    switch (state.status) {
      case SummaryStatus.loading:
        return Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _WaitingLabel(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: LoadingView(itemCount: 3)),
          ],
        );
      case SummaryStatus.empty:
        return const EmptyState(
          icon: Icons.edit_note_rounded,
          title: 'Ghi chú chưa có nội dung',
          message: 'Quay lại viết thêm nội dung rồi thử tóm tắt lại.',
        );
      case SummaryStatus.failure:
        return ErrorView(
          icon: state.isNetworkError
              ? Icons.wifi_off_rounded
              : Icons.error_outline_rounded,
          title: state.isNetworkError
              ? 'Không kết nối được'
              : 'Không tóm tắt được',
          message: state.errorMessage ?? 'Đã xảy ra lỗi khi tóm tắt ghi chú.',
          onRetry: cubit.summarize,
        );
      case SummaryStatus.success:
        final result = state.result;
        if (result == null) {
          return const EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'Chưa có kết quả',
            message: 'Bấm Tóm tắt để tạo bản tóm tắt cho ghi chú này.',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SummaryResultCard(summary: result, elapsed: state.elapsed),
        );
      case SummaryStatus.idle:
        return const EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'Chọn kiểu tóm tắt',
          message: 'Ngắn, dài hoặc gạch ý chính — rồi bấm Tóm tắt.',
        );
    }
  }
}

class _WaitingLabel extends StatelessWidget {
  const _WaitingLabel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Đang tóm tắt, thường dưới 15 giây…',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
