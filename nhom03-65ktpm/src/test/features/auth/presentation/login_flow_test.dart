import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/auth/domain/entities/app_user.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late AppDependencies dependencies;

  setUp(() {
    authRepository = FakeAuthRepository();
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
  });

  tearDown(() => authRepository.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  /// Gỡ widget trước khi đóng database để cubit huỷ subscription, tránh lỗi
  /// "Timer is still pending".
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'minh@example.com',
    String password = 'matkhau123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  Future<void> fillRegisterForm(
    WidgetTester tester, {
    String email = 'minh@example.com',
    String password = 'matkhau123',
    String confirmPassword = 'matkhau123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), confirmPassword);
  }

  /// Màn đăng nhập cuộn được (có hero thương hiệu), nên trên khung test
  /// 800x600 phải cuộn nút vào vùng nhìn thấy trước khi bấm.
  Future<void> tapLoginButton(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreateAccountButton(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Tạo tài khoản');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> openRegisterPage(WidgetTester tester) async {
    final registerLink = find.text('Chưa có tài khoản? Đăng ký');
    await tester.ensureVisible(registerLink);
    await tester.pumpAndSettle();
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
  }

  testWidgets('Chưa đăng nhập thì hiển thị màn đăng nhập', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsOneWidget);
    expect(find.text('Chưa có ghi chú nào'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('Đăng nhập đúng thì vào màn hình chính', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await fillForm(tester);

    await tapLoginButton(tester);

    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets(
    'Sai mật khẩu thì hiển thị lỗi tiếng Việt và ở lại màn đăng nhập',
    (WidgetTester tester) async {
      authRepository.signInFailure = const AuthFailure(
        'Email hoặc mật khẩu không đúng.',
        code: 'wrong-password',
      );
      await pumpApp(tester);
      await fillForm(tester, password: 'saithat');

      await tapLoginButton(tester);

      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.text('Chưa có ghi chú nào'), findsNothing);

      await disposeApp(tester);
    },
  );

  // Hồi quy: AuthCubit phải nằm trên MaterialApp, nếu không route đăng ký
  // (push bằng MaterialPageRoute) sẽ không đọc được provider và ném lỗi đỏ.
  testWidgets('Mở được màn đăng ký từ màn đăng nhập', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openRegisterPage(tester);

    expect(find.widgetWithText(FilledButton, 'Tạo tài khoản'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('Đăng ký đúng thì vào màn hình chính', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openRegisterPage(tester);
    await fillRegisterForm(tester);

    await tapCreateAccountButton(tester);

    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('Nhập lại mật khẩu sai thì báo lỗi và không đăng ký', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openRegisterPage(tester);
    await fillRegisterForm(tester, confirmPassword: 'khac-hoan-toan');

    await tapCreateAccountButton(tester);

    expect(find.text('Mật khẩu nhập lại không khớp.'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsWidgets);
    expect(find.text('Chưa có ghi chú nào'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('Xác nhận đăng xuất thì quay về màn đăng nhập', (
    WidgetTester tester,
  ) async {
    await dependencies.dispose();
    await authRepository.dispose();
    authRepository = FakeAuthRepository(
      initialUser: const AppUser(id: 'uid-1', email: 'minh@example.com'),
    );
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Bộ lọc và công cụ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsOneWidget);
    expect(find.text('Chưa có ghi chú nào'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('Mất mạng khi đăng nhập thì báo lỗi mạng rõ ràng', (
    WidgetTester tester,
  ) async {
    authRepository.signInFailure = const AuthFailure(
      'Không có kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.',
      code: 'network-request-failed',
    );
    await pumpApp(tester);
    await fillForm(tester);

    await tapLoginButton(tester);

    expect(
      find.text('Không có kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('Email sai định dạng bị chặn trước khi gọi Firebase', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await fillForm(tester, email: 'khong-phai-email');

    await tapLoginButton(tester);

    expect(find.text('Email không hợp lệ.'), findsOneWidget);

    await disposeApp(tester);
  });
}
