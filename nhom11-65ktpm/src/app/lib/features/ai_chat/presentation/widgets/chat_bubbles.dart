import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../application/ai_chat_controller.dart';
import 'typing_indicator.dart';

const hanziFontFallback = ['Noto Sans SC', 'PingFang SC', 'Roboto'];

Color scoreColor(int score) {
  if (score >= 85) return AppColors.jadeGreen;
  if (score >= 60) return AppColors.warningOrange;
  return AppColors.errorRed;
}

/// Bong bóng câu nói của trợ lý AI: Hán tự, pinyin, nút nghe, nút bật/tắt nghĩa.
class AssistantBubble extends StatelessWidget {
  final ChatBubble bubble;
  final bool showTranslation;
  final VoidCallback onToggleTranslation;
  final VoidCallback onSpeak;
  final VoidCallback onSpeakSlow;

  const AssistantBubble({
    super.key,
    required this.bubble,
    required this.showTranslation,
    required this.onToggleTranslation,
    required this.onSpeak,
    required this.onSpeakSlow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final waiting = bubble.isStreaming && bubble.text.isEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CookieIcon(icon: Icons.smart_toy_outlined, color: AppColors.primary, size: 34, lobes: 8),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GlassSurface(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(8),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
                child: AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.springSmooth,
                  alignment: Alignment.topLeft,
                  child: waiting
                      ? const TypingIndicator(key: Key('ai-typing'))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text.rich(
                                TextSpan(
                                  text: bubble.text,
                                  children: [
                                    if (bubble.isStreaming)
                                      TextSpan(
                                        text: ' ▍',
                                        style: TextStyle(color: theme.colorScheme.primary),
                                      ),
                                  ],
                                ),
                                key: Key('ai-hanzi-${bubble.id}'),
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.4,
                                  color: theme.colorScheme.onSurface,
                                  fontFamilyFallback: hanziFontFallback,
                                ),
                              ),
                            ),
                            if (!bubble.isStreaming && (bubble.pinyin ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                bubble.pinyin!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            AnimatedSwitcher(
                              duration: AppMotion.medium,
                              switchInCurve: AppMotion.emphasized,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: SizeTransition(sizeFactor: a, alignment: Alignment.topLeft, child: child),
                              ),
                              child: !bubble.isStreaming && showTranslation && bubble.translationVi != null
                                  ? Padding(
                                      key: Key('ai-translation-${bubble.id}'),
                                      padding: const EdgeInsets.only(top: 6, right: 6),
                                      child: Text(
                                        bubble.translationVi!,
                                        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (!bubble.isStreaming)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _SmallIconButton(
                                      key: Key('speak-${bubble.id}'),
                                      icon: CupertinoIcons.speaker_2,
                                      tooltip: 'Nghe mẫu',
                                      onPressed: onSpeak,
                                    ),
                                    _SmallIconButton(
                                      icon: CupertinoIcons.tortoise,
                                      tooltip: 'Nghe chậm',
                                      onPressed: onSpeakSlow,
                                    ),
                                    _SmallIconButton(
                                      key: Key('translate-${bubble.id}'),
                                      icon: showTranslation ? Icons.translate : Icons.g_translate_outlined,
                                      tooltip: showTranslation ? 'Ẩn nghĩa tiếng Việt' : 'Hiện nghĩa tiếng Việt',
                                      active: showTranslation,
                                      onPressed: onToggleTranslation,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bong bóng câu trả lời của người học kèm kết quả chấm ngữ pháp.
class UserBubble extends StatelessWidget {
  final ChatBubble bubble;
  final VoidCallback? onOpenGrammar;

  const UserBubble({super.key, required this.bubble, this.onOpenGrammar});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(8),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            // Bóng vẽ bằng RRect (Impeller vẽ bóng superellipse bị lỗi khối vuông).
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  shape: RoundedSuperellipseBorder(borderRadius: radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.clayGradient,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bubble.inputMethod == 'voice') ...[
                        const Icon(CupertinoIcons.waveform, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          bubble.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamilyFallback: hanziFontFallback,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.springBouncy,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a.drive(const ClampedProgress(end: 0.5)),
              child: ScaleTransition(scale: a, alignment: Alignment.centerRight, child: child),
            ),
            child: KeyedSubtree(
              key: ValueKey(bubble.grammarStatus),
              child: GrammarChip(bubble: bubble, onTap: onOpenGrammar),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn nhỏ dưới câu của người học: đang chấm / điểm ngữ pháp / lỗi.
class GrammarChip extends StatelessWidget {
  final ChatBubble bubble;
  final VoidCallback? onTap;

  const GrammarChip({super.key, required this.bubble, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    switch (bubble.grammarStatus) {
      case GrammarStatus.none:
        return const SizedBox.shrink();
      case GrammarStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 7),
            const SizedBox(width: 6),
            Text('Đang phân tích ngữ pháp...', style: style),
          ],
        );
      case GrammarStatus.failed:
        return Text(
          'Chưa phân tích được ngữ pháp câu này',
          style: style?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        );
      case GrammarStatus.done:
        final g = bubble.grammar!;
        final color = scoreColor(g.score);
        final label = g.isCorrect ? 'Chính xác · ${g.score} điểm' : '${g.errors.length} lỗi · ${g.score} điểm';
        return Pressable(
          key: Key('grammar-chip-${bubble.id}'),
          onTap: onTap,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(100),
            tint: color.withValues(alpha: 0.14),
            shadow: false,
            padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  g.isCorrect ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.exclamationmark_circle_fill,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: style?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 2),
                  Icon(CupertinoIcons.chevron_forward, size: 13, color: color),
                ],
              ],
            ),
          ),
        );
    }
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  const _SmallIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        pressedScale: 0.8,
        semanticLabel: tooltip,
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.emphasized,
          width: 36,
          height: 32,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: active ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent,
          ),
          child: Center(
            child: MorphSwitcher(
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 19,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
