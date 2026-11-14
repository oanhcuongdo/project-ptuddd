import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../injection_container.dart';
import '../controllers/abacus_controller.dart';
import 'soroban_painter.dart';

class SorobanBoardWidget extends StatefulWidget {
  final AbacusController controller;
  final double height;
  final bool showLiveValue;

  const SorobanBoardWidget({
    super.key,
    required this.controller,
    this.height = 240.0,
    this.showLiveValue = true,
  });

  @override
  State<SorobanBoardWidget> createState() => _SorobanBoardWidgetState();
}

class _SorobanBoardWidgetState extends State<SorobanBoardWidget> {
  final AudioService _audioService = sl<AudioService>();

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final localPos = details.localPosition;
    final colWidth = constraints.maxWidth / widget.controller.columns.length;
    final colIdx = (localPos.dx / colWidth).floor().clamp(
          0,
          widget.controller.columns.length - 1,
        );

    final beamY = widget.height * 0.32;

    _audioService.playBeadClick();

    if (localPos.dy < beamY) {
      // Chạm vùng hạt trên
      widget.controller.toggleUpperBead(colIdx);
    } else {
      // Chạm vùng 4 hạt dưới
      final lowerHeight = widget.height - beamY;
      final touchRelativeY = localPos.dy - beamY;
      // Chia thành 4 nấc từ trên xuống
      final fraction = touchRelativeY / lowerHeight;
      if (fraction < 0.28) {
        widget.controller.setLowerBeads(colIdx, 1);
      } else if (fraction < 0.52) {
        widget.controller.setLowerBeads(colIdx, 2);
      } else if (fraction < 0.76) {
        widget.controller.setLowerBeads(colIdx, 3);
      } else {
        widget.controller.setLowerBeads(colIdx, 4);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh giá trị và nút Reset bàn tính
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showLiveValue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Số trên bàn tính: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${widget.controller.totalValue}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // Nút Reset (Gạt hạt bàn tính về 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      _audioService.playBeadClick();
                      widget.controller.reset();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Gạt số (0)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Khung bàn tính gảy Soroban
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, constraints),
                  child: Container(
                    height: widget.height,
                    width: constraints.maxWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomPaint(
                      painter: SorobanPainter(
                        columns: widget.controller.columns,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
