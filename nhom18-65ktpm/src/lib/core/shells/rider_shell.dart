import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';

class RiderShell extends StatelessWidget {
  const RiderShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Quân thay bằng bản đồ & tìm kiếm (UC-02 → UC-06)'),
      ),
    );
  }
}
