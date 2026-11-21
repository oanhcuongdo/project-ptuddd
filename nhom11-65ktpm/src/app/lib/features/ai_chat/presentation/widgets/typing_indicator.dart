import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ba chấm nhảy sóng (kiểu iMessage) + "AI đang suy nghĩ..." khi chờ chữ đầu tiên.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 6, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(builder: (context) {
                    final t = (_controller.value - i * 0.15) % 1.0;
                    // Nửa đầu chu kỳ: nảy lên theo hình sin; nửa sau: nằm yên.
                    final wave = t < 0.5 ? math.sin(t * 2 * math.pi) : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -5 * wave),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.45 + 0.55 * wave),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AI đang suy nghĩ...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
