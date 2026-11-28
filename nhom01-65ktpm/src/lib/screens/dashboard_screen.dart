import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../models/habit_preset.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/player_profile_model.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'match_journal_screen.dart';

/// Neon Pitch UI Deluxe (Pro Athlete Level):
/// Background: Deep Pitch Radial Dark #0A0E17 -> #0D1117
/// Cards: Glass-morphic Slate #162032 with gradient border & subtle inner glow
/// Accents: Pitch Neon #10B981, Sky Pulse #38BDF8, Flame Amber #F59E0B
/// Typography: Energetic, athletic badges, responsive & overflow-proof
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  PlayerProfileModel? _userProfile;

  // Streak ngày kỷ luật
  final int _streakDays = 7;
  bool _checkedInToday = false;

  // Tab controller 3 nhóm
  late TabController _tabController;

  // Danh sách thói quen
  final List<HabitModel> _habits = [
    // 1. Kỹ thuật bóng đá
    HabitModel(
      id: '1',
      title: 'Tâng bóng cảm giác 2 chân',
      description: 'Duy trì sự nhạy bén và cảm giác chạm mu bàn chân',
      category: HabitCategory.technical,
      type: HabitType.quantitative,
      targetValue: 500,
      currentValue: 350,
      unit: 'cái',
      isCompletedToday: false,
    ),
    HabitModel(
      id: '2',
      title: 'Chuyền bóng bật tường 1 chạm',
      description: 'Luyện phản xạ cổ chân và đỡ bóng dính bước 1',
      category: HabitCategory.technical,
      type: HabitType.qualitative,
      targetValue: 1,
      currentValue: 1,
      unit: 'phiên',
      isCompletedToday: true,
    ),
    HabitModel(
      id: '3',
      title: 'Sút phạt góc hẹp & cứa lòng',
      description: '10 cú góc chữ A chân thuận & 10 cú chân không thuận',
      category: HabitCategory.technical,
      type: HabitType.quantitative,
      targetValue: 20,
      currentValue: 10,
      unit: 'quả',
      isCompletedToday: false,
    ),

    // 2. Thể lực
    HabitModel(
      id: '4',
      title: 'Chạy biến tốc (Interval Sprint)',
      description: 'Bứt tốc 100m nghỉ 30s x 10 hiệp tăng VO2 max',
      category: HabitCategory.fitness,
      type: HabitType.quantitative,
      targetValue: 5.0,
      currentValue: 5.0,
      unit: 'km',
      isCompletedToday: true,
    ),
    HabitModel(
      id: '5',
      title: 'Plank & Cơ bụng cốt lõi (Core)',
      description: 'Cải thiện thăng bằng và sức mạnh tranh chấp tì đè',
      category: HabitCategory.fitness,
      type: HabitType.quantitative,
      targetValue: 15,
      currentValue: 10,
      unit: 'phút',
      isCompletedToday: false,
    ),
    HabitModel(
      id: '6',
      title: 'Giãn cơ Foam Roller sau tập',
      description: 'Thả lỏng cơ đùi trước, bắp chuối và gân kheo tránh chấn thương',
      category: HabitCategory.fitness,
      type: HabitType.qualitative,
      targetValue: 1,
      currentValue: 0,
      unit: 'lần',
      isCompletedToday: false,
    ),

    // 3. Dinh dưỡng
    HabitModel(
      id: '7',
      title: 'Uống đủ nước & Bù điện giải',
      description: 'Duy trì nước cho các sợi cơ, chống mỏi cơ và chuột rút',
      category: HabitCategory.nutrition,
      type: HabitType.quantitative,
      targetValue: 3.0,
      currentValue: 2.2,
      unit: 'lít',
      isCompletedToday: false,
    ),
    HabitModel(
      id: '8',
      title: 'Bổ sung Protein phục hồi cơ',
      description: 'Nạp protein sạch và carb hấp thu chậm sau khi tập luyện',
      category: HabitCategory.nutrition,
      type: HabitType.qualitative,
      targetValue: 1,
      currentValue: 1,
      unit: 'bữa',
      isCompletedToday: true,
    ),
    HabitModel(
      id: '9',
      title: 'Ngủ đủ 8 tiếng phục hồi thể lực',
      description: 'Đi ngủ trước 23h để cơ bắp tái tạo tối đa',
      category: HabitCategory.nutrition,
      type: HabitType.qualitative,
      targetValue: 1,
      currentValue: 0,
      unit: 'đêm',
      isCompletedToday: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
    _checkStreakStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkStreakStatus() {
    final completedCount = _habits.where((h) => h.isCompletedToday).length;
    _checkedInToday = completedCount > 0;
  }

  Future<void> _loadProfileData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _profileService.getProfile(user.id);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  void _toggleHabit(HabitModel habit) {
    setState(() {
      habit.isCompletedToday = !habit.isCompletedToday;
      if (habit.isCompletedToday) {
        habit.currentValue = habit.targetValue;
      } else {
        habit.currentValue = 0;
      }
      _checkStreakStatus();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                habit.isCompletedToday ? Icons.check : Icons.replay,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.isCompletedToday
                    ? 'Xuất sắc! Đã hoàn thành: ${habit.title}'
                    : 'Đã hoàn tác: ${habit.title}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: habit.isCompletedToday ? const Color(0xFF059669) : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: habit.isCompletedToday ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
        ),
      ),
    );
  }

  void _increaseProgress(HabitModel habit) {
    setState(() {
      if (habit.unit == 'km' || habit.unit == 'lít') {
        habit.currentValue = (habit.currentValue + 0.5).clamp(0.0, habit.targetValue * 2);
      } else {
        habit.currentValue = (habit.currentValue + 10).clamp(0.0, habit.targetValue * 2);
      }

      if (habit.currentValue >= habit.targetValue) {
        habit.isCompletedToday = true;
      }
      _checkStreakStatus();
    });
  }

  void _deleteHabit(HabitModel habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162032),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 8),
            Text(
              'Xóa bài tập',
              style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn bỏ "${habit.title}" khỏi giáo án luyện tập hôm nay?',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY BỎ', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _habits.removeWhere((item) => item.id == habit.id);
                _checkStreakStatus();
              });
              Navigator.pop(ctx);
            },
            child: const Text('XÁC NHẬN XÓA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditHabitDialog([HabitModel? existingHabit]) {
    final titleController = TextEditingController(text: existingHabit?.title ?? '');
    final descController = TextEditingController(text: existingHabit?.description ?? '');
    final targetController = TextEditingController(
      text: existingHabit != null ? existingHabit.targetValue.toString() : '100',
    );
    final unitController = TextEditingController(text: existingHabit?.unit ?? 'cái');

    HabitCategory selectedCategory = existingHabit?.category ?? HabitCategory.values[_tabController.index];
    HabitType selectedType = existingHabit?.type ?? HabitType.quantitative;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Color(0xFF233352), width: 1.5),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              existingHabit == null ? Icons.sports_soccer : Icons.edit,
                              color: const Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            existingHabit == null ? 'THÊM BÀI TẬP KỶ LUẬT' : 'CHỈNH SỬA BÀI TẬP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      )
                    ],
                  ),
                  if (existingHabit == null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showPresetDialog();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoặc chọn từ Giáo Án Mẫu Pro ⚡',
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Gói tập CR7, Nhạc trưởng, Sát thủ vòng cấm...',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Color(0xFF38BDF8), size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  const Text('PHÂN LOẠI NHÓM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildCategoryChip('⚽ Kỹ thuật', HabitCategory.technical, selectedCategory, (cat) {
                        setModalState(() => selectedCategory = cat);
                      }),
                      const SizedBox(width: 8),
                      _buildCategoryChip('⚡ Thể lực', HabitCategory.fitness, selectedCategory, (cat) {
                        setModalState(() => selectedCategory = cat);
                      }),
                      const SizedBox(width: 8),
                      _buildCategoryChip('🥗 Dinh dưỡng', HabitCategory.nutrition, selectedCategory, (cat) {
                        setModalState(() => selectedCategory = cat);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Tên bài tập / Thói quen *',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      hintText: 'VD: Tâng bóng 2 chân, Sút phạt 20 quả...',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0B111E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Color(0xFFF8FAFC)),
                    decoration: InputDecoration(
                      labelText: 'Mục tiêu & Hướng dẫn kỹ thuật',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      hintText: 'VD: Rèn phản xạ đỡ bóng dính bước 1',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0B111E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('CƠ CHẾ ĐO LƯỜNG', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Định lượng (Số liệu)')),
                          selected: selectedType == HabitType.quantitative,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF0B111E),
                          side: BorderSide(
                            color: selectedType == HabitType.quantitative ? const Color(0xFF10B981) : const Color(0xFF233352),
                          ),
                          labelStyle: TextStyle(
                            color: selectedType == HabitType.quantitative ? Colors.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = HabitType.quantitative);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Định tính (Check-in)')),
                          selected: selectedType == HabitType.qualitative,
                          selectedColor: const Color(0xFF38BDF8),
                          backgroundColor: const Color(0xFF0B111E),
                          side: BorderSide(
                            color: selectedType == HabitType.qualitative ? const Color(0xFF38BDF8) : const Color(0xFF233352),
                          ),
                          labelStyle: TextStyle(
                            color: selectedType == HabitType.qualitative ? Colors.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = HabitType.qualitative);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (selectedType == HabitType.quantitative) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Chỉ tiêu mục tiêu',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF0B111E),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Đơn vị tính',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              hintText: 'cái, km, lít, phút...',
                              filled: true,
                              fillColor: const Color(0xFF0B111E),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập tên bài tập!')),
                            );
                            return;
                          }

                          final target = double.tryParse(targetController.text.trim()) ?? 1.0;

                          setState(() {
                            if (existingHabit == null) {
                              _habits.add(
                                HabitModel(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  category: selectedCategory,
                                  type: selectedType,
                                  targetValue: target,
                                  currentValue: 0,
                                  unit: selectedType == HabitType.quantitative ? unitController.text.trim() : 'lần',
                                  isCompletedToday: false,
                                ),
                              );
                            } else {
                              existingHabit.title = titleController.text.trim();
                              existingHabit.description = descController.text.trim();
                              existingHabit.category = selectedCategory;
                              existingHabit.type = selectedType;
                              existingHabit.targetValue = target;
                              existingHabit.unit = unitController.text.trim();
                            }
                            _checkStreakStatus();
                          });

                          Navigator.pop(ctx);
                        },
                        child: Text(
                          existingHabit == null ? '⚡ LƯU VÀO GIÁO ÁN' : 'CẬP NHẬT BÀI TẬP',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hiển thị Dialog chọn Giáo án mẫu (Preset Library)
  void _showPresetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF131D2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 22),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THƯ VIỆN GIÁO ÁN MẪU',
                                style: TextStyle(
                                  color: Color(0xFFF8FAFC),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Chọn gói bài tập bóng đá chuyên biệt để áp dụng ngay',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: PresetRepository.presets.length,
                    itemBuilder: (context, index) {
                      final preset = PresetRepository.presets[index];
                      return _buildPresetCard(preset, ctx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetCard(HabitPreset preset, BuildContext modalCtx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: preset.accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: preset.accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: preset.accentColor,
          iconColor: preset.accentColor,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: preset.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: preset.accentColor.withValues(alpha: 0.4)),
            ),
            child: Icon(preset.icon, color: preset.accentColor, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  preset.title,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: preset.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  preset.roleTag,
                  style: TextStyle(
                    color: preset.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              preset.subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 6),
                  const Text(
                    'DANH SÁCH BÀI TẬP TRONG GÓI:',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...preset.habits.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: preset.accentColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, size: 10, color: preset.accentColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.title,
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    h.type == HabitType.quantitative
                                        ? 'Mục tiêu: ${h.targetValue.toInt()} ${h.unit} • ${h.description}'
                                        : 'Hoàn thành / Check-in • ${h.description}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: preset.accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _applyPreset(preset);
                        Navigator.pop(modalCtx);
                      },
                      icon: const Icon(Icons.add_task, size: 18),
                      label: Text(
                        'ÁP DỤNG GÓI ${preset.roleTag.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(HabitPreset preset) {
    setState(() {
      for (var sample in preset.habits) {
        _habits.add(
          HabitModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_${sample.title.hashCode}',
            title: sample.title,
            description: sample.description,
            category: sample.category,
            type: sample.type,
            targetValue: sample.targetValue,
            currentValue: 0,
            unit: sample.unit,
            isCompletedToday: false,
          ),
        );
      }
      _checkStreakStatus();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã thêm ${preset.habits.length} bài tập từ "${preset.title}" vào giáo án!',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, HabitCategory cat, HabitCategory current, Function(HabitCategory) onSelect) {
    final isSelected = cat == current;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(cat),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0B111E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF233352),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : const Color(0xFF94A3B8),
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF233352)),
      ),
      builder: (ctx) {
        final email = _authService.currentUser?.email ?? 'baller@discipline.com';
        final name = _userProfile?.fullName ?? 'Cầu Thủ Sân Cỏ';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF38BDF8)]),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF0A0E17),
                      backgroundImage: (_userProfile?.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(_userProfile!.avatarUrl!)
                          : null,
                      child: (_userProfile?.avatarUrl == null || _userProfile!.avatarUrl!.isEmpty)
                          ? const Icon(Icons.sports_soccer, color: Color(0xFF10B981), size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${_userProfile?.position ?? 'Tiền đạo'} • Số #${_userProfile?.jerseyNumber ?? 10}',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFF233352)),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                ),
                title: const Text('Hồ sơ & Chỉ số Cầu thủ', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC), fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((_) => _loadProfileData());
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book, color: Color(0xFFF59E0B), size: 20),
                ),
                title: const Text('Nhật ký trận đấu', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC), fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MatchJournalScreen()),
                  );
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                ),
                title: const Text('Đăng xuất tài khoản', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _habits.where((h) => h.isCompletedToday).length;
    final totalCount = _habits.length;
    final progressPercent = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Dark pitch stadium base
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF233352), Colors.transparent],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BALLER DISCIPLINE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Color(0xFFF8FAFC),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Kỷ luật sân cỏ mỗi ngày',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: InkWell(
              onTap: _showUserMenu,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF38BDF8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF0A0E17),
                  backgroundImage: (_userProfile?.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
                  child: (_userProfile?.avatarUrl == null || _userProfile!.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Color(0xFF10B981), size: 19)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // 1. Hero Hub: Streak + Daily Ring/Bars (Trang trọng, hiện đại)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF131D2E), Color(0xFF18243A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF283856), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge Ngọn lửa Streak Pro
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            const Color(0xFFD97706).withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '$_streakDays NGÀY',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tiêu đề & trạng thái
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'CHUỖI KỶ LUẬT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF8FAFC),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _checkedInToday ? 'Đã rèn luyện hôm nay 🔥' : 'Chưa điểm danh hôm nay',
                            style: TextStyle(
                              fontSize: 11,
                              color: _checkedInToday ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Badge Hoàn thành
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E17),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.task_alt, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$completedCount/$totalCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF38BDF8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Gradient Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E17),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressPercent.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF38BDF8)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hoàn thành ${(progressPercent * 100).toInt()}% chỉ tiêu',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.shield, color: Color(0xFF38BDF8), size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Kỷ luật tạo nên nhà vô địch',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TabBar phân loại 3 nhóm: Kỹ thuật, Thể lực, Dinh dưỡng
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF131D2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF283856)),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.sports_soccer, size: 16),
                  text: 'Kỹ thuật',
                ),
                Tab(
                  icon: Icon(Icons.bolt, size: 16),
                  text: 'Thể lực',
                ),
                Tab(
                  icon: Icon(Icons.restaurant, size: 16),
                  text: 'Dinh dưỡng',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Danh sách bài tập
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHabitsList(HabitCategory.technical),
                _buildHabitsList(HabitCategory.fitness),
                _buildHabitsList(HabitCategory.nutrition),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Buttons: Cả 2 nút Preset & Thêm mới
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút Chọn Preset Mẫu
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: const Color(0xFF131D2E),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'btnPreset',
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF38BDF8),
              elevation: 0,
              onPressed: () => _showPresetDialog(),
              icon: const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF38BDF8)),
              label: const Text(
                'GIÁO ÁN MẪU',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nút Tạo Mới Tự Do
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'btnAddCustom',
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
              onPressed: () => _showAddEditHabitDialog(),
              icon: const Icon(Icons.add, size: 22, color: Colors.black),
              label: const Text(
                'TỰ TẠO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(HabitCategory category) {
    final filteredHabits = _habits.where((h) => h.category == category).toList();

    if (filteredHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF283856)),
              ),
              child: const Icon(Icons.sports_soccer, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có bài tập nào trong mục này',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bấm "THÊM BÀI TẬP" để lên giáo án ngay!',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 84, top: 2),
      itemCount: filteredHabits.length,
      itemBuilder: (context, index) {
        final habit = filteredHabits[index];
        return _buildHabitCard(habit);
      },
    );
  }

  Widget _buildHabitCard(HabitModel habit) {
    final isDone = habit.isCompletedToday;
    final isQuant = habit.type == HabitType.quantitative;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFF10B981) : const Color(0xFF283856),
          width: isDone ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
          if (isDone)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 10,
            )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút Check-in tròn phát sáng
                InkWell(
                  onTap: () => _toggleHabit(habit),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: isDone
                          ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                          : null,
                      color: isDone ? null : const Color(0xFF0A0E17),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                        width: 2,
                      ),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isDone ? Icons.check : Icons.circle_outlined,
                        color: isDone ? Colors.black : const Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nội dung bài tập
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDone ? const Color(0xFF94A3B8) : const Color(0xFFF8FAFC),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF64748B),
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          habit.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Menu thao tác
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF283856)),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showAddEditHabitDialog(habit);
                    } else if (val == 'delete') {
                      _deleteHabit(habit);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF38BDF8)),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text('Xóa bài tập', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Phần định lượng
            if (isQuant) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF283856)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.speed, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Chỉ tiêu: ${habit.currentValue % 1 == 0 ? habit.currentValue.toInt() : habit.currentValue} / ${habit.targetValue % 1 == 0 ? habit.targetValue.toInt() : habit.targetValue} ${habit.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF8FAFC),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _increaseProgress(habit),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: Colors.black),
                            SizedBox(width: 2),
                            Text(
                              'Ghi nhận thêm',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
