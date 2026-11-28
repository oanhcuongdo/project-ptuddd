import 'package:flutter/material.dart';

import '../../features/sos/screens/sos_request_screen.dart';
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
      // UC-07: giữ nút này khi thay body bằng bản đồ.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SosRequestScreen())),
        icon: const Icon(Icons.sos),
        label: const Text('SOS'),
      ),
    );
  }
}
