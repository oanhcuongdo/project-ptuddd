import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/core/theme/app_theme.dart';
import 'package:nhom14_app/screens/auth_gate.dart';
import 'package:nhom14_app/screens/login_screen.dart';

void main() {
  group('AuthGate & SplashLoadingView Tests', () {
    testWidgets('SplashLoadingView displays correctly with standardized theme elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashLoadingView(),
        ),
      );

      // 1. Kiểm tra tiêu đề và thông điệp kiểm tra phiên
      expect(find.text('HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN'), findsOneWidget);
      expect(find.text('Đang kiểm tra phiên đăng nhập...'), findsOneWidget);

      // 2. Kiểm tra biểu tượng trường học và tiến trình loading
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AuthGate renders SplashLoadingView initially then transitions to LoginScreen when unauthenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
        ),
      );

      // Khung hình đầu: đang tải phiên
      expect(find.byType(SplashLoadingView), findsOneWidget);
      expect(find.text('Đang kiểm tra phiên đăng nhập...'), findsOneWidget);

      // Sau khi microtask kiểm tra phiên hoàn thành: hiển thị LoginScreen
      await tester.pumpAndSettle();

      expect(find.byType(SplashLoadingView), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
    });
  });
}
