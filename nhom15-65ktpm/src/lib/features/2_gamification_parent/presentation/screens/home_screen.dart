import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/abacus_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/soroban_board_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storageService.getChildProfile();
    setState(() => _profile = profile);
    _audioService.speak(
      'Chào mừng bé đến với thế giới bàn tính Soroban! Bé chọn bài học nhé!',
    );
  }

  void _openFreePlayModal() {
    final controller = AbacusController(columnCount: 3);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
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
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🧮 ', style: TextStyle(fontSize: 26)),
                  Text(
                    'Bàn Tính Soroban Tự Do',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Bé hãy gảy các hạt bàn tính để xem số thay đổi nhé!',
                style: TextStyle(fontSize: 15, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SorobanBoardWidget(
                  controller: controller,
                  height: 220,
                  showLiveValue: true,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _audioService.speak(
                    'Số hiện tại là ${controller.totalValue}',
                  );
                },
                icon: const Icon(Icons.volume_up, size: 24),
                label: const Text('Đọc Số Này Cho Bé Nghe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
                  // Huy hiệu Streak
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          '${_profile?.streakCount ?? 3} Ngày',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút Cổng Phụ Huynh (Parental Gate)
                  IconButton(
                    onPressed: () {
                      ParentalGateDialog.show(
                        context,
                        onPass: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentDashboardScreen(),
                            ),
                          );
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
                            color: Colors.black.withOpacity(0.08),
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
              const SizedBox(height: 16),

              // Linh vật hoạt hình Mascot
              MascotBubbleWidget(
                speechText:
                    'Hôm nay bé muốn gảy bàn tính hay thi đấu tính nhẩm nhanh nè?',
                onMascotTap: () {
                  _audioService.speak(
                    'Hôm nay bé muốn gảy bàn tính hay thi đấu tính nhẩm nhanh nè?',
                  );
                },
              ),
              const SizedBox(height: 24),

              // Danh sách 3 Cấp độ học tập dạng thẻ to rực rỡ
              _buildLevelCard(
                title: 'CẤP ĐỘ 1: HẠT NHỎ NHẬN DIỆN',
                subtitle: 'Làm quen hạt trên (5), hạt dưới (1) và cộng trừ trực tiếp',
                color: AppColors.secondary,
                emoji: '🌱',
                badgeText: 'Cơ Bản',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 2: ANH BẠN NHỎ',
                subtitle: 'Công thức cộng trừ kết hợp hạt 5 (+4 = +5 - 1)',
                color: AppColors.primary,
                emoji: '⭐',
                badgeText: 'Nâng Cao',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 3: FLASH ANZAN',
                subtitle: 'Tính nhẩm nhanh với các con số chớp nhoáng trên màn hình',
                color: AppColors.accentPurple,
                emoji: '⚡',
                badgeText: 'Siêu Tốc',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FlashAnzanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Nút Bàn tính tự do
              OutlinedButton.icon(
                onPressed: _openFreePlayModal,
                icon: const Icon(Icons.touch_app, size: 26),
                label: const Text('BÀN TÍNH TỰ DO (CHƠI TỰ DO)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
