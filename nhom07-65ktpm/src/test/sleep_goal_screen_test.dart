import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dcsleep/data/database/database_helper.dart';
import 'package:dcsleep/providers/sleep_provider.dart';
import 'package:dcsleep/screens/sleep_management/sleep_goal_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.initCustomDatabase(
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabase();
  });

  testWidgets('saving active days stays on the root screen and persists them', (
    tester,
  ) async {
    final provider = SleepProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SleepGoalScreen()),
      ),
    );
    await tester.pump();
    await tester.runAsync(provider.loadData);
    await tester.pump();

    for (final day in ['T3', 'T5', 'T7']) {
      await tester.tap(find.widgetWithText(FilterChip, day));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Lưu Mục Tiêu Giấc Ngủ'),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('Thiết Lập Mục Tiêu Ngủ'), findsOneWidget);
    expect(
      find.text('Đã cập nhật mục tiêu giấc ngủ thành công!'),
      findsOneWidget,
    );

    final savedGoal = await tester.runAsync(
      DatabaseHelper.instance.getSleepGoal,
    );
    expect(savedGoal?.activeDays, 'T2,T4,T6,CN');

    await tester.runAsync(provider.loadData);
    await tester.pump();
    for (final day in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
      final selected = tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, day))
          .selected;
      expect(selected, ['T2', 'T4', 'T6', 'CN'].contains(day));
    }
  });
}
