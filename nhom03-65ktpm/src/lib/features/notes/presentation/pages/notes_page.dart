import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import '../services/word_export_service.dart';
import '../widgets/note_card.dart';
import '../widgets/sync_status_indicator.dart';
import 'note_editor_page.dart';
import 'quiz_page.dart';

/// Thư viện ghi chú theo mẫu bảng chủ đề đã duyệt.
class NotesPage extends StatefulWidget {
  const NotesPage({
    required this.dependencies,
    this.actions = const <Widget>[],
    super.key,
  });

  final AppDependencies dependencies;

  /// Widget hành động trong vùng bộ lọc và công cụ, do nơi điều hướng truyền vào (ví dụ nút
  /// đăng xuất). Nhờ vậy feature notes không phải import feature auth.
  final List<Widget> actions;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final Set<String> _selectedIds = <String>{};
  bool _isGrid = true;
  bool _showTools = false;
  String _query = '';
  String? _selectedTag;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  List<String> _tags(List<Note> notes) {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags.where((String tag) => tag.trim().isNotEmpty));
    }
    return tags.toList()..sort();
  }

  List<Note> _filter(List<Note> notes) {
    final keyword = _query.trim().toLowerCase();
    return notes.where((Note note) {
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }
      if (keyword.isEmpty) {
        return true;
      }
      final haystack = <String>[
        note.title,
        note.content,
        ...note.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(keyword);
    }).toList();
  }

  String _subtitle(NotesState state, int shown) {
    if (state.isLoading || state.status == NotesStatus.failure) {
      return 'Đang đồng bộ ghi chú của bạn';
    }
    if (state.notes.isEmpty) {
      return 'Sẵn sàng cho ghi chú đầu tiên';
    }
    if (_query.trim().isNotEmpty || _selectedTag != null) {
      return '$shown/${state.notes.length} ghi chú phù hợp';
    }
    return '${state.notes.length} ghi chú';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotesCubit>();
    return Theme(
      data: AppTheme.notes(Theme.of(context)),
      child: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final filtered = _filter(state.notes);
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      NotesLayout.gutter,
                      AppSpacing.xl,
                      NotesLayout.gutter,
                      NotesLayout.gap,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _header(context, state, filtered.length, cubit),
                    ),
                  ),
                  ..._bodySlivers(context, state, filtered, cubit),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(
    BuildContext context,
    NotesState state,
    int count,
    NotesCubit cubit,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tags = _tags(state.notes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectionMode ? '${_selectedIds.length} đã chọn' : 'Ghi chú',
                style: _selectionMode
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineLarge,
              ),
            ),
            if (_selectionMode) ...[
              IconButton(
                tooltip: 'Xuất Word',
                icon: const Icon(Icons.description_outlined),
                onPressed: () => _exportSelected(context),
              ),
              IconButton(
                tooltip: 'Huỷ chọn',
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selectedIds.clear),
              ),
            ] else
              IconButton.filled(
                tooltip: 'Tạo ghi chú',
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(NotesLayout.controlHeight),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: () => _showCreateSheet(context, cubit),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Visibility(
          visible: !_selectionMode,
          maintainState: true,
          child: AppSearchBar(
            dense: true,
            hintText: 'Tìm trong ghi chú',
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (_selectionMode)
          const Text('Chọn thêm hoặc xuất tài liệu Word')
        else ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Tooltip(
                    message: 'Bộ lọc và công cụ',
                    child: InkWell(
                      onTap: () => setState(() => _showTools = !_showTools),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _selectedTag ?? 'Theo chủ đề',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              _showTools
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: AppSpacing.lg,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _subtitle(state, count),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SyncStatusIndicator(
                status: state.syncStatus,
                message: state.syncMessage,
              ),
            ],
          ),
          if (_showTools) ...[
            if (tags.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _tagChip(label: 'Tất cả', tag: null),
                  for (final tag in tags) _tagChip(label: tag, tag: tag),
                ],
              ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trắc nghiệm từ ghi chú',
                  icon: const Icon(Icons.quiz_outlined),
                  onPressed: () => _openQuiz(context, cubit),
                ),
                IconButton(
                  tooltip: _isGrid ? 'Xem dạng danh sách' : 'Xem dạng lưới',
                  icon: Icon(
                    _isGrid
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                  ),
                  onPressed: () => setState(() => _isGrid = !_isGrid),
                ),
                ...widget.actions,
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _tagChip({required String label, required String? tag}) => ChoiceChip(
    label: Text(label),
    selected: _selectedTag == tag,
    showCheckmark: false,
    onSelected: (_) => setState(() {
      _selectedTag = tag;
      _showTools = false;
    }),
  );

  List<Widget> _bodySlivers(
    BuildContext context,
    NotesState state,
    List<Note> filtered,
    NotesCubit cubit,
  ) {
    final Widget? status = switch (state) {
      _ when state.isLoading => const LoadingView(),
      _ when state.status == NotesStatus.failure => ErrorView(
        message: state.errorMessage ?? 'Đã xảy ra lỗi khi đọc ghi chú.',
        onRetry: cubit.load,
      ),
      _ when state.notes.isEmpty => EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Chưa có ghi chú nào',
        message: 'Ghi chú bạn tạo sẽ xuất hiện tại đây.',
        actionLabel: 'Tạo ghi chú',
        onAction: () => _showCreateSheet(context, cubit),
      ),
      _ when filtered.isEmpty => const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy ghi chú',
        message: 'Thử từ khoá khác hoặc bỏ bộ lọc môn học.',
      ),
      _ => null,
    };
    if (status != null) {
      return [SliverFillRemaining(child: status)];
    }
    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: NotesLayout.gutter,
    );
    if (!_isGrid) {
      return [
        SliverPadding(
          padding: horizontalPadding,
          sliver: SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: NotesLayout.gap),
            itemBuilder: (_, index) => _card(filtered[index], cubit),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ];
    }
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 840
        ? 4
        : (width >= 600 ? 3 : (width < 310 || textScale > 1.5 ? 1 : 2));
    final extraHeight =
        (NotesLayout.tileHeight - NotesLayout.cardPadding * 2) *
        (textScale - 1).clamp(0.0, double.infinity);
    return [
      SliverPadding(
        padding: horizontalPadding,
        sliver: SliverGrid.builder(
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: NotesLayout.gap,
            mainAxisSpacing: NotesLayout.gap,
            mainAxisExtent: NotesLayout.tileHeight + extraHeight,
          ),
          itemBuilder: (_, index) =>
              _card(filtered[index], cubit, compact: true),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
    ];
  }

  Widget _card(Note note, NotesCubit cubit, {bool compact = false}) {
    final selected = _selectedIds.contains(note.id);
    return NoteCard(
      key: ValueKey(note.id),
      note: note,
      compact: compact,
      selected: selected,
      onLongPress: () => setState(() => _selectedIds.add(note.id)),
      onTap: () {
        if (!_selectionMode) {
          _openEditor(cubit, note);
        } else {
          setState(() {
            if (selected) {
              _selectedIds.remove(note.id);
            } else {
              _selectedIds.add(note.id);
            }
          });
        }
      },
    );
  }

  void _openEditor(NotesCubit cubit, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          cubit: cubit,
          note: note,
          summaryRepository: widget.dependencies.summaryRepository,
          isSummaryDemo: widget.dependencies.aiClient.isDemo,
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context, NotesCubit cubit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizPage(
          notesCubit: cubit,
          scoresDao: widget.dependencies.quizScoresDao,
          aiClient: widget.dependencies.aiClient,
        ),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, NotesCubit cubit) async {
    final navigator = Navigator.of(context);
    final kind = await showModalBottomSheet<NoteKind>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('Ghi chú mới'),
              onTap: () => navigator.pop(NoteKind.note),
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Viết nhật ký hằng ngày'),
              onTap: () => navigator.pop(NoteKind.diary),
            ),
          ],
        ),
      ),
    );
    if (!mounted || kind == null) {
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          cubit: cubit,
          initialKind: kind,
          summaryRepository: widget.dependencies.summaryRepository,
          isSummaryDemo: widget.dependencies.aiClient.isDemo,
        ),
      ),
    );
  }

  Future<void> _exportSelected(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = context
        .read<NotesCubit>()
        .state
        .notes
        .where((Note note) => _selectedIds.contains(note.id))
        .toList();
    if (selected.isEmpty) {
      return;
    }
    try {
      final path = await WordExportService().exportNotes(selected);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu Word:\n$path')),
      );
      setState(_selectedIds.clear);
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Không xuất được Word: $error')),
      );
    }
  }
}
