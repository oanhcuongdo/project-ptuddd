import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/datasources/database_helper.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';
import 'package:gooddeeds_fund/data/models/fund_transaction_model.dart';
import 'package:gooddeeds_fund/data/models/proof_model.dart';
import 'package:gooddeeds_fund/data/repositories/fund_repository.dart';
import 'package:gooddeeds_fund/data/services/proof_approval_credit_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openInMemoryTestDatabase() async {
  return await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${DatabaseHelper.tableChallenges} (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            rewardAmount REAL NOT NULL,
            category TEXT NOT NULL,
            icon TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE ${DatabaseHelper.tableProofs} (
            id TEXT PRIMARY KEY,
            challengeId TEXT NOT NULL,
            challengeTitle TEXT NOT NULL,
            memberName TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            ocrExtractedText TEXT,
            detectedTime TEXT,
            submittedAt TEXT NOT NULL,
            status TEXT NOT NULL,
            rewardAmount REAL NOT NULL,
            note TEXT,
            adminFeedback TEXT,
            FOREIGN KEY (challengeId) REFERENCES ${DatabaseHelper.tableChallenges} (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE ${DatabaseHelper.tableFundTransactions} (
            id TEXT PRIMARY KEY,
            proofId TEXT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            proofImagePath TEXT,
            note TEXT,
            recipientOrSponsor TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (proofId) REFERENCES ${DatabaseHelper.tableProofs} (id)
          )
        ''');
      },
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ProofApprovalCreditHelper Unit Tests', () {
    test('1. canCreditFund chỉ trả về true khi minh chứng Pending và tiền thưởng > 0', () {
      final validProof = ProofModel(
        id: 'p_valid',
        challengeId: 'ch_1',
        challengeTitle: 'Dậy sớm 5h30',
        memberName: 'Lê Anh Tuấn',
        imagePath: '/images/p_valid.jpg',
        ocrExtractedText: '05:35 AM',
        submittedAt: DateTime(2026, 11, 27, 5, 35),
        status: ProofStatus.pending,
        rewardAmount: 20000,
      );

      final approvedProof = validProof.copyWith(status: ProofStatus.approved);
      final zeroRewardProof = validProof.copyWith(rewardAmount: 0);

      expect(ProofApprovalCreditHelper.canCreditFund(validProof), isTrue);
      expect(ProofApprovalCreditHelper.canCreditFund(approvedProof), isFalse);
      expect(ProofApprovalCreditHelper.canCreditFund(zeroRewardProof), isFalse);
    });

    test('2. buildIncomeTransaction lấy đúng category thử thách, đính kèm ảnh và phản hồi', () {
      const challenge = ChallengeModel(
        id: 'ch_1',
        title: 'Dậy sớm trước 6h sáng đọc sách 30 phút',
        description: 'Chụp ảnh đồng hồ trước 6h00.',
        rewardAmount: 20000,
        category: 'Kỷ luật',
        icon: 'alarm',
      );
      final proof = ProofModel(
        id: 'p_001',
        challengeId: challenge.id,
        challengeTitle: challenge.title,
        memberName: 'Nguyễn Văn A',
        imagePath: '/storage/proof_001.jpg',
        ocrExtractedText: '05:40 AM',
        submittedAt: DateTime(2026, 11, 27, 5, 40),
        status: ProofStatus.pending,
        rewardAmount: 20000,
      );

      final tx = ProofApprovalCreditHelper.buildIncomeTransaction(
        proof: proof,
        challenge: challenge,
        adminFeedback: 'Ảnh rõ nét, đúng giờ quy định',
        approvedAt: DateTime(2026, 11, 27, 8, 0),
      );

      expect(tx.type, TransactionType.thu);
      expect(tx.proofId, 'p_001');
      expect(tx.amount, 20000);
      expect(tx.category, 'Kỷ luật');
      expect(tx.proofImagePath, '/storage/proof_001.jpg');
      expect(tx.note, contains('Nguyễn Văn A'));
      expect(tx.note, contains('Ảnh rõ nét, đúng giờ quy định'));

      expect(
        () => ProofApprovalCreditHelper.buildIncomeTransaction(
          proof: proof.copyWith(rewardAmount: 0),
          challenge: challenge,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SQLite Integration Tests - Tự động cộng tiền Thu khi duyệt Approved', () {
    late Database testDb;
    late FundRepository repo;

    const sampleChallenge = ChallengeModel(
      id: 'ch_early',
      title: 'Dậy sớm trước 6h sáng đọc sách',
      description: 'Dậy sớm và đọc sách 30 phút.',
      rewardAmount: 25000,
      category: 'Kỷ luật',
      icon: 'alarm',
    );

    setUp(() async {
      testDb = await _openInMemoryTestDatabase();
      await DatabaseHelper.instance.setDatabaseForTesting(testDb);
      repo = FundRepository(
        challengeRepository: ChallengeRepositoryImpl(db: DatabaseHelper.instance),
        proofRepository: ProofRepositoryImpl(db: DatabaseHelper.instance),
        transactionRepository:
            FundTransactionRepositoryImpl(db: DatabaseHelper.instance),
      );

      await repo.addChallenge(sampleChallenge);
      await repo.recordTransaction(
        FundTransactionModel(
          id: 'tx_seed',
          type: TransactionType.thu,
          amount: 1000000,
          title: 'Tài trợ mở quỹ',
          category: 'Tài trợ mở quỹ',
          recipientOrSponsor: 'Cựu sinh viên KTPM',
          createdAt: DateTime(2026, 11, 20),
        ),
      );
    });

    tearDown(() async {
      await DatabaseHelper.instance.setDatabaseForTesting(null);
      await testDb.close();
    });

    test('3. Duyệt minh chứng Approved tự động cộng đúng tiền Thu, đồng bộ category và số dư', () async {
      final proof = ProofModel(
        id: 'proof_approve_01',
        challengeId: sampleChallenge.id,
        challengeTitle: sampleChallenge.title,
        memberName: 'Lê Anh Tuấn',
        imagePath: '/local/proof_approve_01.jpg',
        ocrExtractedText: '05:30 AM',
        submittedAt: DateTime(2026, 11, 27, 5, 30),
        status: ProofStatus.pending,
        rewardAmount: 25000,
      );
      await repo.submitProof(proof);

      final balanceBefore = await repo.getBalance();
      final versionBefore = repo.fundUpdateVersion.value;

      final result = await repo.approveProofAndCreditFund(
        proof.id,
        feedback: 'Đạt chuẩn 5h30 sáng',
      );

      expect(result.approved, isTrue);
      expect(result.status, ApprovalCreditStatus.credited);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.type, TransactionType.thu);
      expect(result.transaction!.proofId, proof.id);
      expect(result.transaction!.amount, 25000);
      expect(result.transaction!.category, 'Kỷ luật');
      expect(result.transaction!.proofImagePath, '/local/proof_approve_01.jpg');
      expect(result.newBalance, balanceBefore + 25000);

      // Kiểm tra trạng thái lưu trong SQLite & sự kiện đồng bộ số dư
      final allProofs = await repo.getProofs();
      final updatedProof = allProofs.firstWhere((p) => p.id == proof.id);
      expect(updatedProof.status, ProofStatus.approved);
      expect(updatedProof.adminFeedback, 'Đạt chuẩn 5h30 sáng');

      expect(await repo.getBalance(), 1025000.0);
      expect(repo.fundUpdateVersion.value, versionBefore + 1);
    });

    test('4. Duyệt lại lần 2 cùng một minh chứng bị chặn và không cộng trùng tiền', () async {
      final proof = ProofModel(
        id: 'proof_dup_01',
        challengeId: sampleChallenge.id,
        challengeTitle: sampleChallenge.title,
        memberName: 'Trần Văn B',
        imagePath: '/local/proof_dup_01.jpg',
        ocrExtractedText: '05:45 AM',
        submittedAt: DateTime(2026, 11, 27, 5, 45),
        status: ProofStatus.pending,
        rewardAmount: 25000,
      );
      await repo.submitProof(proof);

      final first = await repo.approveProofAndCreditFund(proof.id);
      expect(first.approved, isTrue);

      final second = await repo.approveProofAndCreditFund(proof.id);
      expect(second.approved, isFalse);
      expect(second.status, ApprovalCreditStatus.alreadyProcessed);

      final txs = await repo.getTransactions();
      final creditedForProof = txs.where((t) => t.proofId == proof.id).toList();
      expect(creditedForProof.length, 1);
      expect(await repo.getBalance(), 1025000.0);
    });

    test('5. Từ chối minh chứng (Rejected) không cộng tiền vào quỹ và không thể duyệt lại', () async {
      final proof = ProofModel(
        id: 'proof_reject_01',
        challengeId: sampleChallenge.id,
        challengeTitle: sampleChallenge.title,
        memberName: 'Phạm Thị C',
        imagePath: '/local/proof_reject_01.jpg',
        ocrExtractedText: '07:15 AM',
        submittedAt: DateTime(2026, 11, 27, 7, 15),
        status: ProofStatus.pending,
        rewardAmount: 25000,
      );
      await repo.submitProof(proof);

      final rejected = await repo.rejectProof(
        proof.id,
        reason: 'Ảnh chụp sau 6h00 sáng',
      );
      expect(rejected, isTrue);
      expect(await repo.getBalance(), 1000000.0);

      final approveAfterReject = await repo.approveProofAndCreditFund(proof.id);
      expect(approveAfterReject.approved, isFalse);
      expect(approveAfterReject.status, ApprovalCreditStatus.alreadyProcessed);
      expect(await repo.getBalance(), 1000000.0);
    });
  });
}
