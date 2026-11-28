import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth_profile/presentation/providers/auth_provider.dart';
import '../../features/auth_profile/presentation/screens/profile_tab.dart';
import '../../features/buddy_matching/presentation/screens/buddy_matching_tab.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/chat/presentation/screens/chat_rooms_tab.dart';
import '../../features/chat/presentation/screens/streak_dashboard_tab.dart';
import '../../features/vocab_notebook/presentation/screens/vocab_notebook_tab.dart';
import 'components/main_header.dart';
import 'components/main_nav_sidebar.dart';
import 'components/nav_item.dart';
import 'styles/main_layout_styles.dart';

/// Khung bố cục chính của toàn ứng dụng kiểu Web Dashboard:
/// - Bên trái: `MainNavSidebar` (danh sách NavLink chuyển trang).
/// - Bên phải phía trên: `MainHeader` (tiêu đề trang, Streak, tài khoản).
/// - Phần còn lại: `Outlet` (hiển thị nội dung trang theo NavLink đang chọn).
/// Tự động tương thích Mobile (< 850px) bằng Drawer + NavigationBar.
class MainLayout extends StatefulWidget {
  final int initialIndex;

  /// Cho phép truyền trực tiếp nội dung Outlet tùy chỉnh nếu cần dùng lại vỏ Layout ở route con.
  final Widget? outlet;

  const MainLayout({
    super.key,
    this.initialIndex = 0,
    this.outlet,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  bool _isSidebarCollapsed = false;

  static const List<MainNavItem> _navItems = [
    MainNavItem(
      id: 'chat',
      label: 'Phòng học',
      headerTitle: '',
      headerSubtitle: '',
      section: 'Không gian học',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      page: ChatRoomsTab(),
    ),
    MainNavItem(
      id: 'streak',
      label: 'Bảng chuỗi',
      headerTitle: '',
      headerSubtitle: '',
      section: 'Không gian học',
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department_rounded,
      page: StreakDashboardTab(),
    ),
    MainNavItem(
      id: 'buddy',
      label: 'Bạn đồng hành',
      headerTitle: 'Tìm bạn đồng hành',
      headerSubtitle: 'Ghép cặp bạn luyện nói theo ngôn ngữ và trình độ phù hợp',
      section: 'Không gian học',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      page: BuddyMatchingTab(),
    ),
    MainNavItem(
      id: 'vocab',
      label: 'Sổ tay',
      headerTitle: '',
      headerSubtitle: '',
      section: 'Không gian học',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      page: VocabNotebookTab(),
    ),
    MainNavItem(
      id: 'profile',
      label: 'Hồ sơ',
      headerTitle: 'Hồ sơ cá nhân',
      headerSubtitle: 'Quản lý thông tin tài khoản, ngôn ngữ và mục tiêu học tập',
      section: 'Tài khoản',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      page: ProfileTab(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _navItems.length - 1);
  }

  void _selectNav(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  int get _profileNavIndex =>
      _navItems.indexWhere((item) => item.id == 'profile');

  int get _streakNavIndex =>
      _navItems.indexWhere((item) => item.id == 'streak');

  void _openStreakDashboard() {
    _selectNav(_streakNavIndex);
    final profile = context.read<AuthProvider>().currentProfile;
    if (profile != null) {
      context.read<ChatProvider>().loadStreakBoard(
            userId: profile.userId,
            dailyGoalMinutes: profile.dailyGoalMinutes,
          );
    }
  }

  Widget _buildOutlet() {
    if (widget.outlet != null) {
      return widget.outlet!;
    }
    return IndexedStack(
      index: _currentIndex,
      children: _navItems.map((item) => item.page).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _navItems[_currentIndex];
    final auth = context.read<AuthProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= MainLayoutStyles.desktopBreakpoint;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: MainLayoutStyles.outletBg,
            body: Row(
              children: [
                MainNavSidebar(
                  items: _navItems,
                  selectedIndex: _currentIndex,
                  onSelect: _selectNav,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () => setState(
                    () => _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                  onSignOut: auth.signOut,
                ),
                Expanded(
                  child: Column(
                    children: [
                      MainHeader(
                        currentItem: currentItem,
                        onOpenProfile: () => _selectNav(_profileNavIndex),
                        onOpenStreakBoard: _openStreakDashboard,
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: MainLayoutStyles.outletBg,
                          child: _buildOutlet(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Bố cục Mobile (< 850px): giữ trải nghiệm gọn nhẹ bằng Drawer + Bottom NavigationBar
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: MainLayoutStyles.outletBg,
          drawer: Drawer(
            width: MainLayoutStyles.sidebarWidthExpanded,
            child: SafeArea(
              child: MainNavSidebar(
                items: _navItems,
                selectedIndex: _currentIndex,
                onSelect: (index) {
                  _selectNav(index);
                  Navigator.of(context).pop();
                },
                onSignOut: () {
                  Navigator.of(context).pop();
                  auth.signOut();
                },
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                MainHeader(
                  currentItem: currentItem,
                  showMenuButton: true,
                  onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  onOpenProfile: () => _selectNav(_profileNavIndex),
                  onOpenStreakBoard: _openStreakDashboard,
                ),
                Expanded(child: _buildOutlet()),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectNav,
            destinations: _navItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
