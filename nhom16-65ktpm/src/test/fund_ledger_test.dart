import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';
import 'package:gooddeeds_fund/data/models/fund_transaction_model.dart';
import 'package:gooddeeds_fund/data/models/proof_model.dart';
import 'package:gooddeeds_fund/data/repositories/challenge_repository.dart';
import 'package:gooddeeds_fund/data/repositories/fund_repository.dart';
import 'package:gooddeeds_fund/data/repositories/fund_transaction_repository.dart';
import 'package:gooddeeds_fund/data/repositories/proof_repository.dart';
import 'package:gooddeeds_fund/features/fund_ledger/disbursement_form_screen.dart';
import 'package:gooddeeds_fund/features/fund_ledger/fund_ledger_screen.dart';
import 'package:gooddeeds_fund/features/fund_ledger/widgets/transaction_detail_sheet.dart';

// Mock Transaction Repository cho Unit/Widget Test độc lập
class MockTransactionRepositoryForTest implements IFundTransactionRepository {
  final List<FundTransactionModel> _txs = [
    FundTransactionModel(
      id: 'tx_test_01',
      type: TransactionType.thu,
      amount: 1500000,
      title: 'Tài trợ mở quỹ thiện nguyện',
      category: 'Tài trợ',
      recipientOrSponsor: 'Cựu sinh viên KTPM',
      createdAt: DateTime(2026, 11, 20, 10, 0),
    ),
    FundTransactionModel(
      id: 'tx_test_02',
      type: TransactionType.chi,
      amount: 300000,
      title: 'Mua sách vở tặng học sinh nghèo',
      category: 'Hỗ trợ giáo dục & Trường học',
      recipientOrSponsor: 'Điểm trường Nậm Cần',
      createdAt: DateTime(2026, 11, 21, 14, 30),
    ),
  ];

  @override
  Future<List<FundTransactionModel>> getTransactions() async => List.from(_txs);

  @override
  Future<int> recordTransaction(FundTransactionModel tx) async {
    _txs.add(tx);
    return 1;
  }

  @override
  Future<double> getTotalIncome() async => 1500000.0;

  @override
  Future<double> getTotalExpense() async => 300000.0;

  @override
  Future<double> getBalance() async => 1200000.0;

  @override
  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return _txs.where((t) {
      if (type != null && t.type != type) return false;
      if (category != null && category != 'Tất cả' && t.category != category) {
        return false;
      }
      return true;
    }).toList();
  }
}

class DummyChallengeRepo implements IChallengeRepository {
  @override
  Future<List<ChallengeModel>> getChallenges() async => [];
  @override
  Future<ChallengeModel?> getChallengeById(String id) async => null;
  @override
  Future<int> addChallenge(ChallengeModel challenge) async => 1;
}

class DummyProofRepo implements IProofRepository {
  @override
  Future<List<ProofModel>> getProofs() async => [];
  @override
  Future<List<ProofModel>> getPendingProofs() async => [];
  @override
  Future<int> submitProof(ProofModel proof) async => 1;
  @override
  Future<bool> approveProof(String proofId, {String? feedback}) async => true;
  @override
  Future<bool> rejectProof(String proofId, {required String reason}) async =>
      true;
}

void main() {
  late FundRepository mockFundRepository;

  setUp(() {
    mockFundRepository = FundRepository(
      challengeRepository: DummyChallengeRepo(),
      proofRepository: DummyProofRepo(),
      transactionRepository: MockTransactionRepositoryForTest(),
    );
  });

  group('FundLedgerScreen & DisbursementFormScreen Unit/Widget Tests', () {
    testWidgets(
        '1. FundLedgerScreen render đầy đủ thông tin số dư, bộ lọc và danh sách giao dịch',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FundLedgerScreen(repository: mockFundRepository),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình và thẻ số dư
      expect(find.text('Sổ Quỹ Thu - Chi'), findsOneWidget);
      expect(find.text('Tổng Số Dư Quỹ Hiện Có'), findsOneWidget);
      expect(find.text('Lịch sử biến động dòng tiền'), findsOneWidget);
      expect(find.text('2 giao dịch'), findsOneWidget);

      // Kiểm tra hiển thị 2 giao dịch mẫu
      expect(find.text('Tài trợ mở quỹ thiện nguyện'), findsOneWidget);
      expect(find.text('Mua sách vở tặng học sinh nghèo'), findsOneWidget);

      // Kiểm tra lọc theo Khoản Chi (-)
      await tester.tap(find.text('Khoản Chi (-)'));
      await tester.pumpAndSettle();
      expect(find.text('1 giao dịch'), findsOneWidget);
      expect(find.text('Mua sách vở tặng học sinh nghèo'), findsOneWidget);
      expect(find.text('Tài trợ mở quỹ thiện nguyện'), findsNothing);

      // Kiểm tra nút Lập Phiếu Chi
      expect(find.text('Lập Phiếu Chi'), findsOneWidget);
    });

    testWidgets(
        '2. DisbursementFormScreen render đúng form và kiểm tra validation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DisbursementFormScreen(currentBalance: 1200000),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra hiển thị tiêu đề và số dư khả dụng
      expect(find.text('Lập Phiếu Chi Giải Ngân'), findsOneWidget);
      expect(find.textContaining('Số dư quỹ khả dụng hiện tại'), findsOneWidget);

      // Cuộn tới nút Xác nhận và bấm khi form rỗng
      final submitButton = find.text('Xác Nhận Lập Phiếu Chi');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Phải báo lỗi mục đích chi và số tiền
      expect(find.text('Vui lòng nhập mục đích chi'), findsOneWidget);
      expect(find.text('Vui lòng nhập số tiền chi'), findsOneWidget);
    });

    testWidgets('3. TransactionDetailSheet hiển thị đúng chi tiết giao dịch',
        (tester) async {
      final tx = FundTransactionModel(
        id: 'tx_detail_01',
        type: TransactionType.thu,
        amount: 50000,
        title: 'Hoàn thành thử thách dậy sớm',
        category: 'Kỷ luật',
        recipientOrSponsor: 'Nguyễn Văn A',
        note: 'Minh chứng đã được admin phê duyệt',
        createdAt: DateTime(2026, 11, 24, 6, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDetailSheet(transaction: tx),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra các trường hiển thị
      expect(find.text('Hoàn thành thử thách dậy sớm'), findsOneWidget);
      expect(find.text('Kỷ luật'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Minh chứng đã được admin phê duyệt'), findsOneWidget);
      expect(find.text('KHOẢN THU (TÀI TRỢ / CỘNG QUỸ)'), findsOneWidget);
      expect(find.text(tx.formattedAmount), findsOneWidget);
    });
  });
}
