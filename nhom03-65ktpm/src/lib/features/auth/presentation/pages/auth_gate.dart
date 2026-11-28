import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/navigation/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../notes/presentation/bloc/notes_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/logout_button.dart';
import 'login_page.dart';

/// Cổng điều hướng dựa trên phiên đăng nhập:
///
/// - `unknown` → màn chờ (Firebase đang khôi phục phiên),
/// - `authenticated` → màn hình chính,
/// - `unauthenticated` → màn đăng nhập.
///
/// Nhờ vậy người dùng đã đăng nhập được vào thẳng app, còn người chưa đăng
/// nhập không mở được màn hình chính.
class AuthGate extends StatelessWidget {
  const AuthGate({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state.isUnknown) {
          return const _SplashPage();
        }
        if (state.isAuthenticated) {
          return BlocProvider<NotesCubit>(
            key: ValueKey(state.user?.id),
            create: (_) => NotesCubit(
              dependencies.noteRepository,
              monitor: dependencies.syncMonitor,
            )..load(),
            child: AppShell(
              notesDependencies: dependencies,
              notesActions: const <Widget>[LogoutButton()],
            ),
          );
        }
        return const LoginPage();
      },
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppLogo(size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text('SmartNote', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Học tốt hơn mỗi ngày',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppLoadingIndicator(size: 24, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
