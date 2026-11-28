import 'package:flutter/material.dart';

import '../../features/notes/presentation/pages/notes_page.dart';
import '../di/app_dependencies.dart';
import '../theme/app_theme.dart';
import 'coming_soon_page.dart';

/// Khung điều hướng chính của app: 4 tab cố định theo mockup
/// `02_notes_google_keep_inspired.png` (thanh tab dưới đáy, icon + nhãn).
///
/// Nhóm đã chốt 4 tab đích: **Ghi chú – Nhật ký – Thống kê – Cài đặt**
/// (`docs/ui_ux.md` mục 9). Hiện chỉ tab Ghi chú có tính năng; ba tab còn lại
/// hiển thị `ComingSoonPage` cho tới khi #5, #17 và màn cài đặt được merge.
///
/// `IndexedStack` giữ nguyên trạng thái từng tab (từ khoá tìm kiếm, kiểu
/// lưới/danh sách) khi người dùng chuyển qua lại.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.notesDependencies,
    this.notesActions = const <Widget>[],
    super.key,
  });

  /// Dependency dùng chung cho tab Ghi chú (notes + quiz scores).
  final AppDependencies notesDependencies;

  /// Hành động trên AppBar của tab Ghi chú, do nơi điều hướng truyền vào
  /// (ví dụ nút đăng xuất). Nhờ vậy `core` không phải import feature auth.
  final List<Widget> notesActions;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          NotesPage(
            dependencies: widget.notesDependencies,
            actions: widget.notesActions,
          ),
          const ComingSoonPage(
            title: 'Nhật ký',
            icon: Icons.menu_book_outlined,
            message: 'Nhật ký hằng ngày sẽ xuất hiện ở đây khi tính năng hoàn thành.',
          ),
          const ComingSoonPage(
            title: 'Thống kê',
            icon: Icons.insights_outlined,
            message:
                'Thống kê tuần và chuỗi ngày học sẽ xuất hiện ở đây khi tính '
                'năng hoàn thành.',
          ),
          const ComingSoonPage(
            title: 'Cài đặt',
            icon: Icons.settings_outlined,
            message:
                'Cài đặt tài khoản, giao diện và đồng bộ sẽ có tại đây khi '
                'tính năng hoàn thành.',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: _index == 0
            ? AppTheme.notes(Theme.of(context)).navigationBarTheme
            : Theme.of(context).navigationBarTheme,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: _index == 0
                  ? BorderSide.none
                  : BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (int index) =>
                setState(() => _index = index),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.sticky_note_2_outlined),
                selectedIcon: Icon(Icons.sticky_note_2),
                label: 'Ghi chú',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Nhật ký',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Thống kê',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
