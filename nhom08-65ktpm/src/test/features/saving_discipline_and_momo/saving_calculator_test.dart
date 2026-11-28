import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/models/saving_plan.dart';
import 'package:travel_buddy/features/saving_discipline_and_momo/utils/saving_calculator.dart';

void main() {
  group('SavingCalculator Tests', () {
    test('Throws ArgumentError when targetAmount is <= 0', () {
      expect(
        () => SavingCalculator.calculateInstallments(
          targetAmount: 0,
          startDate: DateTime(2026, 11, 1),
          deadlineDate: DateTime(2026, 11, 20),
        ),
        throwsArgumentError,
      );

      expect(
        () => SavingCalculator.calculateInstallments(
          targetAmount: -50000,
          startDate: DateTime(2026, 11, 1),
          deadlineDate: DateTime(2026, 11, 20),
        ),
        throwsArgumentError,
      );
    });

    test('Throws ArgumentError when deadline is before or same day as startDate', () {
      expect(
        () => SavingCalculator.calculateInstallments(
          targetAmount: 1000000,
          startDate: DateTime(2026, 11, 10),
          deadlineDate: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );

      expect(
        () => SavingCalculator.calculateInstallments(
          targetAmount: 1000000,
          startDate: DateTime(2026, 11, 15),
          deadlineDate: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
    });

    test('Automatically switches to daily frequency when days < 7', () {
      final startDate = DateTime(2026, 11, 1);
      final deadlineDate = DateTime(2026, 11, 5); // 4 days

      final result = SavingCalculator.calculateInstallments(
        targetAmount: 2000000,
        startDate: startDate,
        deadlineDate: deadlineDate,
        preferredFrequency: SavingFrequency.weekly,
      );

      expect(result.frequency, SavingFrequency.daily);
      expect(result.totalInstallments, 4);
      expect(result.schedule.length, 4);

      // Verify sum of installments equals target amount
      final sum = result.schedule.fold<double>(0, (acc, item) => acc + item.amount);
      expect(sum, 2000000.0);
    });

    test('Automatically switches monthly to weekly when days between 7 and 29', () {
      final startDate = DateTime(2026, 11, 1);
      final deadlineDate = DateTime(2026, 11, 22); // 21 days (3 weeks)

      final result = SavingCalculator.calculateInstallments(
        targetAmount: 3000000,
        startDate: startDate,
        deadlineDate: deadlineDate,
        preferredFrequency: SavingFrequency.monthly,
      );

      expect(result.frequency, SavingFrequency.weekly);
      expect(result.totalInstallments, 3);
      expect(result.schedule.length, 3);

      final sum = result.schedule.fold<double>(0, (acc, item) => acc + item.amount);
      expect(sum, 3000000.0);
    });

    test('Calculates weekly installments with remainder adjustment on final installment', () {
      final startDate = DateTime(2026, 11, 1);
      final deadlineDate = DateTime(2026, 11, 29); // 28 days = 4 weeks
      const targetAmount = 1005500.0; // Needs rounding & adjustment

      final result = SavingCalculator.calculateInstallments(
        targetAmount: targetAmount,
        startDate: startDate,
        deadlineDate: deadlineDate,
        preferredFrequency: SavingFrequency.weekly,
      );

      expect(result.totalInstallments, 4);
      expect(result.schedule.length, 4);

      // 1005500 / 4 = 251375 -> rounded to nearest 1,000 = 251,000
      expect(result.installmentAmount, 251000.0);

      // Final installment should absorb remainder: 1005500 - (251000 * 3) = 1005500 - 753000 = 252500
      expect(result.finalInstallmentAmount, 252500.0);
      expect(result.schedule.last.amount, 252500.0);
      expect(result.schedule.last.isAdjusted, true);

      final sum = result.schedule.fold<double>(0, (acc, item) => acc + item.amount);
      expect(sum, targetAmount);
    });

    test('Single interval produces exact single installment', () {
      final startDate = DateTime(2026, 11, 1);
      final deadlineDate = DateTime(2026, 11, 2); // 1 day

      final result = SavingCalculator.calculateInstallments(
        targetAmount: 500000,
        startDate: startDate,
        deadlineDate: deadlineDate,
        preferredFrequency: SavingFrequency.daily,
      );

      expect(result.totalInstallments, 1);
      expect(result.schedule.length, 1);
      expect(result.schedule.first.amount, 500000.0);
      expect(result.finalInstallmentAmount, 500000.0);
    });

    test('Calculates installments on remaining amount when previous plan is partially paid', () {
      final result = SavingCalculator.calculateInstallments(
        targetAmount: 2000000,
        alreadyPaidAmount: 1400000,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 11), // 10 days
        preferredFrequency: SavingFrequency.daily,
      );

      expect(result.totalAmount, 600000);
      expect(result.totalInstallments, 10);
      expect(result.installmentAmount, 60000);
      final sum = result.schedule.fold<double>(0, (acc, item) => acc + item.amount);
      expect(sum, 600000);
    });

    test('Returns 0 installments when previous plan is already fully deposited', () {
      final result = SavingCalculator.calculateInstallments(
        targetAmount: 2000000,
        alreadyPaidAmount: 2000000,
        startDate: DateTime(2026, 11, 1),
        deadlineDate: DateTime(2026, 11, 11),
        preferredFrequency: SavingFrequency.daily,
      );

      expect(result.totalAmount, 0);
      expect(result.totalInstallments, 0);
      expect(result.installmentAmount, 0);
      expect(result.schedule, isEmpty);
    });
  });
}
