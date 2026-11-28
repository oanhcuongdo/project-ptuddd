import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

/// Màn hình đăng ký tài khoản bằng email + mật khẩu.
///
/// Cùng ngôn ngữ thiết kế với màn đăng nhập (tham chiếu Duolingo): tiêu đề lớn,
/// nhãn trên ô nhập, một CTA chính, cùng khung [AuthScaffold]. Quy ước ở
/// `docs/ui_ux.md`.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final succeeded = await context.read<AuthCubit>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (succeeded && mounted) {
      // Đăng ký xong Firebase đã mở phiên; quay về để AuthGate đưa vào app.
      Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      showBackButton: true,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const AppLogo(size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Text('SmartNote', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Tạo tài khoản', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Bắt đầu ghi chú cùng SmartNote',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'ban@truong.edu.vn',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: FormValidators.email,
                  onChanged: (_) => context.read<AuthCubit>().clearError(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPasswordField(
                  label: 'Mật khẩu',
                  controller: _passwordController,
                  hintText:
                      'Tối thiểu '
                      '${FormValidators.minPasswordLength} ký tự',
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  validator: FormValidators.password,
                  onChanged: (_) => context.read<AuthCubit>().clearError(),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Nhập lại mật khẩu',
                  controller: _confirmController,
                  hintText: 'Nhập lại mật khẩu ở trên',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (String? value) => FormValidators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) => context.read<AuthCubit>().clearError(),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Tạo tài khoản',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
