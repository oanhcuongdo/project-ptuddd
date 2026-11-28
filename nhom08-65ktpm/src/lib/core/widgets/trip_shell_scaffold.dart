import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Khung chứa 4 tab cố định của không gian chuyến đi:
/// 0: Chuẩn bị (Module 1) | 1: Quỹ MoMo (Module 2) | 2: Lịch trình (Module 3) | 3: Ngân sách (Module 4)
class TripShellScaffold extends StatelessWidget {
  const TripShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: AppColors.outlineVariantSoft),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 64,
              backgroundColor: AppColors.surfaceContainerLow,
              indicatorColor: AppColors.primaryContainer,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 22,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  key: Key('nav_tab_checklist'),
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'Chuẩn bị',
                ),
                NavigationDestination(
                  key: Key('nav_tab_momo'),
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: 'Quỹ MoMo',
                ),
                NavigationDestination(
                  key: Key('nav_tab_itinerary'),
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Lịch trình',
                ),
                NavigationDestination(
                  key: Key('nav_tab_budget'),
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Ngân sách',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
