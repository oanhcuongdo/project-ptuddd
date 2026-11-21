import 'package:flutter/material.dart';

import '../domain/auth_repository.dart';
import 'auth_feedback.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<AuthSession?> _sessions = widget.auth.sessions;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthSession?>(
      stream: _sessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không thể đọc phiên đăng nhập.'),
                    TextButton(
                      onPressed: () =>
                          setState(() => _sessions = widget.auth.sessions),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final session = snapshot.data;
        return session == null
            ? SignInPage(auth: widget.auth)
            : _SessionPage(
                key: ValueKey(session.uid),
                auth: widget.auth,
                session: session,
              );
      },
    );
  }
}

class _SessionPage extends StatefulWidget {
  const _SessionPage({super.key, required this.auth, required this.session});

  final AuthRepository auth;
  final AuthSession session;

  @override
  State<_SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<_SessionPage> {
  late Future<String> _dataAccess = _checkAccess();
  bool _signingOut = false;
  String? _signOutError;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() {
      _signingOut = true;
      _signOutError = null;
    });
    try {
      await widget.auth.signOut();
    } catch (error) {
      if (mounted) setState(() => _signOutError = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<String> _checkAccess() async {
    try {
      final allowed = await widget.auth.hasDataAccess(refresh: true);
      if (allowed) return 'Tài khoản đã được cấp quyền truy cập dữ liệu.';
      return 'Tài khoản đang chờ quyền truy cập dữ liệu. Liên hệ nhóm trưởng để cấp quyền, rồi kiểm tra lại.';
    } catch (error) {
      return authErrorMessage(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthyLife')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Phiên đăng nhập',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (widget.session.email case final email?) Text(email),
                  const SizedBox(height: 24),
                  FutureBuilder<String>(
                    future: _dataAccess,
                    builder: (context, snapshot) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            snapshot.connectionState == ConnectionState.done
                                ? snapshot.requireData
                                : 'Đang kiểm tra quyền truy cập dữ liệu…',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed:
                              snapshot.connectionState !=
                                      ConnectionState.done ||
                                  _signingOut
                              ? null
                              : () => setState(() {
                                  _dataAccess = _checkAccess();
                                }),
                          child: const Text('Kiểm tra lại quyền'),
                        ),
                      ],
                    ),
                  ),
                  if (_signOutError case final error?)
                    Semantics(liveRegion: true, child: Text(error)),
                  FilledButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: Text(_signingOut ? 'Đang đăng xuất…' : 'Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
