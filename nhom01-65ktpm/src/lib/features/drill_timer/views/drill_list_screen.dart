import 'package:flutter/material.dart';
import '../models/drill_item.dart';
import '../models/drill_presets.dart';

class DrillListScreen extends StatefulWidget {
  final ValueChanged<DrillItem>? onSelectDrill;
  final VoidCallback? onOpenHistory;

  const DrillListScreen({
    super.key,
    this.onSelectDrill,
    this.onOpenHistory,
  });

  @override
  State<DrillListScreen> createState() => _DrillListScreenState();
}

class _DrillListScreenState extends State<DrillListScreen> {
  String _selectedCategory = 'Tất cả';

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'timeline':
        return Icons.timeline_rounded;
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'gps_fixed':
        return Icons.gps_fixed_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'sports_soccer':
      default:
        return Icons.sports_soccer_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Khởi động':
        return const Color(0xFF38BDF8);
      case 'Thể lực':
        return const Color(0xFFF59E0B);
      case 'Phục hồi':
        return const Color(0xFFA855F7);
      case 'Kỹ thuật':
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drills = DrillPresets.getByCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GIÁO ÁN BẤM GIỜ',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Chọn bài tập để bắt đầu phiên huấn luyện',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử tập luyện',
            onPressed: widget.onOpenHistory,
            icon: const Icon(
              Icons.history_rounded,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: DrillPresets.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = DrillPresets.categories[index];
                final isSelected = category == _selectedCategory;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: const Color(0xFF10B981),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF000000)
                        : const Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF334155),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: drills.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12, height: 12),
              itemBuilder: (context, index) {
                final drill = drills[index];
                return _buildDrillCard(context, drill);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillCard(BuildContext context, DrillItem drill) {
    final categoryColor = _getCategoryColor(drill.category);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (widget.onSelectDrill != null) {
            widget.onSelectDrill!(drill);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã chọn bài tập: ${drill.title}'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(drill.iconName),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drill.title,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            drill.category,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFF22C55E),
                    size: 36,
                  ),
                ],
              ),
              if (drill.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  drill.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaInfo(
                    Icons.timer_outlined,
                    '${drill.durationMinutes} phút/hiệp',
                  ),
                  _buildMetaInfo(
                    Icons.repeat_rounded,
                    '${drill.sets} hiệp',
                  ),
                  _buildMetaInfo(
                    Icons.pause_circle_outline_rounded,
                    drill.restSeconds > 0
                        ? 'Nghỉ ${drill.restSeconds}s'
                        : 'Không nghỉ',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
