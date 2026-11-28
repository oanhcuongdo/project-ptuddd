import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy/core/theme/app_theme.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/models/trip_expense.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/presentation/budget_screen.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/presentation/widgets/cashew_amount_keypad.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/repository/budget_repository.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/utils/cashew_calculator.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/utils/debt_simplifier.dart';
import 'package:travel_buddy/features/budget_and_expense_cashew/utils/receipt_amount_parser.dart';

void main() {
  testWidgets('budget screen shows six envelopes and comparison chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HŨ NGÂN SÁCH CASHEW'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('Cashew keypad exposes arithmetic and clear controls', (
    tester,
  ) async {
    String? pressedKey;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashewAmountKeypad(onKeyPressed: (value) => pressedKey = value),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('cashew_key_000')));
    expect(pressedKey, '000');
    expect(find.byKey(const Key('cashew_key_⌫')), findsOneWidget);
    expect(find.byKey(const Key('cashew_key_C')), findsOneWidget);
    expect(find.byKey(const Key('cashew_key_+')), findsOneWidget);
    expect(find.byKey(const Key('cashew_key_−')), findsOneWidget);
  });

  group('InMemoryBudgetRepository', () {
    test('seeds six envelopes and updates spent amount atomically', () async {
      final repository = InMemoryBudgetRepository();
      addTearDown(repository.dispose);
      const tripId = 'budget-test-trip';
      final initial = await repository
          .watchEnvelopes(
            tripId,
            targetBudget: 100000,
            initializeDefaults: true,
          )
          .first;
      expect(initial, hasLength(6));
      expect(
        initial.fold<int>(0, (sum, envelope) => sum + envelope.allocatedAmount),
        100000,
      );

      await repository.addExpense(
        tripId: tripId,
        expense: TripExpense(
          id: '',
          title: 'Coffee',
          amount: 1500,
          envelopeId: 'food',
          category: 'food',
          paymentSource: 'personal_advance',
          paidBy: 'member-a',
          paidByName: 'An',
          splitType: 'equal',
          splitBetween: const ['member-a'],
          splitDetails: const {'member-a': 1500},
          isOcrScanned: false,
          spentAt: DateTime(2026),
          createdBy: 'member-a',
          createdAt: DateTime(2026),
        ),
      );

      final updated = await repository
          .watchEnvelopes(
            tripId,
            targetBudget: 100000,
            initializeDefaults: true,
          )
          .first;
      expect(
        updated.singleWhere((envelope) => envelope.id == 'food').spentAmount,
        1500,
      );
    });
  });

  group('CashewCalculator keypad', () {
    test('evaluates positive and negative entries in order', () {
      expect(CashewCalculator.evaluate('120000 + 30000 − 5000'), 145000);
    });

    test('appends digits and thousand shortcut then deletes safely', () {
      final expression = CashewCalculator.appendDigits(
        CashewCalculator.appendDigits('12', '000'),
        '500',
      );
      expect(expression, '12000500');
      expect(CashewCalculator.backspace('12000500'), '1200050');
      expect(CashewCalculator.backspace('120 + '), '120');
    });

    test('returns null for incomplete or invalid calculations', () {
      expect(CashewCalculator.evaluate('100 +'), isNull);
      expect(CashewCalculator.evaluate('100 / 0'), isNull);
    });
  });

  group('DebtSimplifier', () {
    test('settles equal-split expenses with minimum transfers', () {
      final settlements = DebtSimplifier.simplifyEqualSplit([
        const MemberExpenseContribution(
          memberId: 'a',
          memberName: 'An',
          paidAmount: 100,
        ),
        const MemberExpenseContribution(
          memberId: 'b',
          memberName: 'Bình',
          paidAmount: 200,
        ),
        const MemberExpenseContribution(
          memberId: 'c',
          memberName: 'Chi',
          paidAmount: 0,
        ),
      ]);

      expect(settlements, hasLength(1));
      expect(settlements.single.fromId, 'c');
      expect(settlements.single.toId, 'b');
      expect(settlements.single.amount, 100);
    });

    test('balances multiple creditors and debtors without losing money', () {
      final settlements = DebtSimplifier.simplifyNetBalances(
        balances: {'a': 100, 'b': 50, 'c': -90, 'd': -60},
        names: const {'a': 'An', 'b': 'Bình', 'c': 'Chi', 'd': 'Dung'},
      );

      expect(settlements.length, lessThanOrEqualTo(3));
      expect(
        settlements.fold<int>(0, (sum, settlement) => sum + settlement.amount),
        150,
      );
      expect(settlements.every((settlement) => settlement.amount > 0), isTrue);
    });

    test('returns no transactions for a balanced group', () {
      expect(
        DebtSimplifier.simplifyNetBalances(
          balances: const {'a': 0, 'b': 0},
          names: const {'a': 'An', 'b': 'Bình'},
        ),
        isEmpty,
      );
    });

    test('searches for a lower transfer count than the greedy pairing', () {
      final settlements = DebtSimplifier.simplifyNetBalances(
        balances: const {'a': 6, 'b': 4, 'c': 4, 'd': 2, 'e': -8, 'f': -8},
        names: const {},
      );

      expect(settlements, hasLength(4));
      expect(
        settlements.fold<int>(0, (sum, settlement) => sum + settlement.amount),
        16,
      );
    });
  });

  group('ReceiptAmountParser', () {
    test('prefers the labeled total over larger line item amounts', () {
      expect(
        ReceiptAmountParser.extractAmount(
          'Sản phẩm 1.500.000\nTổng cộng 850.000\nThanh toán 850.000',
        ),
        850000,
      );
    });

    test('falls back to the largest amount when total label is missing', () {
      expect(
        ReceiptAmountParser.extractAmount('Món ăn 45.000\nTiền mặt 200.000'),
        200000,
      );
    });
  });
}
