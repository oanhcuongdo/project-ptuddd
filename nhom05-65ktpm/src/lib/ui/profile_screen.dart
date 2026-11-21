import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/app_database.dart';

/// Lets several learners share one device, each with their own history.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<User>> _users = context.read<AppState>().db.users();

  Future<void> _create() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Người học mới'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Tạo')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final state = context.read<AppState>();
    try {
      await state.selectUser(await state.db.createUser(name.trim()));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tên này đã tồn tại')));
      }
    }
  }

  Future<void> _delete(User u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Xóa "${u.name}"?'),
        content: const Text('Toàn bộ lịch sử luyện tập của người này sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final db = context.read<AppState>().db;
    await db.deleteUser(u.id);
    setState(() => _users = db.users());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn người học')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
      body: FutureBuilder(
        future: _users,
        builder: (context, snap) {
          final users = snap.data;
          if (users == null) return const Center(child: CircularProgressIndicator());
          if (users.isEmpty) {
            return const Center(child: Text('Chưa có người học. Nhấn "Thêm" để bắt đầu.'));
          }
          return ListView(
            children: [
              for (final u in users)
                ListTile(
                  leading: CircleAvatar(child: Text(u.name[0].toUpperCase())),
                  title: Text(u.name),
                  subtitle: Text('Mục tiêu ${u.dailyGoalMinutes} phút/ngày'),
                  onTap: () => context.read<AppState>().selectUser(u),
                  trailing: IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(u),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
