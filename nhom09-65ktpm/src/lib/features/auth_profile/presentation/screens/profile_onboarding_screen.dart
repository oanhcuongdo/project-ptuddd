import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/auth_layout.dart';
import '../../../../core/components/app_button.dart';
import '../../../../core/components/app_error_text.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/language_model.dart';
import '../components/avatar_picker.dart';
import '../components/daily_goal_selector.dart';
import '../components/language_preference_selector.dart';
import '../components/onboarding_step_header.dart';
import '../providers/auth_provider.dart';

/// Màn hình Thiết lập hồ sơ kiểu Duolingo (hiển thị sau khi đăng nhập Email hoặc Google
/// nếu người dùng chưa hoàn tất thiết lập hồ sơ `onboarding_completed == false`):
/// - Bước 1 / 2 (Có thể Bỏ qua): Chọn ảnh đại diện & Nhập Họ và tên.
///   Nếu bấm "Bỏ qua" -> tự gán tên `user_<shortId>` + ảnh đại diện mặc định rồi qua Bước 2.
/// - Bước 2 / 2 (Bắt buộc): Chọn Ngôn ngữ muốn luyện (tải từ bảng `languages`),
///   Trình độ & Mục tiêu hàng ngày kiểu Duolingo — KHÔNG fix cứng giá trị mặc định.
class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  int _currentStep = 1;
  String _selectedAvatarId = AvatarPicker.presets.first.id;
  String? _googlePhotoUrl;

  List<LanguageModel> _languages = const [];
  bool _isLoadingLanguages = true;
  String? _languageError;
  String? _step2ValidationError;

  // Không fix cứng — bắt đầu bằng null để người dùng tự chọn
  String? _targetLang;
  String? _proficiencyLevel;
  int? _dailyGoalMinutes;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentProfile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');

    final existingAvatar = profile?.avatarUrl;
    if (existingAvatar != null && existingAvatar.startsWith('http')) {
      _googlePhotoUrl = existingAvatar;
      _selectedAvatarId = AvatarPicker.googleAvatarId;
    } else if (existingAvatar != null && existingAvatar.startsWith('preset:')) {
      _selectedAvatarId = existingAvatar.replaceFirst('preset:', '');
    }

    _loadAllowedLanguages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _defaultDisplayName(String userId) {
    final compact = userId.replaceAll('-', '');
    final shortId = compact.length > 8 ? compact.substring(0, 8) : compact;
    return 'user_$shortId';
  }

  Future<void> _loadAllowedLanguages() async {
    setState(() {
      _isLoadingLanguages = true;
      _languageError = null;
    });

    try {
      final list = await context.read<AuthProvider>().fetchAllowedLanguages();
      if (!mounted) return;
      setState(() {
        _languages = list;
        _isLoadingLanguages = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLanguages = false;
        _languageError =
            'Không thể tải danh sách ngôn ngữ từ Supabase. Hãy chạy migration 008_languages_and_onboarding.sql trước.';
      });
    }
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    setState(() => _currentStep = 2);
  }

  /// Bỏ qua Bước 1 (Họ tên & Avatar): tự điền `user_<shortId>` nếu chưa nhập tên
  /// và dùng ảnh đại diện mặc định, sau đó chuyển sang Bước 2 (chọn ngôn ngữ & mục tiêu).
  void _skipStep1() {
    final userId = context.read<AuthProvider>().currentProfile?.userId ?? '';
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = _defaultDisplayName(userId);
    }
    if (_selectedAvatarId.isEmpty) {
      _selectedAvatarId = _googlePhotoUrl != null
          ? AvatarPicker.googleAvatarId
          : AvatarPicker.presets.first.id;
    }
    setState(() => _currentStep = 2);
  }

  String? _resolveAvatarUrl() {
    if (_selectedAvatarId == AvatarPicker.googleAvatarId) {
      return _googlePhotoUrl;
    }
    return 'preset:$_selectedAvatarId';
  }

  Future<void> _handleComplete() async {
    if (!_step2FormKey.currentState!.validate()) return;
    if (_languages.isEmpty) return;

    if (_targetLang == null) {
      setState(
        () => _step2ValidationError = 'Vui lòng chọn ngôn ngữ bạn muốn luyện tập.',
      );
      return;
    }
    if (_proficiencyLevel == null) {
      setState(
        () => _step2ValidationError = 'Vui lòng chọn trình độ hiện tại của bạn.',
      );
      return;
    }
    if (_dailyGoalMinutes == null) {
      setState(
        () => _step2ValidationError =
            'Vui lòng chọn hoặc nhập mục tiêu số phút mỗi ngày.',
      );
      return;
    }

    setState(() => _step2ValidationError = null);

    final auth = context.read<AuthProvider>();
    final userId = auth.currentProfile?.userId ?? '';
    final finalName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _defaultDisplayName(userId);

    await auth.completeOnboarding(
      displayName: finalName,
      avatarUrl: _resolveAvatarUrl(),
      targetLang: _targetLang!,
      proficiencyLevel: _proficiencyLevel!,
      dailyGoalMinutes: _dailyGoalMinutes!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      subtitle: 'Cá nhân hóa lộ trình giao tiếp & chuỗi kỷ luật của riêng bạn',
      showMobileBrandHeader: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            currentStep: _currentStep,
            totalSteps: 2,
            onBack: _currentStep == 2
                ? () => setState(() => _currentStep = 1)
                : null,
            // Chỉ Bước 1 (Avatar + Họ tên) mới được bỏ qua để sang Bước 2
            onSkip: _currentStep == 1 && !auth.isLoading ? _skipStep1 : null,
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
            'Thiết lập hồ sơ cá nhân',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn ảnh đại diện và tên hiển thị. Bạn có thể bấm "Bỏ qua" để dùng mặc định và chuyển sang bước chọn ngôn ngữ.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          AvatarPicker(
            selectedId: _selectedAvatarId,
            googlePhotoUrl: _googlePhotoUrl,
            onSelected: (id) => setState(() => _selectedAvatarId = id),
          ),
          const SizedBox(height: 22),
          AppTextField(
            controller: _nameController,
            label: 'Họ và tên hiển thị',
            hintText: 'Ví dụ: Phạm Văn Hưng',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập họ và tên hoặc bấm "Bỏ qua" ở góc trên'
                : null,
          ),
          AppErrorText(message: auth.errorMessage),
          const SizedBox(height: 24),
          AppButton(
            label: 'Tiếp tục chọn ngôn ngữ',
            trailingIcon: Icons.arrow_forward_rounded,
            isLoading: auth.isLoading,
            onPressed: _goToStep2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ngôn ngữ & Mục tiêu hàng ngày',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn ngôn ngữ muốn luyện tập, trình độ và thời lượng luyện nói mỗi ngày.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          LanguagePreferenceSelector(
            languages: _languages,
            isLoadingLanguages: _isLoadingLanguages,
            loadError: _languageError,
            onRetryLoad: _loadAllowedLanguages,
            targetLang: _targetLang,
            proficiencyLevel: _proficiencyLevel,
            onTargetLangChanged: (code) => setState(() {
              _targetLang = code;
              _step2ValidationError = null;
            }),
            onLevelChanged: (lvl) => setState(() {
              _proficiencyLevel = lvl;
              _step2ValidationError = null;
            }),
          ),
          const SizedBox(height: 22),
          DailyGoalSelector(
            selectedMinutes: _dailyGoalMinutes,
            onChanged: (mins) => setState(() {
              _dailyGoalMinutes = mins;
              _step2ValidationError = null;
            }),
          ),
          AppErrorText(message: _step2ValidationError ?? auth.errorMessage),
          const SizedBox(height: 24),
          AppButton(
            label: 'Hoàn tất & Bắt đầu hành trình 🎉',
            isLoading: auth.isLoading,
            onPressed: _languages.isEmpty ? null : _handleComplete,
          ),
        ],
      ),
    );
  }
}
