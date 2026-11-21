import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../application/ai_chat_controller.dart';
import '../../data/chat_voice_services.dart';
import '../widgets/chat_bubbles.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/grammar_analysis_view.dart';
import 'ai_chat_summary_screen.dart';

/// Màn hình trò chuyện ôn bài cùng trợ lý AI sau mỗi bài học.
class AiChatScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final String? lessonTitle;

  const AiChatScreen({super.key, required this.lessonId, this.lessonTitle});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _listening = false;
  bool _usedVoice = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(aiChatControllerProvider.notifier).start(widget.lessonId));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (_listening) await _toggleMic();
    final method = _usedVoice ? 'voice' : 'text';
    _input.clear();
    _usedVoice = false;
    await ref.read(aiChatControllerProvider.notifier).send(text, inputMethod: method);
  }

  Future<void> _toggleMic() async {
    final speech = ref.read(chatSpeechInputProvider);
    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!await speech.initialize()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không dùng được micro. Hãy cấp quyền ghi âm cho ứng dụng.')),
      );
      return;
    }
    setState(() => _listening = true);
    await speech.listen(onResult: (text, isFinal) {
      if (!mounted) return;
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
      _usedVoice = true;
      if (isFinal) setState(() => _listening = false);
    });
  }

  Future<void> _openSummary() async {
    final conversationId = ref.read(aiChatControllerProvider).conversationId;
    if (conversationId == null) return;
    final controller = ref.read(aiChatControllerProvider.notifier);
    controller.markFinished();
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => AiChatSummaryScreen(
          conversationId: conversationId,
          onPracticeAgain: () {
            Navigator.of(context).pop();
            controller.start(widget.lessonId);
          },
        ),
      ),
    );
  }

  Future<void> _confirmFinishEarly() async {
    HapticFeedback.selectionClick();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc phiên?'),
        content: const Text('Bạn muốn dừng trò chuyện và xem tổng kết ngay bây giờ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tiếp tục')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kết thúc')),
        ],
      ),
    );
    if (ok == true) await _openSummary();
  }

  /// Bong bóng có chỉ số < [_revealed] đã xuất hiện rồi → không chạy lại hiệu ứng khi cuộn.
  int _revealed = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatControllerProvider);
    final controller = ref.read(aiChatControllerProvider.notifier);
    final tts = ref.read(chatTtsProvider);
    final theme = Theme.of(context);

    ref.listen(aiChatControllerProvider, (prev, next) {
      if (prev?.bubbles.length != next.bubbles.length ||
          (next.bubbles.isNotEmpty && prev?.bubbles.last.text != next.bubbles.last.text)) {
        _scrollToBottom();
      }
      final error = next.errorMessage;
      if (error != null && error != prev?.errorMessage && next.phase != ChatPhase.startFailed) {
        if (next.failedInput != null && _input.text.isEmpty) {
          _input.text = next.failedInput!;
        }
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        controller.clearError();
      }
    });

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ôn bài cùng AI'),
            if (widget.lessonTitle != null)
              Text(
                widget.lessonTitle!,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.springBouncy,
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: state.phase == ChatPhase.ready && state.turnCount > 0
                ? GlassIconButton(
                    key: const Key('finish-early'),
                    tooltip: 'Kết thúc & tổng kết',
                    icon: CupertinoIcons.flag,
                    onPressed: _confirmFinishEarly,
                  )
                : const SizedBox.shrink(),
          ),
        ],
        bottom: state.conversationId == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: _TurnProgress(turnCount: state.turnCount, maxTurns: state.maxTurns),
              ),
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        child: switch (state.phase) {
          ChatPhase.starting => const _CenteredStatus(
              key: Key('chat-starting'),
              icon: Icons.smart_toy_outlined,
              message: 'Trợ lý AI đang chuẩn bị cuộc trò chuyện theo bài học...',
              loading: true,
            ),
          ChatPhase.startFailed => _CenteredStatus(
              key: const Key('chat-start-failed'),
              icon: Icons.cloud_off_outlined,
              message: state.errorMessage ?? 'Không bắt đầu được phiên trò chuyện.',
              actionLabel: 'Thử lại',
              onAction: controller.retryStart,
            ),
          _ => Builder(
              key: const Key('chat-body'),
              builder: (context) {
                final top = MediaQuery.paddingOf(context).top;
                final offset = state.disclaimer.isNotEmpty ? 1 : 0;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (state.bubbles.length > _revealed) _revealed = state.bubbles.length;
                });
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        key: const Key('chat-list'),
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(12, top + 10, 12, 12),
                        itemCount: state.bubbles.length + offset,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          if (offset == 1 && i == 0) return _Disclaimer(text: state.disclaimer);
                          final index = i - offset;
                          final bubble = state.bubbles[index];
                          final child = bubble.isAssistant
                              ? AssistantBubble(
                                  bubble: bubble,
                                  showTranslation: state.revealedTranslations.contains(bubble.id),
                                  onToggleTranslation: () => controller.toggleTranslation(bubble.id),
                                  onSpeak: () => tts.speak(bubble.text),
                                  onSpeakSlow: () => tts.speak(bubble.text, slow: true),
                                )
                              : UserBubble(
                                  bubble: bubble,
                                  onOpenGrammar: bubble.grammar == null
                                      ? null
                                      : () => showGrammarAnalysisSheet(context, bubble.grammar!),
                                );
                          return EntranceAnimation(
                            enabled: index >= _revealed,
                            offset: const Offset(0, 24),
                            fromScale: 0.85,
                            scaleAlignment: bubble.isAssistant ? Alignment.bottomLeft : Alignment.bottomRight,
                            child: child,
                          );
                        },
                      ),
                    ),
                    AnimatedSize(
                      duration: AppMotion.medium,
                      curve: AppMotion.springSmooth,
                      alignment: Alignment.bottomCenter,
                      child: state.phase == ChatPhase.finished
                          ? _FinishedBanner(onViewSummary: _openSummary)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SuggestedRepliesBar(
                                  suggestions: state.suggestions,
                                  onSelected: (s) {
                                    _input.text = s.hanzi;
                                    _input.selection = TextSelection.collapsed(offset: s.hanzi.length);
                                    _usedVoice = false;
                                  },
                                ),
                                ChatInputBar(
                                  controller: _input,
                                  enabled: state.canSend,
                                  isListening: _listening,
                                  onSend: _send,
                                  onMicPressed: _toggleMic,
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
        },
      ),
    );
  }
}

class _TurnProgress extends StatelessWidget {
  final int turnCount;
  final int maxTurns;

  const _TurnProgress({required this.turnCount, required this.maxTurns});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppMotion.short,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: a.drive(Tween(begin: const Offset(0, 0.6), end: Offset.zero)),
                child: child,
              ),
            ),
            child: Text(
              'Lượt $turnCount/$maxTurns',
              key: ValueKey(turnCount),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: maxTurns == 0 ? 0 : turnCount / maxTurns),
              duration: AppMotion.long,
              curve: AppMotion.springSmooth,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v.clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;

  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GlassSurface(
        borderRadius: BorderRadius.circular(100),
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.info_circle, size: 15, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedBanner extends StatelessWidget {
  final VoidCallback onViewSummary;

  const _FinishedBanner({required this.onViewSummary});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: EntranceAnimation(
          key: const Key('chat-finished'),
          offset: const Offset(0, 40),
          child: GlassCard(
            thick: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bạn đã hoàn thành phiên trò chuyện! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.jadeGreen),
                ),
                const SizedBox(height: 12),
                GlassButton(
                  key: const Key('view-summary'),
                  label: 'Xem tổng kết',
                  icon: Icons.insights_outlined,
                  prominent: true,
                  expand: true,
                  onPressed: onViewSummary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredStatus({
    super.key,
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: EntranceAnimation(
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CookieIcon(icon: icon, color: AppColors.primary, size: 80, lobes: 10),
                const SizedBox(height: 18),
                Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                if (loading) ...[
                  const SizedBox(height: 18),
                  const CupertinoActivityIndicator(radius: 12),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 18),
                  GlassButton(label: actionLabel!, icon: Icons.refresh, prominent: true, onPressed: onAction),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
