import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/models/ai_chat_models.dart';
import 'chat_bubbles.dart' show hanziFontFallback;

/// Hàng câu trả lời mẫu do AI gợi ý; chạm để điền vào ô nhập.
class SuggestedRepliesBar extends StatelessWidget {
  final List<SuggestedReply> suggestions;
  final ValueChanged<SuggestedReply> onSelected;

  const SuggestedRepliesBar({super.key, required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.springSmooth,
      child: suggestions.isEmpty
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 66,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Center(
                      child: Tooltip(
                        message: 'Câu trả lời mẫu',
                        child: Icon(CupertinoIcons.lightbulb, color: AppColors.secondaryDark),
                      ),
                    );
                  }
                  final s = suggestions[index - 1];
                  return EntranceAnimation(
                    key: ValueKey('${s.hanzi}-$index'),
                    index: index,
                    offset: const Offset(24, 0),
                    child: Tooltip(
                      message: s.translationVi,
                      child: Pressable(
                        key: Key('suggestion-${index - 1}'),
                        onTap: () => onSelected(s),
                        haptic: true,
                        child: GlassSurface(
                          borderRadius: BorderRadius.circular(18),
                          shadow: false,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.hanzi,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                  fontFamilyFallback: hanziFontFallback,
                                ),
                              ),
                              Text(
                                s.pinyin,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Ô nhập câu trả lời: gõ phím hoặc bấm micro để nói tiếng Trung.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final int maxLength;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isListening,
    required this.onSend,
    required this.onMicPressed,
    this.maxLength = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
        child: GlassSurface(
          thick: true,
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MicButton(
                key: const Key('mic-button'),
                listening: isListening,
                onPressed: enabled ? onMicPressed : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  key: const Key('chat-input'),
                  controller: controller,
                  enabled: enabled,
                  maxLength: maxLength,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  cursorColor: scheme.primary,
                  style: TextStyle(fontSize: 18, color: scheme.onSurface, fontFamilyFallback: hanziFontFallback),
                  decoration: InputDecoration(
                    hintText: isListening ? 'Đang nghe... hãy nói tiếng Trung' : 'Trả lời bằng tiếng Trung...',
                    counterText: '',
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = enabled && value.text.trim().isNotEmpty;
                  return Tooltip(
                    message: 'Gửi',
                    child: Pressable(
                      key: const Key('send-button'),
                      onTap: canSend ? onSend : null,
                      pressedScale: 0.82,
                      semanticLabel: 'Gửi',
                      child: AnimatedScale(
                        scale: canSend ? 1 : 0.78,
                        duration: AppMotion.medium,
                        curve: AppMotion.springBouncy,
                        child: AnimatedContainer(
                          duration: AppMotion.short,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: canSend ? scheme.primary : scheme.onSurface.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            CupertinoIcons.arrow_up,
                            size: 22,
                            color: canSend ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút micro: khi đang nghe sẽ chuyển màu đỏ, icon đổi hình và toả sóng.
class _MicButton extends StatefulWidget {
  final bool listening;
  final VoidCallback? onPressed;

  const _MicButton({super.key, required this.listening, required this.onPressed});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = widget.listening;
    final tooltip = on ? 'Dừng nghe' : 'Nói câu trả lời (tiếng Trung)';
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: widget.onPressed,
        pressedScale: 0.82,
        semanticLabel: tooltip,
        child: AnimatedOpacity(
          opacity: widget.onPressed == null ? 0.4 : 1,
          duration: AppMotion.short,
          child: SizedBox.square(
            dimension: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (on)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => Transform.scale(
                      scale: 1 + _pulse.value * 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.35 * (1 - _pulse.value)),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? AppColors.primary : scheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: MorphSwitcher(
                      child: Icon(
                        on ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                        key: ValueKey(on),
                        size: 20,
                        color: on ? Colors.white : scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
