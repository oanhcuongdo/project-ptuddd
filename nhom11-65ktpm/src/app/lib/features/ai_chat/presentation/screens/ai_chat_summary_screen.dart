import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/ai_chat_repository.dart';
import '../../data/models/ai_chat_models.dart';
import '../widgets/chat_bubbles.dart' show hanziFontFallback, scoreColor;
import '../widgets/grammar_analysis_view.dart';

/// Kết thúc phiên (server tổng kết và lưu vào lịch sử ôn tập) rồi trả về phiên đầy đủ.
final finishedConversationProvider =
    FutureProvider.autoDispose.family<AiConversation, String>((ref, conversationId) {
  return ref.watch(aiChatRepositoryProvider).finishConversation(conversationId);
});

/// Màn hình tổng kết sau phiên trò chuyện với AI.
class AiChatSummaryScreen extends ConsumerWidget {
  final String conversationId;
  final VoidCallback? onPracticeAgain;

  const AiChatSummaryScreen({super.key, required this.conversationId, this.onPracticeAgain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finishedConversationProvider(conversationId));
    return GlassScaffold(
      appBar: const GlassAppBar(title: Text('Tổng kết phiên ôn bài')),
      body: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: async.when(
          loading: () => const Center(key: Key('summary-loading'), child: CupertinoActivityIndicator(radius: 14)),
          error: (error, _) => Center(
            key: const Key('summary-error'),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: EntranceAnimation(
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CookieIcon(icon: Icons.cloud_off_outlined, color: AppColors.primary, size: 72),
                      const SizedBox(height: 14),
                      Text(
                        error is ApiException ? error.message : 'Không tải được tổng kết. Vui lòng thử lại.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: 'Thử lại',
                        icon: Icons.refresh,
                        prominent: true,
                        onPressed: () => ref.invalidate(finishedConversationProvider(conversationId)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          data: (conv) => _SummaryBody(
            key: const Key('summary-body'),
            conversation: conv,
            onPracticeAgain: onPracticeAgain,
          ),
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  final AiConversation conversation;
  final VoidCallback? onPracticeAgain;

  const _SummaryBody({super.key, required this.conversation, this.onPracticeAgain});

  @override
  Widget build(BuildContext context) {
    final summary = conversation.summary;
    final theme = Theme.of(context);
    final answers = conversation.messages.where((m) => !m.isAssistant).toList();
    final pad = MediaQuery.paddingOf(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    var i = 0;
    Widget enter(Widget child) => EntranceAnimation(index: i++, child: child);

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, pad.top + 12, 16, pad.bottom + 24),
      children: [
        enter(GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                ScoreRing(key: const Key('summary-score'), score: summary?.overallScore ?? 0, size: 88),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Điểm tổng kết', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(summary?.commentVi ?? '', key: const Key('summary-comment')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Stat(icon: Icons.forum_outlined, label: '${summary?.turns ?? 0} lượt'),
                          _Stat(
                            icon: Icons.check_circle_outline,
                            label: '${summary?.correctSentences ?? 0} câu đúng',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        if (summary != null && summary.errorCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Lỗi hay gặp', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          enter(GlassCard(child: _ErrorCounts(counts: summary.errorCounts))),
        ],
        if (summary != null && summary.topErrors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Các lỗi cần lưu ý', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final e in summary.topErrors) enter(_TopErrorTile(error: e)),
        ],
        if (summary != null && summary.grammarPointsToReview.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Điểm ngữ pháp nên ôn lại', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          enter(Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final gp in summary.grammarPointsToReview)
                GlassSurface(
                  borderRadius: BorderRadius.circular(100),
                  shadow: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.book, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(gp, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          )),
        ],
        const SizedBox(height: 16),
        Text('Lịch sử câu trả lời', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Đã lưu vào lịch sử ôn tập. Chạm vào một câu để xem phân tích chi tiết.',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        if (answers.isEmpty) const Text('Bạn chưa trả lời câu nào trong phiên này.'),
        for (final m in answers)
          enter(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              key: Key('answer-${m.id}'),
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              borderRadius: BorderRadius.circular(22),
              onTap: m.grammarFeedback == null ? null : () => showGrammarAnalysisSheet(context, m.grammarFeedback!),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.content, style: const TextStyle(fontSize: 18, fontFamilyFallback: hanziFontFallback)),
                        const SizedBox(height: 2),
                        m.grammarFeedback == null
                            ? Text('Chưa có phân tích', style: TextStyle(color: muted))
                            : Text(
                                m.grammarFeedback!.isCorrect
                                    ? 'Chính xác'
                                    : 'Sửa: ${m.grammarFeedback!.correctedSentence ?? ''}',
                                style: TextStyle(color: muted),
                              ),
                      ],
                    ),
                  ),
                  if (m.grammarFeedback != null) ...[
                    Text(
                      '${m.grammarFeedback!.score}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scoreColor(m.grammarFeedback!.score),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_forward, size: 16, color: muted),
                  ],
                ],
              ),
            ),
          )),
        const SizedBox(height: 16),
        if (onPracticeAgain != null) ...[
          GlassButton(
            label: 'Luyện thêm một phiên',
            icon: Icons.replay,
            expand: true,
            onPressed: onPracticeAgain,
          ),
          const SizedBox(height: 10),
        ],
        GlassButton(
          label: 'Hoàn thành',
          prominent: true,
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _ErrorCounts extends StatelessWidget {
  final Map<String, int> counts;

  const _ErrorCounts({required this.counts});

  @override
  Widget build(BuildContext context) {
    final max = counts.values.fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final entry in counts.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 150, child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: entry.value / max),
                      duration: const Duration(milliseconds: 900),
                      curve: AppMotion.springSmooth,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v.clamp(0.0, 1.0),
                        minHeight: 10,
                        color: AppColors.warningOrange,
                        backgroundColor: AppColors.warningOrange.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 32, child: Text('${entry.value}', textAlign: TextAlign.end)),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopErrorTile extends StatelessWidget {
  final Map<String, dynamic> error;

  const _TopErrorTile({required this.error});

  @override
  Widget build(BuildContext context) {
    const hanzi = TextStyle(fontSize: 16, fontFamilyFallback: hanziFontFallback);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (error['label_vi'] as String?) ?? 'Lỗi',
              style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(error['sentence'] as String? ?? '', style: hanzi),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  error['span'] as String? ?? '',
                  style: hanzi.copyWith(color: AppColors.errorRed, decoration: TextDecoration.lineThrough),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                Text(
                  error['correction'] as String? ?? '',
                  style: hanzi.copyWith(color: AppColors.jadeGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if ((error['explanation_vi'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(error['explanation_vi'] as String),
            ],
          ],
        ),
      ),
    );
  }
}
