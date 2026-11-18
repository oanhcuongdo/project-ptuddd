import 'package:buddytalk/core/theme/app_theme.dart';
import 'package:buddytalk/core/theme/theme_mode_controller.dart';
import 'package:buddytalk/main.dart' show BuddyTalkApp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to system mode and persists the selected mode', () async {
      final controller = await ThemeModeController.load();

      expect(controller.themeMode, ThemeMode.system);

      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString('theme_mode'),
        'dark',
      );
    });

    test('restores a saved mode when loaded again', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

      final controller = await ThemeModeController.load();

      expect(controller.themeMode, ThemeMode.light);
    });
  });

  test('provides Material 3 color schemes for both brightness modes', () {
    expect(AppTheme.lightTheme.useMaterial3, isTrue);
    expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.useMaterial3, isTrue);
    expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    expect(AppTheme.lightTheme.colorScheme.secondary, AppTheme.secondaryColor);
    expect(AppTheme.darkTheme.colorScheme.tertiary, AppTheme.accentColor);
  });

  testWidgets('changing the profile selection applies and saves dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await ThemeModeController.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const BuddyTalkApp(),
      ),
    );

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('theme_mode'),
      'dark',
    );
  });
}
