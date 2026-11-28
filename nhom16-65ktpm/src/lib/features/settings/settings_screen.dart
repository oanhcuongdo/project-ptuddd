import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// Màn hình Cài đặt của Thống kê (Giai đoạn 4 - C7).
/// Mở từ nút bánh răng trên AppBar của AnalyticsScreen.
/// Đổi mục tiêu quỹ + Đổi mật khẩu SQLite + Giới thiệu nhóm.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.currentGoal});

  /// Mục tiêu quỹ hiện tại (đ), dùng làm giá trị mặc định của ô nhập.
  final double currentGoal;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.currentGoal.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final digits = _goalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = double.tryParse(digits);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số tiền mục tiêu lớn hơn 0.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fund_goal', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu mục tiêu quỹ.')));
    Navigator.pop(context, true);
  }

  Future<void> _showChangePasswordDialog() async {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Đổi mật khẩu'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mật khẩu mới sẽ được lưu trực tiếp vào CSDL SQLite của ứng dụng.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Tối thiểu 6 ký tự',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  final newPass = newPassController.text.trim();
                  final confirmPass = confirmPassController.text.trim();

                  if (newPass.length < 6) {
                    setDialogState(() =>
                        errorText = 'Mật khẩu phải có tối thiểu 6 ký tự.');
                    return;
                  }
                  if (newPass != confirmPass) {
                    setDialogState(() =>
                        errorText = 'Mật khẩu xác nhận không trùng khớp.');
                    return;
                  }

                  final success =
                      await AuthService.instance.changePassword(newPass);
                  if (!mounted) return;

                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }

                  if (success) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Đổi mật khẩu thành công vào SQLite!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể đổi mật khẩu. Vui lòng thử lại!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Cập nhật'),
              ),
            ],
          );
        },
      ),
    );

    newPassController.dispose();
    confirmPassController.dispose();
  }

  Widget _memberTile(String initials, String name, String role) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text(initials),
      ),
      title: Text(name),
      subtitle: Text(role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentUser = AuthService.instance.currentUser;
    final isAdmin = AuthService.instance.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. MỤC TIÊU QUỸ
          const Text(
            'Mục tiêu quỹ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền mục tiêu (đ)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveGoal,
            icon: const Icon(Icons.save),
            label: const Text('Lưu mục tiêu'),
          ),

          // 2. TÀI KHOẢN & BẢO MẬT
          const SizedBox(height: 24),
          const Text(
            'Tài khoản & Bảo mật',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        foregroundColor: AppColors.primary,
                        child: const Icon(Icons.person_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? 'Người dùng',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              currentUser?.email ?? 'Chưa đăng nhập',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isAdmin ? AppColors.primary : Colors.grey)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAdmin ? 'Admin' : 'Thành viên',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAdmin
                                ? AppColors.primary
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset_rounded,
                        color: AppColors.primary),
                    title: const Text('Đổi mật khẩu tài khoản'),
                    subtitle: const Text(
                        'Cập nhật mật khẩu mới lưu vào CSDL SQLite'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),
          ),

          // 3. GIỚI THIỆU & ĐỘI NGŨ PHÁT TRIỂN
          const SizedBox(height: 24),
          const Text(
            'Giới thiệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 30,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GoodDeeds Fund',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Quản lý Thử thách Việc Tốt & Quỹ Từ Thiện'),
                        SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Đội ngũ phát triển — Nhóm 16 · Lớp 65KTPM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _memberTile('H', 'Nguyễn Văn Huỳnh', 'Trưởng nhóm'),
                _memberTile('TT', 'Trần Anh Tuấn', 'Thống kê & Kiểm duyệt'),
                _memberTile('K', 'Nguyễn Trung Kiên', 'Nộp minh chứng & OCR'),
                _memberTile('LT', 'Lê Anh Tuấn', 'Sổ Quỹ & Cơ sở dữ liệu'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
