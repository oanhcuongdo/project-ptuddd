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

class _FlashcardCardState extends State<FlashcardCard> {
  bool _showBack = false;

  void _flipCard() {
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRemembered = widget.isRemembered;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRemembered ? Colors.green.shade400 : Colors.grey.shade300,
          width: isRemembered ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _flipCard,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(minHeight: 220),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showBack ? Colors.amber.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _showBack ? 'MẶT SAU (ĐÁP ÁN)' : 'MẶT TRƯỚC (CÂU HỎI)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showBack ? Colors.amber.shade900 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (widget.onToggleRemembered != null)
                    IconButton(
                      tooltip: isRemembered ? 'Đánh dấu cần ôn lại' : 'Đánh dấu đã nhớ',
                      icon: Icon(
                        isRemembered ? Icons.check_circle : Icons.check_circle_outline,
                        color: isRemembered ? Colors.green : Colors.grey,
                      ),
                      onPressed: widget.onToggleRemembered,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Content text
              Center(
                child: Text(
                  _showBack ? widget.flashcard.backText : widget.flashcard.frontText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),

              if (_showBack && widget.flashcard.explanation != null && widget.flashcard.explanation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Giải thích: ${widget.flashcard.explanation}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Footer hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Chạm vào thẻ để lật',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
