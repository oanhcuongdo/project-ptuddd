import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';
import 'module_placeholder_screen.dart';

/// Mục điều hướng trong khung ứng dụng
class AppNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Màn hình chính (HomeScreen) - Trang chủ tổng quan & Khung điều hướng
/// HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN
class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({
    super.key,
    this.title = 'HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  Map<String, dynamic>? _userProfile;

  static const List<AppNavItem> _navItems = [
    AppNavItem(
      label: 'Tổng quan',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    AppNavItem(
      label: 'Kho đồ án',
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
    ),
    AppNavItem(
      label: 'AI gợi ý',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
    ),
    AppNavItem(
      label: 'Đề tài cá nhân',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    AppNavItem(
      label: 'Kế hoạch',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
    AppNavItem(
      label: 'Hồ sơ',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!SupabaseConfig.isInitialized) return;

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _userProfile = data;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSignOut() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text(
              'Xác nhận đăng xuất',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textLight,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Đã đăng xuất khỏi hệ thống thành công.'),
            ],
          ),
          backgroundColor: AppColors.primaryAction,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Lỗi khi đăng xuất: $e')),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _onNavDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 840;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Row(
            children: [
              // Thanh điều hướng thanh lịch cho Desktop Windows
              if (isWideScreen) _buildSidebar(constraints.maxWidth >= 1150),

              // Vùng nội dung chính với Header phân cấp rõ nét
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(
                      child: Container(
                        color: AppColors.surfaceAlt,
                        child: _buildCurrentView(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWideScreen
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onNavDestinationSelected,
                    backgroundColor: AppColors.surface,
                    indicatorColor: AppColors.primaryBackground,
                    height: 64,
                    destinations: _navItems.map((item) {
                      return NavigationDestination(
                        icon: Icon(item.icon, size: 20),
                        selectedIcon: Icon(item.activeIcon, color: AppColors.primaryAction, size: 22),
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }

  /// Sidebar Desktop thanh lịch, nhẹ nhàng, có phân chia thương hiệu rõ ràng
  Widget _buildSidebar(bool extended) {
    return Container(
      width: extended ? 240 : 76,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Tên ứng dụng tinh tế ở góc Sidebar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAction,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'HỖ TRỢ ĐỒ ÁN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Danh sách các mục điều hướng
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Material(
                    color: isSelected ? AppColors.primaryBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _onNavDestinationSelected(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: extended ? 12 : 0,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 20,
                              color: isSelected ? AppColors.primaryAction : AppColors.textSecondary,
                            ),
                            if (extended) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primaryAction : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.border),
          // Nút Đăng xuất ở chân Sidebar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: _isLoggingOut ? null : _handleSignOut,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: extended ? 12 : 0,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger,
                              ),
                            )
                          : const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                      if (extended) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header hiện đại: hiển thị tiêu đề hệ thống chuẩn hóa & tài khoản người dùng
  Widget _buildTopHeader() {
    User? currentUser;
    try {
      if (SupabaseConfig.isInitialized) {
        currentUser = supabase.auth.currentUser;
      }
    } catch (_) {
      currentUser = null;
    }

    final userEmail = currentUser?.email ?? 'sinhvien@e.tlu.edu.vn';
    final userFullName = _userProfile?['full_name'] as String? ??
        currentUser?.userMetadata?['full_name'] as String? ??
        userEmail.split('@').first;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin người dùng nhỏ gọn trên Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.primaryAction,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userFullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: _isLoggingOut ? null : _handleSignOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return const ModulePlaceholderScreen(
          moduleTitle: 'Kho đồ án tốt nghiệp',
          assignee: 'TV2 – Phạm Kim Anh',
          description:
              'Tra cứu, tìm kiếm và tham khảo danh sách các đồ án tốt nghiệp khóa trước. '
              'Bao gồm bộ lọc chuyên ngành, xem chi tiết đồ án, quản lý đồ án yêu thích '
              'và đề xuất bổ sung đồ án.',
          icon: Icons.library_books_rounded,
        );
      case 2:
        return const ModulePlaceholderScreen(
          moduleTitle: 'AI gợi ý & đối chiếu đề tài',
          assignee: 'TV3 – Trần Đức Trung',
          description:
              'Phân tích định hướng, nguyện vọng của sinh viên để đề xuất 3-5 đề tài phù hợp. '
              'Hệ thống tự động đối chiếu với dữ liệu kho đồ án đã duyệt để hạn chế trùng lặp ý tưởng.',
          icon: Icons.auto_awesome_rounded,
        );
      case 3:
        return const ModulePlaceholderScreen(
          moduleTitle: 'Quản lý đề tài cá nhân',
          assignee: 'TV4 – Trịnh Mạnh Đức',
          description:
              'Lưu trữ và quản lý các ý tưởng đề tài cá nhân hoặc lưu từ gợi ý của AI. '
              'Cho phép thêm mới, chỉnh sửa, xóa và theo dõi trạng thái đề tài cá nhân.',
          icon: Icons.assignment_rounded,
        );
      case 4:
        return const ModulePlaceholderScreen(
          moduleTitle: 'Kế hoạch & tiến độ thực hiện',
          assignee: 'TV5 – Vương Tiến Dũng',
          description:
              'Xây dựng kế hoạch chi tiết, phân chia các đầu việc, đặt thời hạn '
              'và theo dõi tiến độ hoàn thành các giai đoạn của đồ án tốt nghiệp.',
          icon: Icons.calendar_month_rounded,
        );
      case 5:
        return _buildProfileTab();
      default:
        return _buildOverviewTab();
    }
  }

  /// Tab 0: Trang chủ tổng quan - Bố cục gọn gàng, giảm bóng đổ, tăng tính phân cấp
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Banner chào hỏi tinh tế
              _buildGreetingBanner(),
              const SizedBox(height: 24),

              // 2. Khu vực thống kê tổng quan (không giả lập số liệu)
              _buildStatsOverviewSection(),
              const SizedBox(height: 28),

              // 3. Khu vực truy cập nhanh 5 module
              _buildQuickAccessSection(),
              const SizedBox(height: 28),

              // 4. Khu vực hoạt động gần đây
              _buildRecentActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner chào đón nhẹ nhàng, nền trắng, điểm nhấn xanh tím tinh tế
  Widget _buildGreetingBanner() {
    User? currentUser;
    try {
      if (SupabaseConfig.isInitialized) {
        currentUser = supabase.auth.currentUser;
      }
    } catch (_) {
      currentUser = null;
    }

    final userEmail = currentUser?.email ?? 'sinhvien@e.tlu.edu.vn';
    final userFullName = _userProfile?['full_name'] as String? ??
        currentUser?.userMetadata?['full_name'] as String? ??
        userEmail.split('@').first;
    final userRole = (_userProfile?['role'] as String? ?? 'student').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primaryAction,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Xin chào, $userFullName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryAction,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khu vực thống kê: Card gọn, viền mảnh, rõ ràng thông số
  Widget _buildStatsOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan đồ án',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 640;

            if (isNarrow) {
              return Column(
                children: [
                  _buildStatCard(
                    title: 'Đề tài kho đồ án',
                    value: '0',
                    subtitle: 'Đồ án đã duyệt',
                    icon: Icons.library_books_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'Đề tài đã lưu',
                    value: '0',
                    subtitle: 'Ý tưởng cá nhân',
                    icon: Icons.bookmark_border_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    title: 'Tiến độ hoàn thành',
                    value: '0%',
                    subtitle: 'Kế hoạch hiện tại',
                    icon: Icons.trending_up_rounded,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Đề tài kho đồ án',
                    value: '0',
                    subtitle: 'Đồ án đã duyệt',
                    icon: Icons.library_books_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'Đề tài đã lưu',
                    value: '0',
                    subtitle: 'Ý tưởng cá nhân',
                    icon: Icons.bookmark_border_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tiến độ hoàn thành',
                    value: '0%',
                    subtitle: 'Kế hoạch hiện tại',
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryAction, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khu vực truy cập nhanh 5 module: Card phẳng, phân cấp tốt
  Widget _buildQuickAccessSection() {
    final modules = [
      _QuickAccessItem(
        title: 'Kho đồ án',
        subtitle: 'Tra cứu & tham khảo đề tài khóa trước',
        icon: Icons.library_books_rounded,
        assignee: 'TV2',
        targetIndex: 1,
      ),
      _QuickAccessItem(
        title: 'AI gợi ý đề tài',
        subtitle: 'Gợi ý & đối chiếu hướng nghiên cứu',
        icon: Icons.auto_awesome_rounded,
        assignee: 'TV3',
        targetIndex: 2,
      ),
      _QuickAccessItem(
        title: 'Đề tài cá nhân',
        subtitle: 'Quản lý danh sách đề tài tự chọn',
        icon: Icons.assignment_rounded,
        assignee: 'TV4',
        targetIndex: 3,
      ),
      _QuickAccessItem(
        title: 'Kế hoạch & tiến độ',
        subtitle: 'Lập danh sách đầu việc & mốc thời gian',
        icon: Icons.calendar_month_rounded,
        assignee: 'TV5',
        targetIndex: 4,
      ),
      _QuickAccessItem(
        title: 'Hồ sơ cá nhân',
        subtitle: 'Thông tin tài khoản, lớp, chuyên ngành',
        icon: Icons.person_rounded,
        assignee: 'TV1',
        targetIndex: 5,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Truy cập nhanh',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 960
                ? 3
                : (constraints.maxWidth >= 600 ? 2 : 1);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _onNavDestinationSelected(module.targetIndex),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              module.icon,
                              color: AppColors.primaryAction,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        module.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      module.assignee,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  module.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Khu vực hoạt động gần đây: Trạng thái trống gọn gàng, tinh tế
  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 28,
                  color: AppColors.secondary,
                ),
                SizedBox(height: 10),
                Text(
                  'Chưa có hoạt động nào gần đây',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Các thao tác tra cứu, lưu đề tài và cập nhật tiến độ sẽ xuất hiện tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tab 5: Hồ sơ cá nhân
  Widget _buildProfileTab() {
    User? currentUser;
    try {
      if (SupabaseConfig.isInitialized) {
        currentUser = supabase.auth.currentUser;
      }
    } catch (_) {
      currentUser = null;
    }

    final userEmail = currentUser?.email ?? 'Chưa xác định';
    final userFullName = _userProfile?['full_name'] as String? ??
        currentUser?.userMetadata?['full_name'] as String? ??
        'Chưa cập nhật';
    final studentCode = _userProfile?['student_code'] as String? ?? 'Chưa cập nhật';
    final className = _userProfile?['class_name'] as String? ?? 'Chưa cập nhật';
    final major = _userProfile?['major'] as String? ?? 'Công nghệ phần mềm';
    final role = _userProfile?['role'] as String? ?? 'student';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userFullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),

                _buildProfileInfoRow('Vai trò', role.toUpperCase()),
                _buildProfileInfoRow('Mã sinh viên', studentCode),
                _buildProfileInfoRow('Lớp sinh hoạt', className),
                _buildProfileInfoRow('Chuyên ngành', major),

                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Nút Đăng xuất
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _handleSignOut,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.danger,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    label: Text(
                      _isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất tài khoản',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.danger,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String assignee;
  final int targetIndex;

  _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.assignee,
    required this.targetIndex,
  });
}
