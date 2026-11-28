import 'dart:io';

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
import 'package:gooddeeds_fund/features/fund_ledger/services/disbursement_receipt_storage_service.dart';
import 'package:gooddeeds_fund/features/fund_ledger/widgets/receipt_attachment_card.dart';

class _InMemoryTransactionRepo implements IFundTransactionRepository {
  final List<FundTransactionModel> recorded = [];

  @override
  Future<List<FundTransactionModel>> getTransactions() async =>
      List.unmodifiable(recorded);

  @override
  Future<int> recordTransaction(FundTransactionModel tx) async {
    recorded.add(tx);
    return 1;
  }

  @override
  Future<double> getTotalIncome() async => 2000000.0;

  @override
  Future<double> getTotalExpense() async {
    double sum = 0.0;
    for (final tx in recorded) {
      if (tx.isExpense) sum += tx.amount;
    }
    return sum;
  }

  @override
  Future<double> getBalance() async =>
      (await getTotalIncome()) - (await getTotalExpense());

  @override
  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async =>
      recorded;
}

class _StubChallengeRepo implements IChallengeRepository {
  @override
  Future<List<ChallengeModel>> getChallenges() async => [];
  @override
  Future<ChallengeModel?> getChallengeById(String id) async => null;
  @override
  Future<int> addChallenge(ChallengeModel challenge) async => 1;
}

class _StubProofRepo implements IProofRepository {
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
  group('DisbursementReceiptStorageService Unit Tests', () {
    const storageService = DisbursementReceiptStorageService();

    test('1. formatBytes định dạng chính xác 0 KB, KB và MB', () {
      expect(DisbursementReceiptStorageService.formatBytes(0), '0 KB');
      expect(DisbursementReceiptStorageService.formatBytes(1536), '1.5 KB');
      expect(
        DisbursementReceiptStorageService.formatBytes(2 * 1024 * 1024),
        '2.00 MB',
      );
    });

    test('2. saveReceiptImage sao chép tệp thật và deleteReceiptImage xoá sạch',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('receipt_test_');
      final sampleFile = File('${tempDir.path}/sample_transfer.png');
      await sampleFile.writeAsBytes(List<int>.filled(2048, 42));

      try {
        final stored = await storageService.saveReceiptImage(
          sampleFile.path,
          disbursementRef: 'VCB-001',
        );

        expect(stored.fileName.startsWith('receipt_VCB-001_'), isTrue);
        expect(stored.fileName.endsWith('.png'), isTrue);
        expect(stored.fileSizeBytes, 2048);
        expect(stored.formattedSize, '2.0 KB');
        expect(await File(stored.savedPath).exists(), isTrue);

        final deleted = await storageService.deleteReceiptImage(stored.savedPath);
        expect(deleted, isTrue);
        expect(await File(stored.savedPath).exists(), isFalse);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('ReceiptAttachmentCard Widget Tests', () {
    testWidgets('3. Hiển thị trạng thái trống và trạng thái đã đính kèm sao kê',
        (tester) async {
      // Trạng thái trống
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptAttachmentCard(
              receiptImage: null,
              isSaving: false,
              onPickFromGallery: () {},
              onPickFromCamera: () {},
              onRemoveImage: () {},
            ),
          ),
        ),
      );
      expect(find.text('Chưa có ảnh sao kê / uỷ nhiệm chi'), findsOneWidget);
      expect(find.text('Thư viện'), findsOneWidget);
      expect(find.text('Chụp ảnh'), findsOneWidget);

      // Trạng thái đã đính kèm
      final receipt = StoredReceiptImage(
        savedPath: '/tmp/receipt_demo.jpg',
        fileName: 'receipt_FT123_demo.jpg',
        fileSizeBytes: 51200,
        savedAt: DateTime(2026, 11, 26, 14, 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptAttachmentCard(
              receiptImage: receipt,
              isSaving: false,
              onPickFromGallery: () {},
              onPickFromCamera: () {},
              onRemoveImage: () {},
            ),
          ),
        ),
      );
      expect(find.text('Đã đính kèm sao kê'), findsOneWidget);
      expect(find.text('receipt_FT123_demo.jpg'), findsOneWidget);
      expect(find.text('50.0 KB'), findsOneWidget);
    });
  });

  group('DisbursementFormScreen Integration Widget Tests', () {
    testWidgets(
        '4. Cảnh báo vượt hạn mức quỹ và chặn lưu khi số tiền > số dư hiện có',
        (tester) async {
      final txRepo = _InMemoryTransactionRepo();
      final fundRepo = FundRepository(
        challengeRepository: _StubChallengeRepo(),
        proofRepository: _StubProofRepo(),
        transactionRepository: txRepo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DisbursementFormScreen(
            currentBalance: 500000,
            repository: fundRepo,
          ),
        ),
      );

      // Nhập mục đích chi và số tiền vượt số dư (800.000 > 500.000)
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mua áo ấm tặng trẻ em vùng cao');
      await tester.enterText(fields.at(1), '800000');
      await tester.enterText(fields.at(2), 'Trường Mầm non Mường Lát');
      await tester.pumpAndSettle();

      // Thẻ số dư hiển thị cảnh báo vượt hạn mức realtime
      expect(find.text('Vượt hạn mức quỹ:'), findsOneWidget);

      // Bấm xác nhận -> phải báo lỗi validation và không ghi giao dịch
      final submitButton = find.text('Xác Nhận Lập Phiếu Chi');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Vượt quá số dư quỹ hiện có'), findsOneWidget);
      expect(txRepo.recorded, isEmpty);
    });

    testWidgets(
        '5. Luồng lập phiếu chi hợp lệ -> đối soát Dialog -> ghi nhận TransactionType.chi',
        (tester) async {
      final txRepo = _InMemoryTransactionRepo();
      final fundRepo = FundRepository(
        challengeRepository: _StubChallengeRepo(),
        proofRepository: _StubProofRepo(),
        transactionRepository: txRepo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DisbursementFormScreen(
            currentBalance: 1500000,
            repository: fundRepo,
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Tặng 30 suất học bổng vượt khó');
      await tester.enterText(fields.at(1), '500000');
      await tester.enterText(fields.at(2), 'Trường THCS Nậm Cần');
      await tester.enterText(fields.at(3), 'FT26330998877');
      await tester.enterText(fields.at(4), 'Chuyển khoản trực tiếp cho trường');
      await tester.pumpAndSettle();

      // Hiển thị số dư dự kiến sau giải ngân
      expect(find.text('Số dư dự kiến sau giải ngân:'), findsOneWidget);

      // Bấm Xác Nhận Lập Phiếu Chi -> Mở DisbursementConfirmDialog
      final submitButton = find.text('Xác Nhận Lập Phiếu Chi');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận giải ngân'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('FT26330998877'),
        ),
        findsOneWidget,
      );

      // Bấm Đồng ý giải ngân
      await tester.tap(find.text('Đồng ý giải ngân'));
      await tester.pumpAndSettle();

      // Xác minh giao dịch đã được lưu đúng vào Repository
      expect(txRepo.recorded.length, 1);
      final savedTx = txRepo.recorded.first;
      expect(savedTx.type, TransactionType.chi);
      expect(savedTx.amount, 500000.0);
      expect(savedTx.title, 'Tặng 30 suất học bổng vượt khó');
      expect(savedTx.recipientOrSponsor, 'Trường THCS Nậm Cần');
      expect(savedTx.note, contains('Mã tham chiếu CK: FT26330998877'));
      expect(savedTx.note, contains('Chuyển khoản trực tiếp cho trường'));
    });
  });
}
