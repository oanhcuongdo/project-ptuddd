import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/finger_hand_state.dart';
import '../controllers/finger_math_controller.dart';

/// Widget bàn tay Finger Math hiển thị hình ảnh thẻ bài Flashcard trực quan (0..9)
class FingerMathBoardWidget extends StatefulWidget {
  final FingerMathController controller;
  final double height;
  final bool showLiveValue;

  const FingerMathBoardWidget({
    super.key,
    required this.controller,
    this.height = 250.0,
    this.showLiveValue = true,
  });

  @override
  State<FingerMathBoardWidget> createState() => _FingerMathBoardWidgetState();
}

class _FingerMathBoardWidgetState extends State<FingerMathBoardWidget> {
  final AudioService _audioService = sl<AudioService>();

  void _cycleNextDigit(HandType handType) {
    _audioService.playBeadClick();
    final current = handType == HandType.rightHand
        ? widget.controller.rightHand.digitValue
        : widget.controller.leftHand.digitValue;
    final next = (current + 1) % 10;
    _setDigit(handType, next);
  }

  void _setDigit(HandType handType, int value) {
    _audioService.playBeadClick();
    final clamped = value.clamp(0, 9);
    final thumb = clamped >= 5;
    final fingers = clamped % 5;

    if (handType == HandType.rightHand) {
      if (widget.controller.rightHand.isThumbExtended != thumb) {
        widget.controller.toggleThumb(HandType.rightHand);
      }
      widget.controller.setExtendedFingers(HandType.rightHand, fingers);
    } else {
      if (widget.controller.leftHand.isThumbExtended != thumb) {
        widget.controller.toggleThumb(HandType.leftHand);
      }
      widget.controller.setExtendedFingers(HandType.leftHand, fingers);
    }
  }

  void _showFormulaGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    '📖 Flashcard 1D & Bảng Công Thức Finger Math',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ảnh gốc Flashcard 1D (RH) KiddiMath chuẩn trực quan
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/finger_cards/flashcard_full_1d_rh.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.orange.shade50,
                          child: const Text('Hình ảnh Flashcard 1D chuẩn KiddiMath'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Quy ước 2 bàn tay (0 đến 99):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRuleCard(
                    title: '👉 Tay Phải: HÀNG ĐƠN VỊ (0 - 9)',
                    content: '• Ngón cái = 5 (giá trị 5)\n'
                        '• 4 ngón dài (trỏ, giữa, áp út, út) = mỗi ngón giá trị 1\n'
                        '• Số 6: Ngón cái (5) + 1 ngón trỏ (1)\n'
                        '• Số 7: Ngón cái (5) + 2 ngón (2)\n'
                        '• Số 8: Ngón cái (5) + 3 ngón (3)\n'
                        '• Số 9: Cả 5 ngón xòe (5 + 4 = 9)',
                    color: AppColors.secondary.withOpacity(0.1),
                  ),
                  const SizedBox(height: 8),
                  _buildRuleCard(
                    title: '👈 Tay Trái: HÀNG CHỤC (10 - 90)',
                    content: '• Ngón cái = 50 (giá trị 50)\n'
                        '• 4 ngón dài = mỗi ngón giá trị 10\n'
                        '• Số 10: Tay trái giơ 1 ngón trỏ (10), tay phải nắm (0)\n'
                        '• Số 60: Ngón cái (50) + 1 ngón dài (10)\n'
                        '• Kết hợp 2 tay: Biểu diễn từ 00 đến 99 linh hoạt',
                    color: AppColors.accentYellow.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Công thức Anh Bạn Nhỏ (Tổng = 5):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRuleCard(
                    title: '🤝 Cặp bạn nhỏ: (4-1), (3-2), (2-3), (1-4)',
                    content: 'Dùng khi cộng/trừ trong phạm vi 5 trên cùng 1 bàn tay:\n'
                        '• +4 = +5 - 1 | +3 = +5 - 2 | +2 = +5 - 3 | +1 = +5 - 4\n'
                        '• -4 = -5 + 1 | -3 = -5 + 2 | -2 = -5 + 3 | -1 = -5 + 4\n'
                        'Thao tác: Thêm ngón cái 5, gập bớt ngón bạn nhỏ tương ứng.',
                    color: Colors.green.shade50,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Công thức Anh Bạn Lớn (Tổng = 10 - Phối hợp 2 tay):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRuleCard(
                    title: '🌟 Cặp bạn lớn: (9-1), (8-2), (7-3), (6-4), (5-5)',
                    content: 'Dùng khi cộng qua 10 hoặc trừ qua 10 (phối hợp 2 tay):\n'
                        '• Phép cộng (+): Bung 1 ngón Tay Trái (+10), gập bạn lớn ở Tay Phải (- bạn lớn)\n'
                        '  Ví dụ: +9 = +10 (Tay Trái) - 1 (Tay Phải)\n'
                        '  Ví dụ: +8 = +10 (Tay Trái) - 2 (Tay Phải)\n'
                        '• Phép trừ (-): Gập 1 ngón Tay Trái (-10), bung bạn lớn ở Tay Phải (+ bạn lớn)\n'
                        '  Ví dụ: -9 = -10 (Tay Trái) + 1 (Tay Phải)',
                    color: Colors.orange.shade50,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHandCardView({
    required FingerHandState handState,
    required HandType handType,
  }) {
    final isRight = handType == HandType.rightHand;
    final digit = handState.digitValue;
    final displayValue = handState.actualValue;
    final assetPath = 'assets/images/finger_cards/hand_$digit.png';

    return Column(
      children: [
        // Nhãn tiêu đề bàn tay
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isRight
                ? AppColors.secondary.withOpacity(0.2)
                : AppColors.accentYellow.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isRight
                ? 'TAY PHẢI (ĐƠN VỊ: $displayValue)'
                : 'TAY TRÁI (HÀNG CHỤC: $displayValue)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Thẻ hình ảnh Flashcard (chạm để đổi số hoặc xem)
        Expanded(
          child: GestureDetector(
            onTap: () => _cycleNextDigit(handType),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRight ? AppColors.secondary : AppColors.accentOrange,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Nếu là tay trái thì lật gương hình ảnh ngang để ngón cái ở bên phải
                  Transform.flip(
                    flipX: !isRight,
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            '$digit',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$displayValue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),
        // Bộ nút chọn nhanh số (0 đến 9) cho bé bấm
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(10, (idx) {
              final isSelected = digit == idx;
              final label = isRight ? '$idx' : '${idx * 10}';
              return GestureDetector(
                onTap: () => _setDigit(handType, idx),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isRight ? AppColors.secondary : AppColors.accentOrange)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final totalVal = widget.controller.totalValue;
        final rightHand = widget.controller.rightHand;
        final leftHand = widget.controller.leftHand;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh hiển thị giá trị số & quy ước ngón tay
            if (widget.showLiveValue)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Số: ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '$totalVal',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${rightHand.shortNotation})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Xem Flashcard 1D & công thức',
                          onPressed: () => _showFormulaGuideModal(context),
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _audioService.playBeadClick();
                            widget.controller.reset();
                          },
                          icon: const Icon(Icons.front_hand, size: 16),
                          label: const Text('Nắm tay (0)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Khu vực hiển thị 2 bàn tay tương tác Flashcard
            Container(
              height: widget.height,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Tay trái: Hàng chục (10..90)
                  if (widget.controller.showLeftHand)
                    Expanded(
                      child: _buildHandCardView(
                        handState: leftHand,
                        handType: HandType.leftHand,
                      ),
                    ),

                  if (widget.controller.showLeftHand)
                    Container(
                      width: 2,
                      height: widget.height * 0.7,
                      color: Colors.grey.shade200,
                    ),

                  // Tay phải: Hàng đơn vị (0..9)
                  Expanded(
                    child: _buildHandCardView(
                      handState: rightHand,
                      handType: HandType.rightHand,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
