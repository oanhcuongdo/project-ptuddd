import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';

class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chủ tiệm'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Hiếu thay bằng quản lý tiệm (UC-09 → UC-11)'),
      ),
    );
  }
}
