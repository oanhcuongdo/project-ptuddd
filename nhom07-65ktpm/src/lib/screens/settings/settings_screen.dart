import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/nap_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sleep_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(BuildContext context, SettingsProvider settingsProv) {
    final user = settingsProv.user;
    final nameController = TextEditingController(text: user.name);
    final studentIdController = TextEditingController(text: user.studentId);
    final classController = TextEditingController(text: user.className);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh Sửa Hồ Sơ'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Nhập họ tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sinh viên',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Nhập MSV' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: classController,
                  decoration: const InputDecoration(
                    labelText: 'Lớp sinh hoạt',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Nhập lớp' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await settingsProv.updateProfile(
                name: nameController.text,
                studentId: studentIdController.text,
                className: classController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin hồ sơ!'),
                    backgroundColor: AppTheme.softGreen,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showTeamInfoDialog(BuildContext context) {
    final members = const [
      {
        'name': 'Mã Khánh Linh',
        'id': '2351170602',
        'role': 'Nhóm trưởng • Giao diện, Tài khoản & Hồ sơ',
      },
      {
        'name': 'Vũ Bá Đài',
        'id': '2351170577',
        'role': 'Thành viên • Lịch ngủ, Nhắc nhở & Power Nap',
      },
      {
        'name': 'Dương Quốc Vượng',
        'id': '2351170634',
        'role': 'Thành viên • Trợ lý AI Sleep Assistant',
      },
      {
        'name': 'Lê Văn Dân',
        'id': '2251161963',
        'role': 'Thành viên • Nhật ký, Thống kê & SQLite',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông Tin Nhóm 07 - 65KTPM'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đề tài: DCSleep – Ứng dụng hỗ trợ xây dựng kỷ luật và cải thiện thói quen ngủ bằng AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'GVHD: ThS. Đỗ Oanh Cường',
                style: TextStyle(fontSize: 12, color: AppTheme.accentCyan),
              ),
              const Divider(height: 20),
              ...members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_pin,
                        size: 18,
                        color: AppTheme.accentIndigo,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m['name']} (${m['id']})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              m['role']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmClearPersonalData(
    BuildContext context,
    SettingsProvider settingsProv,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa dữ liệu cá nhân'),
        content: const Text(
          'Toàn bộ nhật ký giấc ngủ, lịch sử Power Nap và hội thoại với Trợ lý AI sẽ bị xóa khỏi thiết bị. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await settingsProv.clearAllPersonalData();
              if (context.mounted) {
                await context.read<SleepProvider>().loadData();
                if (!context.mounted) return;
                await context.read<NapProvider>().loadHistory();
                if (!context.mounted) return;
                await context.read<AIAssistantProvider>().loadMessages();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa toàn bộ dữ liệu cá nhân.'),
                    backgroundColor: AppTheme.softAmber,
                  ),
                );
              }
            },
            child: const Text(
              'Xóa toàn bộ',
              style: TextStyle(color: AppTheme.softRed),
            ),
          ),
        ],
      ),
    );
  }

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
          // 1. Profile Card (with Edit Profile button)
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
              subtitle: Text(
                '${user.studentId} • Lớp ${user.className}\n${user.email}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.accentCyan),
                tooltip: 'Chỉnh sửa hồ sơ',
                onPressed: () => _showEditProfileDialog(context, settingsProv),
              ),
              onTap: () => _showEditProfileDialog(context, settingsProv),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Appearance & AI Privacy Switches
          const Text(
            'Giao Diện & Quyền Riêng Tư AI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    settingsProv.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppTheme.accentCyan,
                  ),
                  title: const Text(
                    'Giao diện Tối (Dark Mode)',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    settingsProv.isDarkMode
                        ? 'Đang dùng nền Midnight Deep Blue'
                        : 'Đang dùng giao diện Sáng',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: settingsProv.isDarkMode,
                  activeThumbColor: AppTheme.accentCyan,
                  onChanged: (val) => settingsProv.toggleTheme(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.history_toggle_off,
                    color: AppTheme.accentIndigo,
                  ),
                  title: const Text(
                    'Lưu lịch sử trò chuyện AI',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Lưu hội thoại vào SQLite trên thiết bị (Mục 7.11)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  value: settingsProv.saveAiHistory,
                  activeThumbColor: AppTheme.accentCyan,
                  onChanged: (val) => settingsProv.toggleSaveAiHistory(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Reminders settings
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

          // 4. Digital Wellbeing & Family Link Guide
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

          // 5. Privacy, Data Management & Team Info
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
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppTheme.softRed,
                  ),
                  title: const Text(
                    'Xóa dữ liệu cá nhân',
                    style: TextStyle(color: AppTheme.softRed),
                  ),
                  subtitle: const Text(
                    'Xóa nhật ký ngủ, Power Nap & lịch sử chat AI',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmClearPersonalData(context, settingsProv),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.groups_outlined,
                    color: AppTheme.accentCyan,
                  ),
                  title: const Text('Thông tin Nhóm 07'),
                  subtitle: const Text(
                    'Lớp 65KTPM • GVHD: ThS. Đỗ Oanh Cường',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTeamInfoDialog(context),
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

          // 6. Logout Button
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
                          Navigator.of(context).popUntil((route) => route.isFirst);
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
