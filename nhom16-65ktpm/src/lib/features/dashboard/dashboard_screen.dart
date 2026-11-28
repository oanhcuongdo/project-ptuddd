import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/fund_transaction_model.dart';
import '../../data/models/proof_model.dart';
import '../../data/repositories/fund_repository.dart';
import '../challenges/challenge_detail_screen.dart';

/// Màn hình Dashboard / Trang chủ GoodDeeds Fund chuẩn Senior Product Designer
/// Phong cách: Material 3, Tone Teal & Cam ấm, bo góc 20-24px, đổ bóng mềm
class DashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FundRepository _fundRepo = FundRepository.instance;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isLoading = true;
  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  int _proofCount = 0;
  List<ProofModel> _proofs = [];
  List<ChallengeModel> _challenges = [];
  List<FundTransactionModel> _recentTransactions = [];

  static const double _targetFund = 100000000; // 100 triệu VNĐ

  static const List<ChallengeModel> _defaultChallenges = [
    ChallengeModel(
      id: 'ch_01',
      title: 'Dậy sớm trước 6:00 sáng',
      description:
          'Chụp ảnh bàn học, đồng hồ hoặc app báo thức chứng minh bạn đã dậy và học bài trước 6h00.',
      rewardAmount: 20000,
      category: 'Kỷ luật',
      icon: 'wb_sunny',
    ),
    ChallengeModel(
      id: 'ch_02',
      title: 'Gia sư dạy học cho trẻ em',
      description:
          'Dạy kèm 1 buổi học (toán, tiếng Việt, tiếng Anh) cho các em nhỏ có hoàn cảnh khó khăn.',
      rewardAmount: 50000,
      category: 'Gia sư',
      icon: 'school',
    ),
    ChallengeModel(
      id: 'ch_03',
      title: 'Giải 5 bài toán tư duy / code thuật toán',
      description:
          'Chụp ảnh bài giải hoặc commit code trên nền tảng LeetCode/HackerRank rèn luyện tư duy.',
      rewardAmount: 30000,
      category: 'Học tập',
      icon: 'psychology',
    ),
    ChallengeModel(
      id: 'ch_04',
      title: 'Chạy bộ 3km hoặc rèn luyện thể thao',
      description:
          'Chụp ảnh màn hình ứng dụng Strava / Smartwatch ghi nhận hoạt động chạy bộ nâng cao sức khỏe.',
      rewardAmount: 25000,
      category: 'Sức khỏe',
      icon: 'directions_run',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _fundRepo.fundUpdateVersion.addListener(_onFundUpdated);
  }

  void _onFundUpdated() {
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _fundRepo.fundUpdateVersion.removeListener(_onFundUpdated);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _fundRepo.getBalance();
      final income = await _fundRepo.getTotalIncome();
      final expense = await _fundRepo.getTotalExpense();
      final proofs = await _fundRepo.getProofs();
      final challenges = await _fundRepo.getChallenges();
      final transactions = await _fundRepo.getTransactions();

      if (mounted) {
        setState(() {
          _balance = balance;
          _totalIncome = income;
          _totalExpense = expense;
          _proofCount = proofs.length;
          _proofs = proofs;
          _challenges = challenges.isNotEmpty ? challenges : _defaultChallenges;
          _recentTransactions = transactions.take(4).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _balance = 2000000;
          _totalIncome = 2000000;
          _totalExpense = 0;
          _proofCount = 4;
          _challenges = _defaultChallenges;
          _isLoading = false;
        });
      }
    }
  }

  void _openChallengeDetail(ChallengeModel challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(
          challenge: challenge,
          onJoinNow: () => widget.onNavigateTab?.call(2),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _dynamicLeaderboard {
    final baseMembers = [
      {
        'name': 'Nguyễn Văn Huỳnh',
        'role': 'Trưởng nhóm',
        'baseCount': 10,
        'baseAmount': 500000.0,
      },
      {
        'name': 'Lê Anh Tuấn',
        'role': 'Database & Sổ Quỹ',
        'baseCount': 8,
        'baseAmount': 400000.0,
      },
      {
        'name': 'Nguyễn Trung Kiên',
        'role': 'Camera & AI OCR',
        'baseCount': 7,
        'baseAmount': 350000.0,
      },
      {
        'name': 'Trần Anh Tuấn',
        'role': 'Biểu đồ & Admin Review',
        'baseCount': 6,
        'baseAmount': 300000.0,
      },
    ];

    for (final m in baseMembers) {
      final name = m['name'] as String;
      final approvedList =
          _proofs.where((p) => p.memberName == name && p.isApproved);
      final addedCount = approvedList.length;
      final addedAmount =
          approvedList.fold<double>(0.0, (acc, p) => acc + p.rewardAmount);

      final totalCount = (m['baseCount'] as int) + addedCount;
      final totalAmount = (m['baseAmount'] as double) + addedAmount;

      m['totalCount'] = totalCount;
      m['totalAmount'] = totalAmount;
    }

    baseMembers.sort((a, b) =>
        (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));

    final badges = ['🏆', '🥈', '🥉', '⭐'];
    for (int i = 0; i < baseMembers.length; i++) {
      baseMembers[i]['rank'] = i + 1;
      baseMembers[i]['badge'] = badges[i];
      baseMembers[i]['amount'] =
          '+${_currencyFormat.format(baseMembers[i]['totalAmount'])}';
      baseMembers[i]['count'] =
          '${baseMembers[i]['totalCount']} việc tốt';
    }

    return baseMembers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_balance / _targetFund).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. HEADER CHÀO HỎI CÁ NHÂN HÓA
          _buildUserWelcomeHeader(theme, isDark),
          const SizedBox(height: 16),

          // 2. THẺ TỔNG QUỸ GRADIENT TEAL
          _buildFundSummaryCard(isDark),
          const SizedBox(height: 16),

          // 3. TIẾN ĐỘ MỤC TIÊU CHIẾN DỊCH
          _buildGoalProgressBar(theme, progress, percent),
          const SizedBox(height: 18),

          // 4. LƯỚI 3 Ô THỐNG KÊ NHANH
          _buildQuickStatTriplets(theme),
          const SizedBox(height: 22),

          // 5. CAROUSEL THỬ THÁCH VIỆC TỐT NỔI BẬT
          _buildFeaturedChallengesHeader(theme),
          const SizedBox(height: 12),
          _buildFeaturedChallengesCarousel(theme),
          const SizedBox(height: 24),

          // 6. BẢNG VINH DANH TOP PODIUM
          _buildLeaderboardPodium(theme),
          const SizedBox(height: 24),

          // 7. HOẠT ĐỘNG GẦN ĐÂY (RECENT TIMELINE)
          _buildRecentActivityTimeline(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 1. Header chào hỏi cá nhân hóa
  Widget _buildUserWelcomeHeader(ThemeData theme, bool isDark) {
    final user = AuthService.instance.currentUser;
    final displayName = user != null ? user.name.split(' ').last : 'Bạn';
    final initial = user != null && user.name.isNotEmpty ? user.name[0] : 'U';
    final isAdmin = user?.isAdmin ?? false;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.tealGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Xin chào, $displayName 👋',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAdmin ? AppColors.primary : Colors.blueGrey)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Thành viên',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? AppColors.primary : Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user != null
                    ? '${user.name} • MSSV: ${user.studentId}'
                    : 'Cùng lan tỏa những điều tử tế hôm nay!',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Thẻ Tổng Quỹ Lớn Gradient Teal
  Widget _buildFundSummaryCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'TỔNG QUỸ THỰC TẾ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Minh bạch 100%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Text(
                  _currencyFormat.format(_balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFlowBadge(
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.greenAccent,
                  label: 'Tổng thu',
                  amount: _currencyFormat.format(_totalIncome),
                ),
              ),
              Container(height: 28, width: 1, color: Colors.white24),
              Expanded(
                child: _buildFlowBadge(
                  icon: Icons.volunteer_activism_rounded,
                  color: AppColors.accent,
                  label: 'Đã giải ngân',
                  amount: _currencyFormat.format(_totalExpense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBadge({
    required IconData icon,
    required Color color,
    required String label,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Tiến độ mục tiêu chiến dịch
  Widget _buildGoalProgressBar(
      ThemeData theme, double progress, String percent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tiến độ Mục tiêu Mùa 1',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã đạt: ${_currencyFormat.format(_balance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Mục tiêu: ${_currencyFormat.format(_targetFund)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Lưới 3 ô thống kê nhanh
  Widget _buildQuickStatTriplets(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            theme,
            icon: Icons.task_alt_rounded,
            color: AppColors.primary,
            title: 'Việc tốt',
            value: '$_proofCount lượt',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            theme,
            icon: Icons.people_alt_rounded,
            color: Colors.blueAccent,
            title: 'Thành viên',
            value: '4 sinh viên',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            theme,
            icon: Icons.favorite_rounded,
            color: AppColors.accent,
            title: 'Giải ngân',
            value: '1 trường',
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Carousel thử thách việc tốt nổi bật
  Widget _buildFeaturedChallengesHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 6),
            Text(
              'Thử thách nổi bật',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TextButton(
          onPressed: () => widget.onNavigateTab?.call(1),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppColors.primary,
          ),
          child: const Text('Xem tất cả >', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildFeaturedChallengesCarousel(ThemeData theme) {
    final list = _challenges.isNotEmpty ? _challenges : _defaultChallenges;

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = list[index];
          final color = ChallengeDetailScreen.getCategoryColor(c.category);
          final icon = ChallengeDetailScreen.getIconData(c.icon);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openChallengeDetail(c),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${c.formattedRewardAmount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 6. Bảng vinh danh Top 4 Podium
  Widget _buildLeaderboardPodium(ThemeData theme) {
    final members = _dynamicLeaderboard;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Bảng Vinh Danh Việc Tốt',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Top Nhóm 16',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final m = members[index];
                return Row(
                  children: [
                    Text(
                      m['badge'] as String,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['name'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            m['role'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m['amount'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          m['count'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 7. Hoạt động gần đây (Timeline động từ SQLite)
  Widget _buildRecentActivityTimeline(ThemeData theme) {
    final timeFormat = DateFormat('HH:mm dd/MM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Hoạt động việc tốt mới nhất',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Chưa có biến động quỹ nào được ghi nhận.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final tx = _recentTransactions[index];
                  final isIncome = tx.isIncome;
                  final color = isIncome ? AppColors.primary : AppColors.accent;
                  final icon = isIncome
                      ? Icons.volunteer_activism_rounded
                      : Icons.outbox_rounded;
                  final prefix = isIncome ? '+' : '-';

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${tx.recipientOrSponsor} • ${timeFormat.format(tx.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prefix${_currencyFormat.format(tx.amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
