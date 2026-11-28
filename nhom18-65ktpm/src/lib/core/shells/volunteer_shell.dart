import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';

class VolunteerShell extends StatelessWidget {
  const VolunteerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tình nguyện viên'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Tùng thay bằng hồ sơ & nhận ca SOS (UC-11, UC-13)'),
      ),
    );
  }
}
