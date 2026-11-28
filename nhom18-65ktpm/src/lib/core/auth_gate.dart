import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/banned_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/owner/data/owner_shop_repository.dart';
import '../features/owner/screens/shop_editor_screen.dart';
import '../features/volunteer/data/supabase_volunteer_repository.dart';
import '../features/volunteer/screens/volunteer_profile_screen.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'push_service.dart';
import 'shells/admin_shell.dart';
import 'shells/owner_shell.dart';
import 'shells/rider_shell.dart';
import 'shells/volunteer_shell.dart';
import 'supabase_client.dart';
import 'theme.dart';
import 'widgets/animated_moto_logo.dart';
import 'widgets/auth_backdrop.dart';
import 'widgets/hci_components.dart';

/// Nghe phiên đăng nhập, tải hồ sơ, đăng ký FCM và điều hướng theo vai trò (UC-01).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository();
  StreamSubscription<AuthState>? _subscription;
  Future<UserModel?>? _profile;
  String? _registeredPushUserId;

  @override
  void initState() {
    super.initState();
    _profile = _repo.fetchProfile();
    _subscription = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) {
        setState(() {
          if (supabase.auth.currentSession == null) {
            _registeredPushUserId = null;
          }
          _profile = _repo.fetchProfile();
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _ensurePushRegistered(UserModel user) {
    if (user.role != 'owner' && user.role != 'volunteer') return;
    if (_registeredPushUserId == user.id) return;
    _registeredPushUserId = user.id;
    unawaited(PushService.register());
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentSession == null) {
      return const LoginScreen();
    }

    return FutureBuilder<UserModel?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (snapshot.hasError) {
          return _LoadError(message: snapshot.error.toString());
        }

        final user = snapshot.data;
        if (user == null) {
          return const _LoadError(
            message: 'Không tìm thấy hồ sơ người dùng. Liên hệ quản trị viên.',
          );
        }
        if (user.isBanned) return const BannedScreen();

        _ensurePushRegistered(user);

        switch (user.role) {
          case 'owner':
            return _OnboardingGate(
              checkComplete: () async =>
                  (await OwnerShopRepository().myShops()).isNotEmpty,
              buildOnboarding: (onDone) =>
                  ShopEditorScreen(showLogout: true, onSaved: onDone),
              child: const OwnerShell(),
            );
          case 'volunteer':
            return _OnboardingGate(
              checkComplete: () async =>
                  (await SupabaseVolunteerRepository().myProfile()) != null,
              buildOnboarding: (onDone) =>
                  VolunteerProfileScreen(showLogout: true, onSaved: onDone),
              child: const VolunteerShell(),
            );
          case 'admin':
            return const AdminShell();
          default:
            return const RiderShell();
        }
      },
    );
  }
}

/// Luồng thay thế UC-01: chuyển thẳng Owner chưa có tiệm tới UC-09,
/// và Volunteer chưa có hồ sơ tới UC-13; hoàn tất thì vào shell chính.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({
    required this.checkComplete,
    required this.buildOnboarding,
    required this.child,
  });

  final Future<bool> Function() checkComplete;
  final Widget Function(VoidCallback onDone) buildOnboarding;
  final Widget child;

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<bool> _hasSetup = widget.checkComplete();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSetup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        // Nếu lỗi mạng khi kiểm tra, vẫn mở shell để màn hình tự hiển thị nút Thử lại.
        if (snapshot.hasError || snapshot.data == true) {
          return widget.child;
        }
        return widget.buildOnboarding(() {
          if (mounted) {
            setState(() {
              _hasSetup = Future.value(true);
            });
          }
        });
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        heroFraction: 0.56,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedMotoLogo(
                badgeSize: 84,
                trackWidth: 240,
                interactive: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'Kết nối & Tình nguyện xe máy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyDeep.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Đang tải hồ sơ của bạn...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        heroFraction: 0.34,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: EmptyStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Không tải được hồ sơ',
                message: message,
                accentColor: AppColors.sosRed,
                action: FilledButton.icon(
                  onPressed: () => AuthRepository().signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
