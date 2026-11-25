import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../styles/chat_styles.dart';

/// Thanh phân trang gọn 1 hàng ngang:
/// Trái: `‹ Trước` [1] [2] ... [N] `Sau ›` | Phải: `Đến trang: [1/N] [Đi]`
class ChatPaginationBar extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const ChatPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  State<ChatPaginationBar> createState() => _ChatPaginationBarState();
}

class _ChatPaginationBarState extends State<ChatPaginationBar> {
  final _jumpController = TextEditingController();

  @override
  void dispose() {
    _jumpController.dispose();
    super.dispose();
  }

  void _jumpToPage() {
    final parsed = int.tryParse(_jumpController.text.trim());
    if (parsed == null) return;
    final target = parsed.clamp(1, widget.totalPages);
    _jumpController.clear();
    widget.onPageChanged(target);
  }

  List<int?> _visiblePageNumbers() {
    final total = widget.totalPages;
    final current = widget.currentPage;
    if (total <= 5) {
      return List<int>.generate(total, (i) => i + 1);
    }
    final pages = <int?>[1];
    if (current > 3) pages.add(null);
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (var p = start; p <= end; p++) {
      pages.add(p);
    }
    if (current < total - 2) pages.add(null);
    pages.add(total);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final canPrev = widget.currentPage > 1;
    final canNext = widget.currentPage < widget.totalPages;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: ChatStyles.cardDecoration,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PagePillButton(
                label: '‹ Trước',
                enabled: canPrev,
                onTap: () => widget.onPageChanged(widget.currentPage - 1),
              ),
              const SizedBox(width: 6),
              ..._visiblePageNumbers().map((page) {
                if (page == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('...', style: ChatStyles.metaText),
                  );
                }
                final isActive = page == widget.currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onPageChanged(page),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? ChatStyles.tealPrimary
                            : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? ChatStyles.tealPrimary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isActive ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              _PagePillButton(
                label: 'Sau ›',
                enabled: canNext,
                onTap: () => widget.onPageChanged(widget.currentPage + 1),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đến trang:', style: ChatStyles.metaText),
              const SizedBox(width: 8),
              SizedBox(
                width: 62,
                height: 34,
                child: TextField(
                  controller: _jumpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _jumpToPage(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '${widget.currentPage}/${widget.totalPages}',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _PagePillButton(
                label: 'Đi',
                enabled: true,
                onTap: _jumpToPage,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Nút phân trang co gọn đúng kích thước chữ (không giãn 100% chiều ngang)
class _PagePillButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PagePillButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
