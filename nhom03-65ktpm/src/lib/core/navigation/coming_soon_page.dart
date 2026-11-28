import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';

/// Màn giữ chỗ cho tab **chưa có tính năng** trong bottom navigation.
///
/// Dùng cùng `AppScaffold` + `EmptyState` như mọi màn khác để header, khoảng
/// cách và trạng thái rỗng không bị lệch chuẩn; không tự dựng layout riêng.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      subtitle: 'Sắp ra mắt',
      body: EmptyState(
        icon: icon,
        title: 'Tính năng đang được xây dựng',
        message: message,
      ),
    );
  }
}
