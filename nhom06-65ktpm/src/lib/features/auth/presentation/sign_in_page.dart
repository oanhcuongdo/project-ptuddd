import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/auth_repository.dart';
import 'auth_feedback.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _emailField = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _showPassword = false;
  bool _busy = false;
  String? _feedback;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Nhập email hợp lệ.';
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      await action();
      if (mounted) setState(() => _feedback = success);
    } catch (error) {
      if (mounted) setState(() => _feedback = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submitEmail() {
    if (_busy || !_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final password = _password.text;
    _run(() async {
      if (_registering) {
        await widget.auth.registerWithEmail(email, password);
      } else {
        await widget.auth.signInWithEmail(email, password);
      }
      TextInput.finishAutofillContext();
    });
  }

  void _resetPassword() {
    if (_busy || !_emailField.currentState!.validate()) return;
    _run(
      () => widget.auth.sendPasswordReset(_email.text.trim()),
      success: 'Nếu email có tài khoản, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('HealthyLife')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _registering
                            ? 'Tạo tài khoản'
                            : 'Đăng nhập vào HealthyLife',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: _emailField,
                        controller: _email,
                        enabled: !_busy,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          helperText: _registering ? 'Ít nhất 6 ký tự' : null,
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Ẩn mật khẩu'
                                : 'Hiện mật khẩu',
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: _busy
                                ? null
                                : () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                          ),
                        ),
                        obscureText: !_showPassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _registering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) => _submitEmail(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nhập mật khẩu.';
                          }
                          if (_registering && value.length < 6) {
                            return 'Mật khẩu cần ít nhất 6 ký tự.';
                          }
                          return null;
                        },
                      ),
                      if (_feedback case final text?) ...[
                        const SizedBox(height: 16),
                        Semantics(liveRegion: true, child: Text(text)),
                      ],
                      if (_busy) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          semanticsLabel: 'Đang xử lý',
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submitEmail,
                        child: Text(_registering ? 'Đăng ký' : 'Đăng nhập'),
                      ),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(widget.auth.signInWithGoogle),
                        child: const Text('Tiếp tục với Google'),
                      ),
                      if (!_registering)
                        TextButton(
                          onPressed: _busy ? null : _resetPassword,
                          child: const Text('Quên mật khẩu?'),
                        ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _form.currentState!.reset();
                                _password.clear();
                                setState(() {
                                  _registering = !_registering;
                                  _showPassword = false;
                                  _feedback = null;
                                });
                              },
                        child: Text(
                          _registering
                              ? 'Quay lại đăng nhập'
                              : 'Tạo tài khoản mới',
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
    );
  }
}
