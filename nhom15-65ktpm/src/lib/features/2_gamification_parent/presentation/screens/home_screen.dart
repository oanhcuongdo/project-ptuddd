import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart';
import '../widgets/parental_gate_dialog.dart';
import 'parent_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  ChildProfile? _profile;
  bool _showReminderBanner = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storageService.getChildProfile();
    final reminderSettings = await ReminderService.getSettings();
    final showReminder = ReminderService.shouldShowInAppReminder(
      settings: reminderSettings,
      profile: profile,
    );

    if (mounted) {
      setState(() {
        _profile = profile;
        _showReminderBanner = showReminder;
      });
    }

    _audioService.speak(
      'Chào mừng bé đến với thế giới Finger Math toán ngón tay kỳ diệu! Bé chọn bài học nhé!',
    );
  }

  void _openFreePlayModal() {
    final fingerController = FingerMathController(showLeftHand: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✋ ', style: TextStyle(fontSize: 24)),
                  Text(
                    'Bàn Tay Finger Math Tự Do',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Bé chạm vào các ngón trên Tay Phải (đơn vị: 0-9) và Tay Trái (hàng chục: 10-90) nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FingerMathBoardWidget(
                  controller: fingerController,
                  height: 230,
                  showLiveValue: true,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _audioService.speak(fingerController.speechDescription);
                },
                icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                label: const Text(
                  'Đọc Số Bàn Tay Này 🔊',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh tiêu đề trên cùng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Chuỗi ngày học, ${_profile?.streakCount ?? 1} ngày',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Center(
                        child: Text('🔥', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),

                  // Nút Cổng Phụ Huynh (Parental Gate)
                  IconButton(
                    tooltip: 'Phụ huynh',
                    onPressed: () {
                      ParentalGateDialog.show(
                        context,
                        onPass: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentDashboardScreen(),
                            ),
                          ).then((_) => _loadProfile());
                        },
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: AppColors.textLight,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Banner nhắc nhở học cố định 19:00 (nếu đến giờ mà chưa luyện tập hôm nay)
              if (_showReminderBanner) _buildReminderBanner(),

              const SizedBox(height: 12),

              // Linh vật hoạt hình Mascot
              MascotBubbleWidget(
                speechText:
                    'Hôm nay bé muốn đếm ngón tay Finger Math hay thi đấu tính nhẩm nhanh nè?',
                onMascotTap: () {
                  _audioService.speak(
                    'Hôm nay bé muốn đếm ngón tay Finger Math hay thi đấu tính nhẩm nhanh nè?',
                  );
                },
              ),
              const SizedBox(height: 24),

              // Danh sách 3 Cấp độ học tập dạng thẻ to rực rỡ
              _buildLevelCard(
                title: 'CẤP ĐỘ 1: FINGER MATH CƠ BẢN',
                subtitle:
                    'Đếm ngón 0-9: Tay Phải hàng đơn vị, Tay Trái hàng chục',
                color: AppColors.secondary,
                emoji: '✌️',
                badgeText: 'Cơ Bản',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 1),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 2: ANH BẠN NHỎ & ANH BẠN LỚN',
                subtitle:
                    'Công thức xòe/gập ngón tay: +4 = +5 - 1, +9 = +10 - 1',
                color: AppColors.primary,
                emoji: '👍',
                badgeText: 'Công Thức',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 2),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 3: FLASH ANZAN FINGER MATH',
                subtitle: 'Tính nhẩm nhanh siêu tốc bằng 2 bàn tay (0 - 99)',
                color: AppColors.accentPurple,
                emoji: '⚡',
                badgeText: 'Siêu Tốc',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FlashAnzanScreen(),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 20),

              // Nút Bàn tay Finger Math tự do
              OutlinedButton(
                onPressed: _openFreePlayModal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  minimumSize: const Size(48, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('✋', style: TextStyle(fontSize: 34)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã 19:00 rồi! Giờ luyện tập Finger Math!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Cùng luyện tập để giữ ngọn lửa chuỗi Streak nhé bé ơi! 🔥',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LessonPlayScreen(level: 1),
                      ),
                    ).then((_) => _loadProfile());
                  },
                  child: const Text(
                    '👉 Bắt đầu ngay!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
            onPressed: () => setState(() => _showReminderBanner = false),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String subtitle,
    required Color color,
    required String emoji,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$title. $subtitle. $badgeText',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: badgeText == 'Công Thức'
                  ? AppColors.accentYellow
                  : Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
