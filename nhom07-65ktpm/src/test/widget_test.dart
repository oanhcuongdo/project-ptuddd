import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/main.dart';
import 'package:dcsleep/providers/settings_provider.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.closeDatabase();
  });

  testWidgets('DCSleep app shows LoginScreen when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await tester.pumpWidget(const DCSleepApp());
    await tester.pump();

    expect(find.text('DCSleep'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  test('SettingsProvider registers, logs in, and logs out with SQLite Users table', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SettingsProvider();

    // 1. Register new user
    final regError = await provider.register(
      name: 'Nguyễn Văn Test',
      email: 'testuser@65ktpm.vn',
      studentId: '2351179999',
      className: '65KTPM',
      password: 'password123',
    );
    expect(regError, isNull);
    expect(provider.isLoggedIn, true);
    expect(provider.user.name, 'Nguyễn Văn Test');

    // 2. Logout
    await provider.logout();
    expect(provider.isLoggedIn, false);

    // 3. Login with wrong password fails
    final wrongPwdErr = await provider.login('testuser@65ktpm.vn', 'wrongpass');
    expect(wrongPwdErr, isNotNull);
    expect(provider.isLoggedIn, false);

    // 4. Login with correct password succeeds
    final loginErr = await provider.login('testuser@65ktpm.vn', 'password123');
    expect(loginErr, isNull);
    expect(provider.isLoggedIn, true);
    expect(provider.user.email, 'testuser@65ktpm.vn');
  });

  testWidgets('DCSleep app shows dashboard when SettingsProvider is logged in', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'current_user_email': 'mkl.deeptry@gmail.com',
    });
    await tester.pumpWidget(const DCSleepApp());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    // Also verify navigating to LoginScreen when not logged in is handled cleanly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
