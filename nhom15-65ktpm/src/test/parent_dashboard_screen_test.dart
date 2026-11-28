import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/screens/parent_dashboard_screen.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

const _numberWords = [
  'không',
  'một',
  'hai',
  'ba',
  'bốn',
  'năm',
  'sáu',
  'bảy',
  'tám',
  'chín',
  'mười',
  'mười một',
  'mười hai',
  'mười ba',
  'mười bốn',
  'mười lăm',
  'mười sáu',
  'mười bảy',
  'mười tám',
  'mười chín',
  'hai mươi',
];

class _DashboardHost extends StatelessWidget {
  const _DashboardHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => ParentDashboardRoute.open(context),
          child: const Text('Mở khu vực phụ huynh'),
        ),
      ),
    );
  }
}

int _answerFromQuestion(String text) {
  final match = RegExp(r'^(.+) (cộng|trừ) (.+) bằng mấy\?$')
      .firstMatch(text.toLowerCase())!;
  final first = _numberWords.indexOf(match.group(1)!);
  final second = _numberWords.indexOf(match.group(3)!);
  return match.group(2) == 'cộng' ? first + second : first - second;
}

Future<void> _openDashboard(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: const _DashboardHost(),
    ),
  );
  await tester.tap(find.text('Mở khu vực phụ huynh'));
  await tester.pumpAndSettle();
  expect(find.byType(ParentalGateDialog), findsOneWidget);

  final question = tester.widget<Text>(find.textContaining('bằng mấy?')).data!;
  await tester.enterText(
    find.byType(TextField),
    '${_answerFromQuestion(question)}',
  );
  await tester.tap(find.text('Xác nhận'));
  await tester.pumpAndSettle();
  expect(find.byType(ParentDashboardScreen), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'soroban_child_profile': jsonEncode({
        'id': 'dashboard-child',
        'name': 'Linh',
        'age': 5,
        'streakCount': 2,
        'longestStreak': 4,
        'lastActiveDate': '',
        'unlockedBadgeIds': <String>[],
        'currentLevel': 1,
      }),
      'daily_reminder_enabled': false,
    });
    await sl.reset();
    sl.registerSingleton<StorageService>(StorageService());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('dashboard shows real overview and attempt history',
      (tester) async {
    final storage = sl<StorageService>();
    final attemptTimestamp = DateTime.now().toIso8601String();
    await storage.saveAttemptLog(
      AttemptLog(
        questionId: 'q-1',
        questionText: 'Bốn cộng hai',
        userAnswer: 6,
        isCorrect: true,
        responseTimeMs: 500,
        answeredVia: 'voice',
        timestamp: attemptTimestamp,
      ),
    );
    await storage.saveAttemptLog(
      AttemptLog(
        questionId: 'q-2',
        questionText: 'Bảy trừ ba',
        userAnswer: 5,
        isCorrect: false,
        responseTimeMs: 1000,
        answeredVia: 'abacus_touch',
        timestamp: attemptTimestamp,
      ),
    );
    await storage.saveAttemptLog(
      AttemptLog(
        questionId: 'q-3',
        questionText: 'Ba cộng ba',
        userAnswer: 6,
        isCorrect: true,
        responseTimeMs: 1500,
        answeredVia: 'abacus_touch',
        timestamp: attemptTimestamp,
      ),
    );

    await _openDashboard(tester);

    expect(find.text('Tổng quan tiến độ học tập'), findsOneWidget);
    expect(find.text('Câu hỏi đã hoàn thành'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('1.0s'), findsOneWidget);
    expect(find.text('2 / 3 câu đúng'), findsOneWidget);
    expect(find.text('Thống kê theo ngày trong tuần'), findsOneWidget);
    expect(find.text('Số lượt làm trong 7 ngày gần nhất'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(DateTime.daysPerWeek));
    expect(
      chart.data.barGroups[DateTime.now().weekday - DateTime.monday]
          .barRods
          .single
          .toY,
      3,
    );
    expect(find.text('Bốn cộng hai'), findsOneWidget);
    expect(find.text('Bảy trừ ba'), findsOneWidget);
    expect(find.text('Ba cộng ba'), findsOneWidget);
    expect(find.text('Chính xác'), findsNWidgets(2));
    expect(find.text('Chưa chính xác'), findsOneWidget);
    expect(find.text('Câu trả lời: 5'), findsOneWidget);
    expect(find.text('Thời gian: 500 ms'), findsOneWidget);
    final localAttemptTime = DateTime.parse(attemptTimestamp).toLocal();
    final formattedAttemptTime =
        '${localAttemptTime.day.toString().padLeft(2, '0')}/'
        '${localAttemptTime.month.toString().padLeft(2, '0')}/'
        '${localAttemptTime.year} '
        '${localAttemptTime.hour.toString().padLeft(2, '0')}:'
        '${localAttemptTime.minute.toString().padLeft(2, '0')}';
    expect(find.text(formattedAttemptTime), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('history sorts attempts newest first', (tester) async {
    final now = DateTime.now();
    final newestTimestamp = now.toIso8601String();
    final olderTimestamp = now.subtract(const Duration(days: 1)).toIso8601String();
    final storage = sl<StorageService>();
    await storage.saveAttemptLog(
      AttemptLog(
        questionId: 'newest',
        questionText: 'Câu mới nhất',
        userAnswer: 8,
        isCorrect: false,
        responseTimeMs: 1200,
        answeredVia: 'abacus_touch',
        timestamp: newestTimestamp,
      ),
    );
    await storage.saveAttemptLog(
      AttemptLog(
        questionId: 'older',
        questionText: 'Câu cũ hơn',
        userAnswer: 7,
        isCorrect: true,
        responseTimeMs: 900,
        answeredVia: 'voice',
        timestamp: olderTimestamp,
      ),
    );

    await _openDashboard(tester);

    final newestPosition = tester.getTopLeft(find.text('Câu mới nhất'));
    final olderPosition = tester.getTopLeft(find.text('Câu cũ hơn'));
    expect(newestPosition.dy, lessThan(olderPosition.dy));
    expect(find.text('Chưa chính xác'), findsOneWidget);
    expect(find.text('Chính xác'), findsOneWidget);
    expect(find.text('Thời gian: 1200 ms'), findsOneWidget);
    expect(find.text('Thời gian: 900 ms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty progress does not display fabricated percentages or times',
      (tester) async {
    await _openDashboard(tester);

    expect(find.text('0'), findsNWidgets(8));
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Chưa có dữ liệu'), findsNWidgets(2));
    expect(
        find.text('Chưa có lịch sử làm bài theo bộ lọc này.'), findsOneWidget);
    expect(find.text('Chưa có dữ liệu trong 7 ngày gần nhất'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(DateTime.daysPerWeek));
    expect(
      chart.data.barGroups.every(
        (group) => group.barRods.single.toY == 0,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh reloads statistics after a new attempt is stored',
      (tester) async {
    await _openDashboard(tester);
    await sl<StorageService>().saveAttemptLog(
      AttemptLog(
        questionId: 'new-attempt',
        userAnswer: 6,
        isCorrect: true,
        responseTimeMs: 800,
        answeredVia: 'abacus_touch',
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1 / 1 câu đúng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard layout adapts to narrow, tablet and desktop widths',
      (tester) async {
    final oldSize = tester.view.physicalSize;
    final oldRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = oldSize;
      tester.view.devicePixelRatio = oldRatio;
    });

    for (final size in [
      const Size(320, 720),
      const Size(768, 900),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await _openDashboard(tester);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Bảng điều khiển phụ huynh'), findsOneWidget);
      expect(find.text('Lịch sử làm bài chi tiết'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Viewport $size');
    }
  });
}
