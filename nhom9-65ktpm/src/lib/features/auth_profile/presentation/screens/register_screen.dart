import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../components/avatar_picker.dart';
import '../components/daily_goal_selector.dart';
import '../components/language_preference_selector.dart';
import '../components/password_strength_bar.dart';
import '../components/register_step_header.dart';
import '../components/terms_checkbox.dart';
import '../providers/auth_provider.dart';

/// Màn hình Đăng ký 2 bước chuẩn bản mẫu:
/// - Bước 1 / 2: Thông tin tài khoản + Thanh đo độ mạnh mật khẩu + Điều khoản
/// - Bước 2 / 2: Thiết lập hồ sơ & Kỷ luật (Avatar, Ngôn ngữ, Trình độ, Mục tiêu 15/20/30p)
/// Responsive: 1 cột trên Android, 2 cột kiểu Facebook trên Chrome Web.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1;
  bool _acceptedTerms = true;
  String? _step1Error;

  // Dữ liệu Bước 2
  String _selectedAvatarId = 'owl';
  String _nativeLang = 'vi';
  String _targetLang = 'en';
  String _proficiencyLevel = 'A2';
  int _dailyGoalMinutes = 20;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _step1Error = 'Vui lòng đồng ý với Điều khoản sử dụng để tiếp tục.';
      });
      return;
    }
    setState(() {
      _step1Error = null;
      _currentStep = 2;
    });
  }

  void _onNativeLangChanged(String value) {
    setState(() {
      _nativeLang = value;
      if (_targetLang == value) {
        _targetLang = value == 'vi' ? 'en' : 'vi';
      }
    });
  }

  void _onTargetLangChanged(String value) {
    setState(() {
      _targetLang = value;
      if (_nativeLang == value) {
        _nativeLang = value == 'vi' ? 'en' : 'vi';
      }
    });
  }

  Future<void> _handleCompleteRegister() async {
    final ok = await context.read<AuthProvider>().registerWithEmail(
          displayName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          avatarUrl: 'preset:$_selectedAvatarId',
          nativeLang: _nativeLang,
          targetLang: _targetLang,
          proficiencyLevel: _proficiencyLevel,
          dailyGoalMinutes: _dailyGoalMinutes,
        );
    if (mounted && ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.initialRoute,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      subtitle: 'Giữ vững kỷ luật – Vượt rào cản ngôn ngữ',
      showMobileBrandHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegisterStepHeader(
            currentStep: _currentStep,
            onBack: _goBack,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_currentStep == 1)
            _buildStep1(auth)
          else
            _buildStep2(auth),
        ],
      ),
    );
  }

  Widget _buildStep1(AuthProvider auth) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tạo tài khoản BuddyTalk',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '🔥 Bắt đầu chuỗi Streak giao tiếp mỗi ngày',
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _nameController,
            label: 'Họ và tên',
            hintText: 'Phạm Văn Hưng',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'phamvanhung@65ktpm.edu.vn',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hintText: 'Tối thiểu 6 ký tự',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6)
                ? 'Mật khẩu tối thiểu 6 ký tự'
                : null,
          ),
          const SizedBox(height: 10),
          PasswordStrengthBar(password: _passwordController.text),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirmPasswordController,
            label: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: Icons.verified_user_outlined,
            obscureText: true,
            validator: (v) => (v != _passwordController.text)
                ? 'Mật khẩu xác nhận không khớp'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TermsCheckbox(
            value: _acceptedTerms,
            onChanged: (v) => setState(() {
              _acceptedTerms = v;
              if (v) _step1Error = null;
            }),
          ),
          AppErrorText(message: _step1Error ?? auth.errorMessage),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Đăng ký & Thiết lập hồ sơ',
            trailingIcon: Icons.arrow_forward_rounded,
            isLoading: auth.isLoading,
            onPressed: _goToStep2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Thiết lập hồ sơ & Kỷ luật',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Giúp BuddyTalk ghép cặp bạn đồng hành bù trừ ngôn ngữ chuẩn nhất.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        AvatarPicker(
          selectedId: _selectedAvatarId,
          onSelected: (id) => setState(() => _selectedAvatarId = id),
        ),
        const SizedBox(height: 18),
        LanguagePreferenceSelector(
          nativeLang: _nativeLang,
          targetLang: _targetLang,
          proficiencyLevel: _proficiencyLevel,
          onNativeLangChanged: _onNativeLangChanged,
          onTargetLangChanged: _onTargetLangChanged,
          onLevelChanged: (lvl) => setState(() => _proficiencyLevel = lvl),
        ),
        const SizedBox(height: 18),
        DailyGoalSelector(
          selectedMinutes: _dailyGoalMinutes,
          onChanged: (mins) => setState(() => _dailyGoalMinutes = mins),
        ),
        AppErrorText(message: auth.errorMessage),
        const SizedBox(height: 22),
        AppButton(
          label: 'Hoàn tất & Bắt đầu hành trình 🎉',
          isLoading: auth.isLoading,
          onPressed: _handleCompleteRegister,
        ),
      ],
    );
  }
}
