import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final user = settingsProv.user;
    final reminders = settingsProv.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt & Quyền Riêng Tư')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Profile Card
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.accentIndigo,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${user.studentId} • Lớp ${user.className}'),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Reminders settings
          const Text(
            'Cài Đặt Lịch Nhắc Nhở',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...reminders.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(r.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  'Thời gian: ${TimeUtils.formatTime(r.hour, r.minute)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                value: r.isEnabled,
                activeThumbColor: AppTheme.accentCyan,
                onChanged: (val) => settingsProv.toggleReminder(r, val),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Digital Wellbeing & Family Link Guide
          const Text(
            'Quản Lý Thời Gian Sử Dụng Màn Hình',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(
                        Icons.screen_lock_portrait,
                        color: AppTheme.accentCyan,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Digital Wellbeing & Không làm phiền',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Để có giấc ngủ ngon, bạn nên bật chế độ "Giờ đi ngủ" (Bedtime Mode) trong Cài đặt hệ điều hành Android. '
                    'Đối với trẻ nhỏ, phụ huynh có thể tự cấu hình ứng dụng Google Family Link để đặt giới hạn thời gian sử dụng thiết bị.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Privacy & Project info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Chính sách quyền riêng tư'),
                  subtitle: const Text(
                    'Dữ liệu nhật ký được lưu cục bộ trên máy.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Quyền Riêng Tư DCSleep'),
                        content: const Text(
                          'Ứng dụng DCSleep tôn trọng quyền riêng tư của bạn. Mọi dữ liệu về giờ ngủ, cảm nhận và ghi chú '
                          'được lưu trữ an toàn trong cơ sở dữ liệu SQLite trên thiết bị. Trợ lý AI chỉ tiếp nhận thông tin khi bạn '
                          'chủ động đặt câu hỏi.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đã hiểu'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Phiên bản ứng dụng'),
                  subtitle: Text(
                    '${AppConstants.appName} v${AppConstants.appVersion} (Nhóm 7 - 65KTPM)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.softRed,
                side: const BorderSide(color: AppTheme.softRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận đăng xuất'),
                    content: const Text(
                      'Bạn có chắc muốn đăng xuất khỏi tài khoản hiện tại không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<SettingsProvider>().logout();
                        },
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: AppTheme.softRed),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
