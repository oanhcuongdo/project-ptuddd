import 'package:flutter/material.dart';

import '../../features/admin/screens/admin_workspace_screen.dart';

/// Phân hệ Quản trị viên: UC-14 (kiểm duyệt & tài khoản) và UC-15 (thống kê).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminWorkspaceScreen();
  }
}
