import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/auth_brand_hero.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';

/// Màn hình đăng nhập email + mật khẩu.
///
/// Bố cục tham chiếu `15_brand_visual.png` (khối hero thương hiệu) và
/// `14_ui_style_guide.png` (tiêu đề lớn, nhãn trên ô, một CTA duy nhất).
/// Quy ước chi tiết ở `docs/ui_ux.md`. Không có logic nghiệp vụ — mọi thứ đi
/// qua [AuthCubit].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AuthBrandHero(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Ghi chú thông minh\ncho việc học.',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Đăng nhập để đồng bộ ghi chú của bạn',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  label: 'Mật khẩu',
                  controller: _passwordController,
                  hintText: 'Tối thiểu 6 ký tự',
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  validator: FormValidators.password,
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) => context.read<AuthCubit>().clearError(),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Đăng nhập',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: state.isSubmitting ? null : _openRegister,
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
