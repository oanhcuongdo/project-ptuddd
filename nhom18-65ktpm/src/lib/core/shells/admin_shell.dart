import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị viên'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Hiếu thay bằng dashboard (UC-14, UC-15)'),
      ),
    );
  }
}
