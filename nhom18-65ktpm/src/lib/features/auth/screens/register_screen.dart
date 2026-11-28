import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/auth_backdrop.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RoleOption {
  const _RoleOption({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String key;
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _roleOptions = [
    _RoleOption(
      key: 'rider',
      label: 'Khách hàng',
      shortLabel: 'Khách hàng',
      description: 'Tìm tiệm sửa xe, cây xăng & phát tín hiệu SOS khi gặp sự cố.',
      icon: Icons.two_wheeler_rounded,
      color: AppColors.primary,
    ),
    _RoleOption(
      key: 'owner',
      label: 'Chủ tiệm sửa xe',
      shortLabel: 'Chủ tiệm',
      description: 'Đăng ký cơ sở, quản lý trạng thái mở cửa & tiếp nhận SOS.',
      icon: Icons.build_circle_rounded,
      color: AppColors.motoOrange,
    ),
    _RoleOption(
      key: 'volunteer',
      label: 'Tình nguyện viên',
      shortLabel: 'Tình nguyện',
      description: 'Bật sẵn sàng cứu hộ cộng đồng xung quanh khu vực của bạn.',
      icon: Icons.volunteer_activism_rounded,
      color: AppColors.success,
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repo = AuthRepository();

  String _role = 'rider';
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  _RoleOption get _selectedRoleOption =>
      _roleOptions.firstWhere((item) => item.key == _role);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loggedIn = await _repo.signUp(
        fullName: _fullName.text,
        phone: _phone.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );

      if (!mounted) return;

      if (loggedIn) {
        // AuthGate tự chuyển sang màn hình hoặc bước thiết lập theo vai trò.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký thành công. Kiểm tra email để xác nhận tài khoản.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildRoleSelector() {
    final current = _selectedRoleOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn vai trò tham gia',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _roleOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _RoleChoiceTile(
                  option: _roleOptions[i],
                  selected: _role == _roleOptions[i].key,
                  enabled: !_loading,
                  onTap: () => setState(() => _role = _roleOptions[i].key),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Row(
            key: ValueKey(current.key),
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: current.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  current.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkSecondary,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordMeter() {
    final pwd = _password.text;
    if (pwd.isEmpty) return const SizedBox.shrink();

    final hasMin = pwd.length >= 6;
    final hasDigit = RegExp(r'\d').hasMatch(pwd);
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(pwd);
    final score = (hasMin ? 1 : 0) +
        (pwd.length >= 8 && hasDigit && hasLetter ? 1 : 0) +
        (pwd.length >= 10 ? 1 : 0);

    final (label, color, fill) = switch (score) {
      0 => ('Quá ngắn (cần tối thiểu 6 ký tự)', AppColors.sosRed, 0.28),
      1 => ('Đạt yêu cầu', AppColors.warning, 0.62),
      _ => ('Mật khẩu tốt', AppColors.success, 1.0),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 5,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Đăng ký tài khoản',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: AuthBackdrop(
        heroFraction: 0.30,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.13),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRoleSelector(),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fullName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => validateRequired(v, 'họ và tên'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            hintText: 'VD: 0912345678',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: validatePhone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'ban@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: validateEmail,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        _buildPasswordMeter(),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          FeedbackBanner(
                            message: _error!,
                            tone: FeedbackTone.error,
                          ),
                        ],
                        const SizedBox(height: 14),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Đăng ký'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tài khoản Admin do quản trị viên cấp, không tự đăng ký.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceTile extends StatelessWidget {
  const _RoleChoiceTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _RoleOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? option.color.withValues(alpha: 0.10)
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? option.color : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 20,
                color: selected ? option.color : AppColors.inkSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                option.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? option.color : AppColors.inkPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
