import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/vocab_entry_model.dart';
import '../styles/vocab_styles.dart';

/// Hộp thoại Ôn tập Flashcard lật thẻ 3D 2 mặt:
/// - Mặt trước: Từ gốc + cặp ngôn ngữ + câu ví dụ từ phòng chat.
/// - Mặt sau: Nghĩa dịch chi tiết.
/// - Nút đánh dấu "Đã thuộc" / "Cần ôn lại" cập nhật trực tiếp lên Supabase.
class VocabFlashcardDialog extends StatefulWidget {
  final List<VocabEntryModel> entries;
  final Future<bool> Function(VocabEntryModel entry) onToggleMastered;

  const VocabFlashcardDialog({
    super.key,
    required this.entries,
    required this.onToggleMastered,
  });

  static Future<void> show(
    BuildContext context, {
    required List<VocabEntryModel> entries,
    required Future<bool> Function(VocabEntryModel entry) onToggleMastered,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => VocabFlashcardDialog(
        entries: entries,
        onToggleMastered: onToggleMastered,
      ),
    );
  }

  @override
  State<VocabFlashcardDialog> createState() => _VocabFlashcardDialogState();
}

class _VocabFlashcardDialogState extends State<VocabFlashcardDialog>
    with SingleTickerProviderStateMixin {
  late List<VocabEntryModel> _cards;
  late final AnimationController _flipController;
  int _currentIndex = 0;
  bool _isBack = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _cards = List<VocabEntryModel>.from(widget.entries);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isBack = !_isBack);
  }

  void _goTo(int nextIndex) {
    if (_cards.isEmpty) return;
    final clamped = nextIndex.clamp(0, _cards.length - 1);
    if (clamped == _currentIndex) return;
    _flipController.reset();
    setState(() {
      _currentIndex = clamped;
      _isBack = false;
    });
  }

  Future<void> _markCurrent({required bool targetMastered}) async {
    if (_cards.isEmpty || _isUpdating) return;
    final current = _cards[_currentIndex];

    if (current.isMastered != targetMastered) {
      setState(() => _isUpdating = true);
      final ok = await widget.onToggleMastered(current);
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        if (ok) {
          _cards[_currentIndex] =
              current.copyWith(isMastered: targetMastered);
        }
      });
    }

    if (_currentIndex < _cards.length - 1) {
      _goTo(_currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chưa có từ vựng',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Hãy lưu ít nhất 1 từ vựng từ phòng chat hoặc hộp tra cứu để ôn tập Flashcard.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: VocabStyles.tealDark,
            ),
            child: const Text('Đóng'),
          ),
        ],
      );
    }

    final current = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VocabStyles.tealSoftBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VocabStyles.tealBorder),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: VocabStyles.tealDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ôn tập Flashcard',
                          style: VocabStyles.sectionTitle,
                        ),
                        Text(
                          'Thẻ ${_currentIndex + 1} / ${_cards.length}',
                          style: VocabStyles.metaText,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    VocabStyles.tealPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, _) {
                    final angle = _flipController.value * math.pi;
                    final showingBack = angle > math.pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: showingBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildBackCard(current),
                            )
                          : _buildFrontCard(current),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed:
                        _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                    tooltip: 'Thẻ trước',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _markCurrent(targetMastered: false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: VocabStyles.learningBg,
                        foregroundColor: VocabStyles.learningText,
                        side: const BorderSide(color: VocabStyles.learningBorder),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 17),
                      label: const Text(
                        'Cần ôn lại',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _markCurrent(targetMastered: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: VocabStyles.tealPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Đã thuộc',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.outlined(
                    onPressed: _currentIndex < _cards.length - 1
                        ? () => _goTo(_currentIndex + 1)
                        : null,
                    tooltip: 'Thẻ tiếp theo',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(VocabEntryModel entry) {
    final langColors = VocabStyles.badgeColorsForLang(entry.sourceLang);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: VocabStyles.flashcardFrontDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: langColors.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: langColors.border),
                ),
                child: Text(
                  entry.languagePairLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: langColors.text,
                  ),
                ),
              ),
              const Spacer(),
              _MasteryChip(isMastered: entry.isMastered),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            entry.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (entry.hasExample) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '"${entry.exampleSentence}"',
              textAlign: TextAlign.center,
              style: VocabStyles.exampleText,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 15,
                color: VocabStyles.tealPrimary,
              ),
              SizedBox(width: 5),
              Text(
                'Chạm vào thẻ để lật xem nghĩa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VocabStyles.tealPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(VocabEntryModel entry) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: VocabStyles.flashcardBackDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                entry.word,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _MasteryChip(isMastered: entry.isMastered),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            entry.translatedMeaning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: VocabStyles.tealDeep,
              height: 1.3,
            ),
          ),
          if (entry.hasExample) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '"${entry.exampleSentence}"',
              textAlign: TextAlign.center,
              style: VocabStyles.exampleText,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flip_rounded, size: 15, color: VocabStyles.tealDark),
              SizedBox(width: 5),
              Text(
                'Chạm lại để quay về mặt trước',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VocabStyles.tealDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  final bool isMastered;
  const _MasteryChip({required this.isMastered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMastered ? VocabStyles.masteredBg : VocabStyles.learningBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isMastered
              ? VocabStyles.masteredBorder
              : VocabStyles.learningBorder,
        ),
      ),
      child: Text(
        isMastered ? 'Đã thuộc' : 'Đang học',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color:
              isMastered ? VocabStyles.masteredText : VocabStyles.learningText,
        ),
      ),
    );
  }
}
