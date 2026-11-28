import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/services/auth_service.dart';
import 'package:soroban_kids_app/injection_container.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final RegExp _gmailPattern =
      RegExp(r'^[A-Z0-9._%+-]+@gmail\.com$', caseSensitive: false);
  static final RegExp _passwordPattern =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d\s])\S{8,}$');

  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = sl<AuthService>();

  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _hidePassword = true;
  String? _submitError;

  @override
  void dispose() {
    _parentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateParentName(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Vui lòng nhập họ và tên.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!_gmailPattern.hasMatch(email)) {
      return 'Email phải có định dạng ten@gmail.com.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (_isRegistering && !_passwordPattern.hasMatch(password)) {
      return 'Mật khẩu cần ít nhất 8 ký tự, gồm chữ, số và ký tự đặc biệt.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (!_isRegistering) return null;
    if (value == null || value.isEmpty) return 'Vui lòng nhập lại mật khẩu.';
    if (value != _passwordController.text)
      return 'Mật khẩu nhập lại chưa khớp.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      if (_isRegistering) {
        await _authService.register(
          parentName: _parentNameController.text,
          email: email,
          password: _passwordController.text,
        );
      } else {
        await _authService.signIn(
          email: email,
          password: _passwordController.text,
        );
      }
      // AuthGate listens to FirebaseAuth and opens HomeScreen automatically.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _submitError = _friendlyAuthError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email này đã có tài khoản. Hãy đăng nhập.';
      case 'invalid-email':
        return 'Địa chỉ email chưa hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu chưa đủ mạnh. Hãy dùng ít nhất 8 ký tự.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu chưa chính xác.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần. Hãy đợi một lúc rồi thử lại.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Hãy kiểm tra Internet rồi thử lại.';
      case 'operation-not-allowed':
        return 'Firebase chưa bật đăng nhập Email/Mật khẩu. Hãy bật trong Firebase Console.';
      default:
        return error.message ??
            'Không thể xác thực tài khoản. Vui lòng thử lại.';
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _submitError = null;
      _parentNameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          color: AppColors.primary,
                          size: 58,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRegistering
                              ? 'Tạo tài khoản phụ huynh'
                              : 'Đăng nhập',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegistering
                              ? 'Lưu hồ sơ và tiến độ học của bé trên đám mây.'
                              : 'Đăng nhập để tiếp tục hành trình học toán.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                        const SizedBox(height: 24),
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _parentNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateParentName,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email Gmail',
                            hintText: 'ten@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: _isRegistering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: _isRegistering
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) {
                            if (!_isRegistering) _submit();
                          },
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Nhập lại mật khẩu',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateConfirmation,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mật khẩu: ít nhất 8 ký tự, có chữ cái, chữ số '
                            'và ký tự đặc biệt (không chứa khoảng trắng).',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_submitError != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _submitError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isRegistering ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSubmitting ? null : _toggleMode,
                          child: Text(
                            _isRegistering
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
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
