import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../state/document_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _exportJsonBackup(BuildContext context) async {
    final jsonStr = await context.read<DocumentProvider>().exportBackup();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bản sao lưu JSON (Cashew Snapshot)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dữ liệu đã được đóng gói theo định dạng Snapshot của Cashew, bao gồm Subjects, Documents và DeleteLogs Tombstones:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black12,
                child: SelectableText(
                  jsonStr.length > 800 ? '${jsonStr.substring(0, 800)}\n... (đã cắt bớt)' : jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép chuỗi JSON vào Clipboard!')),
              );
            },
            child: const Text('Sao chép tất cả'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _importJsonBackup(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục từ JSON Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dán nội dung JSON sao lưu vào ô dưới đây. Hệ thống sẽ áp dụng quy tắc giải quyết xung đột Last-Write-Wins và kiểm tra Tombstone:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Dán chuỗi JSON vào đây...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              try {
                final count = await context.read<DocumentProvider>().importBackup(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã khôi phục thành công $count tài liệu!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi nhập dữ liệu: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  void _viewDeleteLogs(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final logs = await db.deleteLogDao.getAllDeleteLogs();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_toggle_off, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  const Text(
                    'Nhật ký Xóa - DeleteLogs (Tombstones)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text(
                'Đây là bảng Tombstone cốt lõi trong Kiến trúc Cashew giúp ghi nhận vết các mục đã xóa, phục vụ đồng bộ vi sai và tránh xung đột Last-Write-Wins.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 20),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('Chưa có vết xóa Tombstone nào.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final log = logs[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.delete_forever, color: Colors.red),
                              title: Text('Mã đối tượng: ${log.entryPk}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('Loại: ${log.itemType} • Thời điểm xóa: ${dateFormat.format(log.dateTimeModified)}', style: const TextStyle(fontSize: 11)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Sao lưu'),
      ),
      body: ListView(
        children: [
          // Phần 1: TÀI KHOẢN GOOGLE & FIREBASE CLOUD
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'TÀI KHOẢN GOOGLE & CLOUD (FIREBASE)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ),
          if (!auth.isSignedIn) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_queue, size: 48, color: Colors.deepOrange),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập Google với Firebase',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đăng nhập để đồng bộ tài liệu lên Cloud Firestore và sao lưu tệp lên Firebase Cloud Storage.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    auth.isLoading
                        ? const CircularProgressIndicator()
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.deepOrange),
                            label: const Text('Đăng nhập bằng Google'),
                            onPressed: () => auth.signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: auth.currentUser?.photoURL != null
                      ? NetworkImage(auth.currentUser!.photoURL!)
                      : null,
                  child: auth.currentUser?.photoURL == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  auth.currentUser?.displayName ?? 'Sinh viên',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(auth.currentUser?.email ?? 'Đã xác thực qua Google'),
                trailing: TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: Colors.deepOrange),
              title: const Text('Đồng bộ lên Cloud Firestore'),
              subtitle: Text(
                auth.isSyncing
                    ? 'Đang đồng bộ dữ liệu...'
                    : 'Lưu trữ tài liệu và môn học lên Cloud Firestore của nhóm',
              ),
              trailing: auth.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: auth.isSyncing
                  ? null
                  : () async {
                      final success = await auth.syncToFirebase(
                        documents: docProvider.allDocuments,
                        subjects: docProvider.subjects,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Đồng bộ lên Cloud Firestore thành công!'
                                  : (auth.errorMessage ?? 'Đồng bộ thất bại'),
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
            ),
          ],
          const Divider(),

          // Phần 2: Giao diện
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('GIAO DIỆN & TRẢI NGHIỆM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Chế độ tối (Dark Mode)'),
            subtitle: const Text('Tùy chỉnh giao diện theo sở thích'),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleTheme(val),
          ),
          const Divider(),

          // Phần 3: Sao lưu & Phục hồi Cục bộ
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('SAO LƯU & ĐỒNG BỘ THEO KIẾN TRÚC CASHEW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
            title: const Text('Xuất Snapshot sao lưu JSON'),
            subtitle: const Text('Đóng gói toàn bộ tài liệu, môn học và vết xóa Tombstone'),
            onTap: () => _exportJsonBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined, color: Colors.green),
            title: const Text('Khôi phục từ Snapshot JSON'),
            subtitle: const Text('Gộp dữ liệu vi sai với thuật toán Last-Write-Wins'),
            onTap: () => _importJsonBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.manage_history, color: Colors.deepOrange),
            title: const Text('Kiểm tra bảng Tombstones (DeleteLogs)'),
            subtitle: const Text('Xem danh sách dấu vết các đối tượng đã bị xóa trong SQLite'),
            onTap: () => _viewDeleteLogs(context),
          ),
          const Divider(),

          // Phần 4: Thông tin nhóm thực hiện
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('THÔNG TIN ĐỒ ÁN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const ListTile(
            leading: Icon(Icons.school, color: Colors.indigo),
            title: Text('Bài Thực Hành TH1: Kiến trúc Cashew'),
            subtitle: Text('Đề tài: Ứng dụng Quản lý Tài liệu Học tập\nNhóm 11 - Tích hợp Firebase Google Auth & Cloud Storage'),
          ),
        ],
      ),
    );
  }
}
