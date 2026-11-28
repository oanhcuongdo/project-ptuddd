import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';

/// Màn hình đăng ký tài khoản sinh viên/người dùng mới.
///
/// Tuân thủ hệ thống màu Burgundy chuyên nghiệp:
/// - Primary: #9F1239 (Burgundy)
/// - Primary Light: #FFF5F5
/// - Secondary: #E8B4BC
/// - Danger/error: #DC2626
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Chuyển đổi mã lỗi kỹ thuật từ Supabase thành thông điệp thân thiện với người dùng
  String _getReadableErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('user already registered') ||
          msg.contains('already exists') ||
          msg.contains('unique constraint')) {
        return 'Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.';
      } else if (msg.contains('password') && msg.contains('least')) {
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      } else if (msg.contains('too many requests') ||
          msg.contains('rate limit')) {
        return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.';
      }
      return 'Đăng ký không thành công: ${error.message}';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    }

    return 'Đã có lỗi xảy ra trong quá trình đăng ký. Vui lòng thử lại sau.';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    // Kiểm tra dữ liệu hợp lệ
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Sử dụng Supabase signUp
      // Tận dụng trigger on_auth_user_created trong Database để tự tạo bản ghi profiles
      // với role mặc định là 'student' (trigger tự đọc raw_user_meta_data->>'full_name').
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (!mounted) return;

      // Kiểm tra trường hợp Supabase yêu cầu xác thực qua email
      final session = response.session;
      if (session == null) {
        // Trường hợp cần xác nhận email trước khi đăng nhập
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Row(
              children: [
                Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.primaryAction,
                ),
                SizedBox(width: 10),
                Text(
                  'Xác thực tài khoản',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Tài khoản đã được tạo thành công!\n\n'
              'Vui lòng kiểm tra hộp thư email "$email" (kể cả mục Thư rác/Spam) '
              'và bấm vào liên kết xác thực để hoàn tất kích hoạt tài khoản trước khi đăng nhập.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Đóng hộp thoại
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Quay về màn hình đăng nhập
                  }
                },
                child: const Text('Về trang đăng nhập'),
              ),
            ],
          ),
        );
      } else {
        // response.session != null: Đã đăng nhập, để AuthGate điều hướng vào ứng dụng
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Đăng ký tài khoản thành công!'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        // Không pop thủ công nếu AuthGate đã tự điều hướng
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_getReadableErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_getReadableErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Quay lại đăng nhập',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Biểu tượng tạo tài khoản
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            size: 28,
                            color: AppColors.primaryAction,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Tiêu đề
                      const Text(
                        'Tạo Tài Khoản Mới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1. Trường Họ và tên
                      TextFormField(
                        controller: _fullNameController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          hintText: 'Nguyễn Văn A',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          if (trimmed.length < 2) {
                            return 'Họ và tên phải có ít nhất 2 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Trường Email
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'sinhvien@e.tlu.edu.vn',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Vui lòng nhập địa chỉ email';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(trimmed)) {
                            return 'Email không hợp lệ (ví dụ: sinhvien@e.tlu.edu.vn)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Trường Mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu *',
                          hintText: 'Ít nhất 6 ký tự',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.secondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            tooltip: _obscurePassword
                                ? 'Hiển thị mật khẩu'
                                : 'Ẩn mật khẩu',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Trường Xác nhận mật khẩu
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_isLoading,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu *',
                          hintText: 'Nhập lại mật khẩu ở trên',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.secondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            tooltip: _obscureConfirmPassword
                                ? 'Hiển thị mật khẩu'
                                : 'Ẩn mật khẩu',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không trùng khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),

                      // Nút Đăng ký
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Đăng ký tài khoản',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Liên kết điều hướng về trang Đăng nhập
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryAction,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
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
