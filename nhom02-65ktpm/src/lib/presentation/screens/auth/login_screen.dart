import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/auth_strings.dart';
import '../../../domain/repositories/auth_repository.dart';

/// Màn hình Đăng nhập / Đăng ký (Email + Google).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = sl<AuthRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _run(Future<Result<void>> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    // Thành công: AuthGate tự chuyển màn hình nhờ lắng nghe authStateChanges.
    if (result case Err(:final failure) when failure.type != FailureType.cancelled) {
      _showMessage(failure.message);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegister) {
      _run(() => _auth.registerWithEmail(
            _emailCtrl.text,
            _passwordCtrl.text,
            _nameCtrl.text,
          ));
    } else {
      _run(() => _auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text));
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      _showMessage(AuthStrings.enterEmailFirst);
      return;
    }
    final result = await _auth.sendPasswordReset(email);
    if (!mounted) return;
    _showMessage(switch (result) {
      Ok() => AuthStrings.resetEmailSent,
      Err(:final failure) => failure.message,
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.eco_rounded, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      AuthStrings.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthStrings.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text(AuthStrings.signInTab)),
                        ButtonSegment(value: true, label: Text(AuthStrings.registerTab)),
                      ],
                      selected: {_isRegister},
                      onSelectionChanged: _busy
                          ? null
                          : (value) => setState(() => _isRegister = value.first),
                    ),
                    const SizedBox(height: 20),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: AuthStrings.displayName,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? AuthStrings.nameRequired : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: AuthStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => _emailRegex.hasMatch(v?.trim() ?? '')
                          ? null
                          : AuthStrings.invalidEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: (_) => _isRegister ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: AuthStrings.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? AuthStrings.passwordTooShort : null,
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: AuthStrings.confirmPassword,
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            v != _passwordCtrl.text ? AuthStrings.passwordMismatch : null,
                      ),
                    ],
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text(AuthStrings.forgotPassword),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegister ? AuthStrings.register : AuthStrings.signIn),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(AuthStrings.or, style: theme.textTheme.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(_auth.signInWithGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text(AuthStrings.signInWithGoogle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
