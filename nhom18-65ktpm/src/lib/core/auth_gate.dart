import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/banned_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'shells/admin_shell.dart';
import 'shells/owner_shell.dart';
import 'shells/rider_shell.dart';
import 'shells/volunteer_shell.dart';
import 'supabase_client.dart';

/// Nghe phiên đăng nhập, tải hồ sơ và điều hướng theo vai trò.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository();
  StreamSubscription<AuthState>? _subscription;
  Future<UserModel?>? _profile;

  @override
  void initState() {
    super.initState();
    _profile = _repo.fetchProfile();
    _subscription = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() => _profile = _repo.fetchProfile());
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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

        switch (user.role) {
          case 'owner':
            return const OwnerShell();
          case 'volunteer':
            return const VolunteerShell();
          case 'admin':
            return const AdminShell();
          default:
            return const RiderShell();
        }
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => AuthRepository().signOut(),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
