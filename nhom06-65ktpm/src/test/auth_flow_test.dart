import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthylife/features/auth/domain/auth_repository.dart';
import 'package:healthylife/features/auth/presentation/auth_gate.dart';

void main() {
  late _TestAuth auth;

  setUp(() => auth = _TestAuth());
  tearDown(() => auth.changes.close());

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: auth)));
    auth.changes.add(null);
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, password);
  }

  testWidgets(
    'invalid form stays local and failed login hides server details',
    (tester) async {
      await openApp(tester);
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
      expect(find.text('Nhập mật khẩu.'), findsOneWidget);
      expect(auth.emailAttempts, 0);

      auth.failure = AuthFailure.invalidCredentials;
      await fillForm(tester, 'tester@example.com ', ' test password ');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(auth.lastEmail, 'tester@example.com');
      expect(auth.lastPassword, ' test password ');
      expect(find.text('Phiên đăng nhập'), findsNothing);
    },
  );

  testWidgets('session requires the data claim and clears when signed out', (
    tester,
  ) async {
    await openApp(tester);
    await fillForm(tester, 'tester@example.com', 'test-password');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Phiên đăng nhập'), findsOneWidget);
    expect(
      find.textContaining('đang chờ quyền truy cập dữ liệu'),
      findsOneWidget,
    );
    expect(auth.claimRefreshes, 1);

    auth.dataAccess = true;
    await tester.tap(find.text('Kiểm tra lại quyền'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tài khoản đã được cấp quyền truy cập dữ liệu.'),
      findsOneWidget,
    );
    expect(auth.claimRefreshes, 2);

    auth.failure = AuthFailure.sessionExpired;
    await tester.tap(find.text('Kiểm tra lại quyền'));
    await tester.pumpAndSettle();
    expect(find.text('Phiên đã hết hạn. Hãy đăng nhập lại.'), findsOneWidget);
    expect(
      find.text('Tài khoản đã được cấp quyền truy cập dữ liệu.'),
      findsNothing,
    );

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập vào HealthyLife'), findsOneWidget);
    expect(find.text('tester@example.com'), findsNothing);
  });

  testWidgets(
    'registration rejects short password and uses registration flow',
    (tester) async {
      await openApp(tester);
      await tester.tap(find.text('Tạo tài khoản mới'));
      await tester.pumpAndSettle();
      await fillForm(tester, 'tester@example.com', '12345');
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu cần ít nhất 6 ký tự.'), findsOneWidget);
      expect(auth.registrations, 0);
      await fillForm(tester, 'tester@example.com', 'valid-password');
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();
      expect(auth.registrations, 1);
      expect(auth.emailAttempts, 0);
      expect(find.text('Phiên đăng nhập'), findsOneWidget);
    },
  );

  testWidgets('password reset accepts email alone and uses neutral feedback', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, isNull);
    await tester.enterText(
      find.byType(TextFormField).first,
      ' tester@example.com ',
    );
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'tester@example.com');
    expect(find.textContaining('Nếu email có tài khoản'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsNothing);
  });

  testWidgets('Google requests are not duplicated and can retry after cancel', (
    tester,
  ) async {
    await openApp(tester);
    final firstAttempt = Completer<void>();
    auth.googlePending = firstAttempt;
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Tiếp tục với Google'),
    );
    expect(button.onPressed, isNull);
    expect(auth.googleAttempts, 1);

    firstAttempt.completeError(AuthFailure.googleCanceled);
    await tester.pumpAndSettle();
    expect(find.text('Chưa hoàn tất đăng nhập Google.'), findsOneWidget);

    auth.googlePending = null;
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    expect(auth.googleAttempts, 2);
    expect(find.text('Phiên đăng nhập'), findsOneWidget);
  });
}

class _TestAuth implements AuthRepository {
  final changes = StreamController<AuthSession?>.broadcast();
  AuthFailure? failure;
  Completer<void>? googlePending;
  bool dataAccess = false;
  int emailAttempts = 0;
  int registrations = 0;
  int googleAttempts = 0;
  int claimRefreshes = 0;
  String? lastEmail;
  String? lastPassword;
  String? resetEmail;

  @override
  Stream<AuthSession?> get sessions => changes.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    emailAttempts++;
    lastEmail = email;
    lastPassword = password;
    if (failure case final error?) throw error;
    changes.add(AuthSession(uid: 'test-user', email: email));
  }

  @override
  Future<void> registerWithEmail(String email, String password) async {
    registrations++;
    changes.add(AuthSession(uid: 'test-user', email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmail = email;

  @override
  Future<void> signInWithGoogle() async {
    googleAttempts++;
    await googlePending?.future;
    changes.add(
      const AuthSession(uid: 'google-user', email: 'google@example.com'),
    );
  }

  @override
  Future<void> signOut() async => changes.add(null);

  @override
  Future<bool> hasDataAccess({bool refresh = false}) async {
    if (refresh) claimRefreshes++;
    if (failure case final error?) throw error;
    return dataAccess;
  }
}
