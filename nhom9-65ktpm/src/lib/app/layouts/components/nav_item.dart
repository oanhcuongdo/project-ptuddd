import 'package:flutter/material.dart';

/// Mô tả một mục điều hướng (NavLink) dùng chung cho Sidebar (Chrome) và BottomNav (Mobile).
/// Khi thêm phân hệ mới chỉ cần thêm 1 phần tử MainNavItem vào danh sách.
class MainNavItem {
  final String id;
  final String label;
  final String headerTitle;
  final String headerSubtitle;
  final String section;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const MainNavItem({
    required this.id,
    required this.label,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}
