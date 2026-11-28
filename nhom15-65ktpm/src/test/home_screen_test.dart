import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';
import 'package:soroban_kids_app/core/services/storage_service.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/screens/parent_dashboard_screen.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/presentation/screens/home_screen.dart';
import 'package:soroban_kids_app/injection_container.dart';
import 'package:soroban_kids_app/shared/widgets/kid_card.dart';
import 'package:soroban_kids_app/shared/widgets/kid_badge_card.dart';
import 'package:soroban_kids_app/shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/shared/widgets/panda_mascot.dart';
import 'package:soroban_kids_app/shared/entities/child_profile.dart';

class _TestAudioService implements AudioService {
  @override
  Future<void> playBeadClick() async {}

  @override
  Future<bool> playCorrectAnswerSound() async => true;

  @override
  Future<void> playIncorrectAnswerSound() async {}

  @override
  Future<void> stopFeedback() async {}

  @override
  Future<void> playEncouragementFeedback([String? explanation]) async {}

  @override
  Future<void> playSuccessFeedback([String? customPraise]) async {}

  @override
  Future<void> speak(String text) async {}
}

int _gateAnswer(WidgetTester tester) {
  const numberWords = [
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
  final questionText =
      tester.widget<Text>(find.textContaining('bằng mấy?')).data!;
  final match = RegExp(r'^(.+) (cộng|trừ) (.+) bằng mấy\?$')
      .firstMatch(questionText.toLowerCase())!;
  final first = numberWords.indexOf(match.group(1)!);
  final second = numberWords.indexOf(match.group(3)!);
  return match.group(2) == 'cộng' ? first + second : first - second;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'soroban_child_profile': jsonEncode({
        'id': 'test-child',
        'name': 'Linh',
        'age': 5,
        'streakCount': 8,
        'lastActiveDate': '2026-11-23',
        'unlockedBadgeIds': <String>[],
        'currentLevel': 1,
      }),
      'daily_reminder_enabled': false,
    });
    await sl.reset();
    sl.registerSingleton<AudioService>(_TestAudioService());
    sl.registerSingleton<StorageService>(StorageService());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('HomeScreen shows service streak and four learning actions',
      (WidgetTester tester) async {
    final previousSize = tester.view.physicalSize;
    final previousDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = previousSize;
      tester.view.devicePixelRatio = previousDevicePixelRatio;
    });

    for (final size in [
      const Size(320, 640),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chào bé Linh!'), findsOneWidget);
      expect(find.text('8 ngày'), findsOneWidget);
      expect(find.byType(KidCard), findsNWidgets(5));
      expect(find.byType(KidBadgeCard), findsNWidgets(7));
      expect(find.byType(PandaMascot), findsOneWidget);
      expect(find.text('0/7'), findsOneWidget);
      expect(find.text('Chưa mở'), findsNWidgets(7));
      expect(find.text('Chọn hoạt động'), findsOneWidget);
      expect(find.text('Tập đếm'), findsOneWidget);
      expect(find.text('Luyện tập'), findsOneWidget);
      expect(find.text('Flash Anzan'), findsOneWidget);
      expect(find.text('Phụ huynh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Home shows earned and locked badges from the saved profile',
      (WidgetTester tester) async {
    final storage = sl<StorageService>();
    final profile = await storage.getChildProfile();
    await storage.saveChildProfile(
      profile.copyWith(
        streakCount: 2,
        unlockedBadgeIds: const ['starter_star'],
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('2 ngày'), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);
    expect(find.text('Đã đạt'), findsOneWidget);
    expect(find.text('Chưa mở'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice action offers both existing lesson levels',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Luyện tập'));
    await tester.tap(find.text('Luyện tập'));
    await tester.pumpAndSettle();

    expect(find.text('Toán cơ bản'), findsOneWidget);
    expect(find.text('Công thức'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows no earned streak when no profile has been saved',
      (WidgetTester tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('soroban_child_profile');

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('0 ngày'), findsOneWidget);
    final profile = await sl<StorageService>().getChildProfile();
    expect(profile.streakCount, 0);
    expect(profile.longestStreak, 0);
    expect(profile.lastActiveDate, isEmpty);
    expect(profile.unlockedBadgeIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('ChildProfile defaults missing gamification data to zero progress', () {
    final profile = ChildProfile.fromMap({
      'id': 'new-child',
      'name': 'Linh',
      'age': 5,
      'currentLevel': 1,
    });

    expect(profile.streakCount, 0);
    expect(profile.longestStreak, 0);
    expect(profile.unlockedBadgeIds, isEmpty);
  });

  testWidgets('tapping Tap dem opens finger math board modal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tập đếm'));
    await tester.tap(find.text('Tập đếm'));
    await tester.pumpAndSettle();

    expect(find.byType(FingerMathBoardWidget), findsOneWidget);
    expect(find.text('Nghe số'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Flash Anzan navigates to FlashAnzanScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Flash Anzan'));
    await tester.tap(find.text('Flash Anzan'));
    await tester.pumpAndSettle();

    expect(find.byType(FlashAnzanScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home reloads streak data after returning from Flash Anzan',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Flash Anzan'));
    await tester.tap(find.text('Flash Anzan'));
    await tester.pumpAndSettle();

    final storage = sl<StorageService>();
    final profile = await storage.getChildProfile();
    await storage.saveChildProfile(profile.copyWith(streakCount: 9));

    Navigator.of(tester.element(find.byType(FlashAnzanScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.text('9 ngày'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Phu huynh opens ParentalGateDialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Phụ huynh'));
    await tester.tap(find.text('Phụ huynh'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentalGateDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ParentalGate stays closed on wrong answer and opens on correct answer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Phụ huynh'));
    await tester.tap(find.text('Phụ huynh'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bằng mấy?'), findsOneWidget);
    final answer = _gateAnswer(tester);

    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();

    expect(find.byType(ParentalGateDialog), findsOneWidget);
    expect(
        find.text('Kết quả chưa chính xác. Vui lòng thử lại.'), findsOneWidget);
    expect(find.byType(ParentDashboardScreen), findsNothing);

    await tester.enterText(find.byType(TextField), '$answer');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentalGateDialog), findsNothing);
    expect(find.byType(ParentDashboardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling Parental Gate keeps the Home screen and no dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Phụ huynh'));
    await tester.tap(find.text('Phụ huynh'));
    await tester.pumpAndSettle();
    expect(find.byType(ParentalGateDialog), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentalGateDialog), findsNothing);
    expect(find.byType(ParentDashboardScreen), findsNothing);
    expect(find.text('Phụ huynh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tapping practice and selecting Toan co ban navigates to LessonPlayScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Luyện tập'));
    await tester.tap(find.text('Luyện tập'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toán cơ bản'));
    // LessonPlayScreen has a repeating mic button animation, pump instead of pumpAndSettle:
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LessonPlayScreen), findsOneWidget);
    final checkButton = find.widgetWithText(
      FilledButton,
      'KIỂM TRA BÀN TAY',
    );
    final checkIcon = find.descendant(
      of: checkButton,
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(
        IconTheme.of(tester.element(checkIcon)).color, AppColors.onSecondary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Panda expressions render without requiring image assets',
      (WidgetTester tester) async {
    for (final expression in PandaExpression.values) {
      await tester.pumpWidget(
        MaterialApp(home: PandaMascot(expression: expression)),
      );
      expect(find.byType(PandaMascot), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Panda bubble scales down on narrow phone screens',
      (WidgetTester tester) async {
    final previousSize = tester.view.physicalSize;
    final previousDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = previousSize;
      tester.view.devicePixelRatio = previousDevicePixelRatio;
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        home: MascotBubbleWidget(
          speechText:
              'Chào bé Linh! Hôm nay mình cùng chơi toán nhé, cố gắng lên nào!',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PandaMascot)), const Size(58, 58));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Panda expression changes animate between existing expressions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MascotBubbleWidget(
          speechText: 'Chào bé!',
          expression: PandaExpression.happy,
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MascotBubbleWidget(
          speechText: 'Cùng cố gắng nhé!',
          expression: PandaExpression.encouraging,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AnimatedSwitcher), findsOneWidget);
    expect(find.byType(PandaMascot), findsNWidgets(2));

    await tester.pumpAndSettle();
    expect(find.byType(PandaMascot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Panda invokes its welcome action',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MascotBubbleWidget(
          speechText: 'Chào bé!',
          onMascotTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(PandaMascot));
    await tester.pump();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
