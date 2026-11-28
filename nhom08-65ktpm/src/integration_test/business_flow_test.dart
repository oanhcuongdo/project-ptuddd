import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:travel_buddy/features/auth_and_group/repository/auth_repository.dart';
import 'package:travel_buddy/features/auth_and_group/repository/trip_repository.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/utils/cashew_calculator.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/utils/debt_simplifier.dart';
import 'package:travel_buddy/features/goal_and_checklist/repository/checklist_repository.dart';
import 'package:travel_buddy/features/place_and_itinerary_planner/repository/itinerary_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/in_memory_saving_repository.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/repository/saving_repository_impl.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/saving_calculator.dart';
import 'package:travel_buddy/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final List<String> runtimeErrors = <String>[];
  FlutterExceptionHandler? originalOnError;

  setUpAll(() {
    originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      runtimeErrors.add(details.exceptionAsString());
      originalOnError?.call(details);
    };
  });

  tearDownAll(() {
    FlutterError.onError = originalOnError;
  });

  Widget buildTestApp({
    required AuthRepository authRepo,
    required TripRepository tripRepo,
    required ChecklistRepository checklistRepo,
    required InMemorySavingRepository savingRepo,
    required ItineraryRepository itineraryRepo,
    Size? viewportSize,
    double textScale = 1.0,
  }) {
    final app = ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        tripRepositoryProvider.overrideWithValue(tripRepo),
        checklistRepositoryProvider.overrideWithValue(checklistRepo),
        savingRepositoryProvider.overrideWithValue(savingRepo),
        itineraryRepositoryProvider.overrideWithValue(itineraryRepo),
      ],
      child: const TravelBuddyApp(),
    );

    if (viewportSize == null && textScale == 1.0) {
      return app;
    }

    return MediaQuery(
      data: MediaQueryData(
        size: viewportSize ?? const Size(360, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: app,
    );
  }

  group('Travel Buddy E2E Business Flow Tests', () {
    testWidgets('TC-AUTH-03 & TC-AUTH-02: Auth Guard, validation & login flow', (tester) async {
      runtimeErrors.clear();
      final authRepo = InMemoryAuthRepository(seedSignedIn: false);
      final tripRepo = InMemoryTripRepository();
      final checklistRepo = InMemoryChecklistRepository(seedDemo: false);
      final savingRepo = InMemorySavingRepository(seedDemo: true);
      final itineraryRepo = InMemoryItineraryRepository();

      // TC-AUTH-03 (Unauthenticated -> redirected to /login)
      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          tripRepo: tripRepo,
          checklistRepo: checklistRepo,
          savingRepo: savingRepo,
          itineraryRepo: itineraryRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

      // TC-AUTH-02: Invalid email format "abc@" -> must stay on LoginScreen & show error
      await tester.enterText(find.byKey(const Key('login_email_field')), 'abc@');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'Wrong@123');
      await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Địa chỉ email không đúng định dạng.'), findsOneWidget);

      // TC-AUTH-02: Valid email, wrong password -> must stay on LoginScreen
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'host.test@travelbuddy.vn',
      );
      await tester.enterText(find.byKey(const Key('login_password_field')), 'Wrong@999');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Email hoặc mật khẩu chưa chính xác.'), findsOneWidget);

      // Sign in with valid test account
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'host.test@travelbuddy.vn',
      );
      await tester.enterText(find.byKey(const Key('login_password_field')), 'Test@123456');
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chuyến đi'), findsWidgets);

      // TC-AUTH-03 (Re-opening app with active session -> skips /login straight to /trips)
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          tripRepo: tripRepo,
          checklistRepo: checklistRepo,
          savingRepo: savingRepo,
          itineraryRepo: itineraryRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_submit_button')), findsNothing);
      expect(find.text('Chuyến đi'), findsWidgets);
      expect(runtimeErrors.where((e) => e.contains('RenderFlex overflowed')), isEmpty);
    });

    testWidgets('TC-M1-02, TC-M1-01, TC-M1-05: Trip validation, create & checklist progress', (tester) async {
      runtimeErrors.clear();
      final authRepo = InMemoryAuthRepository(seedSignedIn: true);
      final tripRepo = InMemoryTripRepository();
      final checklistRepo = InMemoryChecklistRepository(seedDemo: false);
      final savingRepo = InMemorySavingRepository(seedDemo: true);
      final itineraryRepo = InMemoryItineraryRepository();

      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          tripRepo: tripRepo,
          checklistRepo: checklistRepo,
          savingRepo: savingRepo,
          itineraryRepo: itineraryRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Open CreateTripQrScreen
      await tester.tap(find.byKey(const Key('trip_list_add_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_trip_title_field')), findsOneWidget);

      // TC-M1-02: Negative budget "-500000" must be rejected and NOT navigate away
      await tester.enterText(find.byKey(const Key('create_trip_title_field')), 'Phú Quốc 4N3Đ');
      await tester.enterText(find.byKey(const Key('create_trip_dest_field')), 'Phú Quốc');
      await tester.enterText(find.byKey(const Key('create_trip_budget_field')), '-500000');
      await tester.tap(find.byKey(const Key('create_trip_save_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('create_trip_save_button')),
        findsOneWidget,
        reason: 'Negative budget should be blocked by validation',
      );

      // TC-M1-01: Valid trip creation
      await tester.enterText(find.byKey(const Key('create_trip_budget_field')), '8000000');
      await tester.tap(find.byKey(const Key('create_trip_save_button')));
      await tester.pumpAndSettle();

      // Should land on ChecklistScreen for the new trip
      expect(find.text('Phú Quốc 4N3Đ'), findsOneWidget);
      expect(find.byKey(const Key('checklist_countdown_text')), findsOneWidget);
      expect(find.text('0%'), findsWidgets);

      // Let the trip-created SnackBar dismiss so it does not cover the FAB.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Add 4 checklist items so TC-M1-05 tests exact 0% -> 25% -> 0%
      for (var i = 1; i <= 4; i++) {
        await tester.tap(find.byKey(const Key('checklist_add_fab')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('checklist_add_title_field')),
          'Đầu việc $i',
        );
        await tester.ensureVisible(find.byKey(const Key('checklist_add_submit_button')));
        await tester.tap(find.byKey(const Key('checklist_add_submit_button')));
        await tester.pumpAndSettle();
      }

      final readinessText = find.byKey(const Key('checklist_readiness_percent'));
      expect(tester.widget<Text>(readinessText).data, '0%');

      // TC-M1-05: Toggle first checklist item -> 25%, uncheck -> 0%
      final firstToggle = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('checklist_toggle_'),
      ).first;

      await tester.ensureVisible(firstToggle);
      await tester.tap(firstToggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(readinessText).data, '25%');

      await tester.tap(firstToggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(readinessText).data, '0%');
      expect(runtimeErrors.where((e) => e.contains('RenderFlex overflowed')), isEmpty);
    });

    test('TC-M2-01 & TC-M2-02: SavingCalculator period division & odd remainder accuracy', () {
      final start = DateTime(2026, 6, 1);

      // TC-M2-01: 2,000,000 VND over 28 days weekly -> 4 periods x 500,000 VND
      final evenResult = SavingCalculator.calculateInstallments(
        targetAmount: 2000000,
        startDate: start,
        deadlineDate: start.add(const Duration(days: 28)),
        preferredFrequency: SavingFrequency.weekly,
      );
      expect(evenResult.totalInstallments, 4);
      expect(evenResult.installmentAmount, 500000.0);
      expect(
        evenResult.schedule.fold<double>(0.0, (sum, item) => sum + item.amount),
        2000000.0,
      );
      for (var i = 0; i < evenResult.schedule.length; i++) {
        expect(
          evenResult.schedule[i].dueDate,
          start.add(Duration(days: (i + 1) * 7)),
        );
      }

      // TC-M2-02: 1,000,000 VND over 21 days weekly (3 periods) -> exact 1,000,000 sum
      final oddResult = SavingCalculator.calculateInstallments(
        targetAmount: 1000000,
        startDate: start,
        deadlineDate: start.add(const Duration(days: 21)),
        preferredFrequency: SavingFrequency.weekly,
      );
      expect(oddResult.totalInstallments, 3);
      expect(
        oddResult.schedule.fold<double>(0.0, (sum, item) => sum + item.amount),
        1000000.0,
      );
    });

    testWidgets('TC-M3-02, TC-M4-02, TC-M4-05 & TC-NF-01: Itinerary conflict, Cashew keypad, Debt Simplification & Overflow guard', (tester) async {
      runtimeErrors.clear();
      final authRepo = InMemoryAuthRepository(seedSignedIn: true);
      final tripRepo = InMemoryTripRepository();
      final checklistRepo = InMemoryChecklistRepository(seedDemo: true);
      final savingRepo = InMemorySavingRepository(seedDemo: true);
      final itineraryRepo = InMemoryItineraryRepository();

      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          tripRepo: tripRepo,
          checklistRepo: checklistRepo,
          savingRepo: savingRepo,
          itineraryRepo: itineraryRepo,
          viewportSize: const Size(360, 640),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      // Open demo trip
      await tester.tap(find.text('Đà Lạt 4N3Đ').first);
      await tester.pumpAndSettle();

      // Tab 2: MoMo Fund (check responsive / no overflow)
      await tester.tap(find.byKey(const Key('nav_tab_momo')));
      await tester.pumpAndSettle();

      // Tab 3: Itinerary & TC-M3-02 conflict check
      await tester.tap(find.byKey(const Key('nav_tab_itinerary')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('itinerary_add_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('activity_name_field')), 'Hồ Xuân Hương');
      await tester.enterText(find.byKey(const Key('activity_duration_field')), '120');
      await tester.ensureVisible(find.byKey(const Key('activity_save_button')));
      await tester.tap(find.byKey(const Key('activity_save_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('itinerary_add_fab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('activity_name_field')), 'Quảng trường Lâm Viên');
      expect(find.byKey(const Key('activity_conflict_warning')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('activity_save_button')));
      await tester.tap(find.byKey(const Key('activity_save_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('itinerary_conflict_banner')), findsOneWidget);

      // Tab 4: Budget & TC-M4-05 / TC-M4-02
      await tester.tap(find.byKey(const Key('nav_tab_budget')));
      await tester.pumpAndSettle();

      // TC-M4-05: Scroll to dynamic settlement section and trigger simplify action
      await tester.scrollUntilVisible(
        find.byKey(const Key('budget_simplify_debt_button')),
        200,
      );
      expect(find.byKey(const Key('budget_simplify_debt_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('budget_simplify_debt_button')));
      await tester.pumpAndSettle();

      // Verify exact DebtSimplifier calculation for 4 members from TEST_PLAN
      final settlements = DebtSimplifier.simplifyEqualSplit(const [
        MemberExpenseContribution(memberId: 'A', memberName: 'An', paidAmount: 1200000),
        MemberExpenseContribution(memberId: 'B', memberName: 'Bình', paidAmount: 400000),
        MemberExpenseContribution(memberId: 'C', memberName: 'Khánh', paidAmount: 0),
        MemberExpenseContribution(memberId: 'D', memberName: 'Dũng', paidAmount: 0),
      ]);
      expect(settlements.length, 2);
      expect(settlements.every((s) => s.fromId != 'B' && s.toId != 'B'), isTrue);
      expect(settlements.every((s) => s.toId == 'A' && s.amount == 400000), isTrue);

      await tester.tap(find.byKey(const Key('budget_add_expense_button')));
      await tester.pumpAndSettle();

      // TC-M4-02: Enter expression 150000 + 45000 * 2 and evaluate '=' -> 240000
      await tester.enterText(
        find.byKey(const Key('cashew_amount_field')),
        '150000 + 45000 * 2',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cashew_key_=')));
      await tester.pumpAndSettle();

      final amountCtrlText =
          tester.widget<TextField>(find.byKey(const Key('cashew_amount_field'))).controller?.text;
      expect(amountCtrlText, '240000');

      // TC-M4-02 boundary: division by zero and repeated operator '++'
      expect(CashewCalculator.evaluate('1000 / 0'), isNull);
      expect(CashewCalculator.evaluate('100 ++ 50'), 150);

      // TC-NF-01: Assert no RenderFlex overflow or framework errors across visited screens
      final overflows = runtimeErrors.where((e) => e.contains('RenderFlex overflowed')).toList();
      expect(
        overflows,
        isEmpty,
        reason: 'Found UI RenderFlex overflows: $overflows',
      );
      expect(runtimeErrors, isEmpty, reason: 'Unexpected Flutter errors: $runtimeErrors');
    });
  });
}
