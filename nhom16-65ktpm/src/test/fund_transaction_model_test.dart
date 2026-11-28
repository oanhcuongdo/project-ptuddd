import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/fund_transaction_model.dart';

void main() {
  group('FundTransactionModel Unit Tests', () {
    final sampleDate = DateTime(2026, 11, 20, 14, 30);

    // Giao dịch THU mẫu (Tài trợ thử thách)
    final sampleIncomeTx = FundTransactionModel(
      id: 'tx_income_01',
      proofId: 'proof_test_01',
      type: TransactionType.thu,
      amount: 20000.0,
      title: 'Tài trợ: Dậy sớm trước 6:00 sáng',
      category: 'Kỷ luật',
      proofImagePath: '/data/user/0/com.example.gooddeeds/proof.jpg',
      note: 'Minh chứng của Lê Anh Tuấn được duyệt thành công',
      recipientOrSponsor: 'Quỹ Doanh nghiệp ABC',
      createdAt: sampleDate,
    );

    // Giao dịch CHI mẫu (Giải ngân từ thiện)
    final sampleExpenseTx = FundTransactionModel(
      id: 'tx_expense_01',
      proofId: null,
      type: TransactionType.chi,
      amount: 500000.0,
      title: 'Mua sách vở tặng học sinh nghèo',
      category: 'Giáo dục',
      proofImagePath: '/data/user/0/com.example.gooddeeds/receipt.jpg',
      note: 'Hỗ trợ 20 bộ sách giáo khoa cho điểm trường vùng cao',
      recipientOrSponsor: 'Trường Tiểu học Chiềng Sơ',
      createdAt: sampleDate,
    );

    test('Kiểm tra khởi tạo và các thuộc tính cơ bản', () {
      expect(sampleIncomeTx.id, 'tx_income_01');
      expect(sampleIncomeTx.proofId, 'proof_test_01');
      expect(sampleIncomeTx.amount, 20000.0);
      expect(sampleIncomeTx.category, 'Kỷ luật');
      expect(sampleIncomeTx.recipientOrSponsor, 'Quỹ Doanh nghiệp ABC');

      expect(sampleExpenseTx.id, 'tx_expense_01');
      expect(sampleExpenseTx.proofId, isNull);
      expect(sampleExpenseTx.amount, 500000.0);
      expect(sampleExpenseTx.recipientOrSponsor, 'Trường Tiểu học Chiềng Sơ');
    });

    test('Kiểm tra phân loại giao dịch Thu / Chi (isIncome, isExpense, typeDisplay)', () {
      // 1. Giao dịch Thu
      expect(sampleIncomeTx.isIncome, isTrue);
      expect(sampleIncomeTx.isExpense, isFalse);
      expect(sampleIncomeTx.typeDisplay, 'Thu');

      // 2. Giao dịch Chi
      expect(sampleExpenseTx.isIncome, isFalse);
      expect(sampleExpenseTx.isExpense, isTrue);
      expect(sampleExpenseTx.typeDisplay, 'Chi');
    });

    test('Kiểm tra định dạng hiển thị số tiền có tiền tố + / - và định dạng ngày giờ', () {
      // Thu phải có tiền tố '+'
      expect(sampleIncomeTx.formattedAmount, startsWith('+'));
      expect(sampleIncomeTx.formattedAmount, contains('20.000'));
      expect(sampleIncomeTx.formattedAmount, contains('đ'));

      // Chi phải có tiền tố '-'
      expect(sampleExpenseTx.formattedAmount, startsWith('-'));
      expect(sampleExpenseTx.formattedAmount, contains('500.000'));
      expect(sampleExpenseTx.formattedAmount, contains('đ'));

      // Ngày giờ định dạng: HH:mm - dd/MM/yyyy
      expect(sampleIncomeTx.formattedCreatedAt, '14:30 - 20/11/2026');
    });

    test('Kiểm tra ánh xạ SQLite: toMap() và fromMap()', () {
      final map = sampleIncomeTx.toMap();

      expect(map['id'], 'tx_income_01');
      expect(map['proofId'], 'proof_test_01');
      expect(map['type'], 'thu');
      expect(map['amount'], 20000.0);
      expect(map['createdAt'], sampleDate.toIso8601String());

      final fromMapModel = FundTransactionModel.fromMap(map);
      expect(fromMapModel, equals(sampleIncomeTx));

      final expenseMap = sampleExpenseTx.toMap();
      expect(expenseMap['type'], 'chi');
      final fromExpenseMapModel = FundTransactionModel.fromMap(expenseMap);
      expect(fromExpenseMapModel, equals(sampleExpenseTx));
    });

    test('Kiểm tra JSON serialization: toJson() và fromJson()', () {
      final json = sampleIncomeTx.toJson();
      expect(json['id'], 'tx_income_01');
      expect(json['type'], 'thu');

      final fromJsonModel = FundTransactionModel.fromJson(json);
      expect(fromJsonModel, equals(sampleIncomeTx));

      final jsonString = sampleIncomeTx.toJsonString();
      final fromStringModel = FundTransactionModel.fromJsonString(jsonString);
      expect(fromStringModel, equals(sampleIncomeTx));
    });

    test('Kiểm tra copyWith()', () {
      final updated = sampleIncomeTx.copyWith(
        amount: 35000.0,
        note: 'Cập nhật ghi chú mới',
      );

      expect(updated.id, sampleIncomeTx.id);
      expect(updated.amount, 35000.0);
      expect(updated.note, 'Cập nhật ghi chú mới');
      expect(updated.type, sampleIncomeTx.type);
      expect(updated.category, sampleIncomeTx.category);
    });

    test('Kiểm tra toán tử bằng nhau == và hashCode', () {
      final duplicate = FundTransactionModel.fromMap(sampleIncomeTx.toMap());
      expect(duplicate, equals(sampleIncomeTx));
      expect(duplicate.hashCode, equals(sampleIncomeTx.hashCode));
    });

    test('Kiểm tra phân biệt hai giao dịch khác nhau', () {
      final differentTx = sampleIncomeTx.copyWith(id: 'tx_different');
      expect(differentTx, isNot(equals(sampleIncomeTx)));
    });
  });
}

