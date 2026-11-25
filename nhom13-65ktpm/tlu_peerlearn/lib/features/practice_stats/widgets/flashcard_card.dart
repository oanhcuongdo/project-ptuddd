import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ai_generator/models/flashcard_item.dart';

class FlashcardCard extends StatefulWidget {
  final FlashcardItem flashcard;
  final bool isRemembered;
  final VoidCallback? onToggleRemembered;

  const FlashcardCard({
    super.key,
    required this.flashcard,
    this.isRemembered = false,
    this.onToggleRemembered,
  });

  @override
  State<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<FlashcardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_animController.isAnimating) return;
    if (_showBack) {
      _animController.reverse();
      setState(() => _showBack = false);
    } else {
      _animController.forward();
      setState(() => _showBack = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRemembered = widget.isRemembered;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final angle = _animation.value * math.pi;
        final isBack = _animation.value >= 0.5;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildCardFace(
                    isBack: true,
                    isRemembered: isRemembered,
                  ),
                )
              : _buildCardFace(
                  isBack: false,
                  isRemembered: isRemembered,
                ),
        );
      },
    );
  }

  Widget _buildCardFace({
    required bool isBack,
    required bool isRemembered,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: isBack ? Colors.amber.withAlpha(80) : Colors.blue.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isRemembered
              ? Colors.green.shade400
              : (isBack ? Colors.amber.shade300 : Colors.blue.shade200),
          width: isRemembered ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _flipCard,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(minHeight: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBack
                  ? [Colors.white, const Color(0xFFFFFBEB)]
                  : [Colors.white, const Color(0xFFF0F9FF)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBack ? Colors.amber.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isBack ? Colors.amber.shade300 : Colors.blue.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBack ? Icons.lightbulb_outline : Icons.help_outline,
                          size: 14,
                          color: isBack ? Colors.amber.shade900 : Colors.blue.shade900,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBack ? 'MẶT SAU (ĐÁP ÁN)' : 'MẶT TRƯỚC (CÂU HỎI)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isBack ? Colors.amber.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onToggleRemembered != null)
                    IconButton.filledTonal(
                      tooltip: isRemembered ? 'Đánh dấu cần ôn lại' : 'Đánh dấu đã nhớ',
                      style: IconButton.styleFrom(
                        backgroundColor: isRemembered
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                      ),
                      icon: Icon(
                        isRemembered ? Icons.check_circle : Icons.check_circle_outline,
                        color: isRemembered ? Colors.green.shade800 : Colors.grey.shade600,
                      ),
                      onPressed: widget.onToggleRemembered,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Content text
              Center(
                child: Text(
                  isBack ? widget.flashcard.backText : widget.flashcard.frontText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),
              ),

              if (isBack &&
                  widget.flashcard.explanation != null &&
                  widget.flashcard.explanation!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giải thích: ${widget.flashcard.explanation}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Footer hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flip_camera_android_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Chạm vào thẻ để lật xem đáp án',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
