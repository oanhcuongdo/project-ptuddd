import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_factory_setup.dart';
import '../models/challenge_model.dart';
import '../models/fund_transaction_model.dart';
import '../models/proof_model.dart';
import '../models/user_model.dart';
import '../services/proof_approval_credit_helper.dart';

/// DatabaseHelper - Quản lý lưu trữ SQLite đa nền tảng (Cross-Platform Storage)
/// Hỗ trợ mượt mà trên:
/// 1. Android / iOS (Mobile / Máy ảo Emulator) -> Native SQLite qua sqflite
/// 2. Windows / macOS / Linux (Desktop) -> sqflite_common_ffi
/// 3. Web (Chrome / Edge / Firefox) -> sqflite_common_ffi_web qua Wasm & Web Worker (lưu trữ IndexedDB)
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'gooddeeds_fund.db';
  static const int _dbVersion = 2;

  // Tên các bảng
  static const String tableChallenges = 'challenges';
  static const String tableProofs = 'proofs';
  static const String tableFundTransactions = 'fund_transactions';
  static const String tableUsers = 'users';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Khởi tạo databaseFactory tương ứng với nền tảng hiện tại (Desktop FFI / Web Wasm)
    setupDatabaseFactory();

    try {
      final dbPath = await getDatabasesPath();
      final path = kIsWeb ? _dbName : p.join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: _dbVersion,
        onConfigure: (db) async {
          // Bật ràng buộc khóa ngoại trên SQLite
          try {
            await db.execute('PRAGMA foreign_keys = ON');
          } catch (_) {}
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // Fallback an toàn cho môi trường test VM nếu chưa nạp driver
      debugPrint('[DatabaseHelper] Fallback mở database inMemory: $e');
      return await openDatabase(
        inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
      );
    }
  }

  /// Tạo cấu trúc 4 bảng: challenges, proofs, fund_transactions, users
  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng challenges
    await db.execute('''
      CREATE TABLE $tableChallenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        rewardAmount REAL NOT NULL,
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Bảng proofs
    await db.execute('''
      CREATE TABLE $tableProofs (
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
        FOREIGN KEY (challengeId) REFERENCES $tableChallenges (id)
      )
    ''');

    // 3. Bảng fund_transactions
    await db.execute('''
      CREATE TABLE $tableFundTransactions (
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
        FOREIGN KEY (proofId) REFERENCES $tableProofs (id)
      )
    ''');

    // 4. Bảng users
    await _createUsersTable(db);

    // Chèn dữ liệu mẫu ban đầu (Seed Data)
    await _seedInitialData(db);
    await _seedUsersData(db);
  }

  /// Tạo bảng users lưu trữ tài khoản người dùng và phân quyền
  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        studentId TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        avatar TEXT,
        password TEXT NOT NULL
      )
    ''');
  }

  /// Nâng cấp CSDL khi version tăng
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUsersTable(db);
      await _seedUsersData(db);
    }
  }

  /// Nạp sẵn 4 tài khoản của 4 thành viên nhóm 16 vào SQLite
  Future<void> _seedUsersData(Database db) async {
    const defaultUsers = [
      UserModel(
        id: 'usr_01',
        name: 'Nguyễn Văn Huỳnh',
        studentId: '2351170599',
        email: 'huynh@gooddeeds.vn',
        role: 'admin',
        password: 'GoodDeeds@2026',
      ),
      UserModel(
        id: 'usr_02',
        name: 'Lê Anh Tuấn',
        studentId: '2151060296',
        email: 'latuan@gooddeeds.vn',
        role: 'member',
        password: 'GoodDeeds@2026',
      ),
      UserModel(
        id: 'usr_03',
        name: 'Nguyễn Trung Kiên',
        studentId: '2251172394',
        email: 'kien@gooddeeds.vn',
        role: 'member',
        password: 'GoodDeeds@2026',
      ),
      UserModel(
        id: 'usr_04',
        name: 'Trần Anh Tuấn',
        studentId: '2351170629',
        email: 'tatuan@gooddeeds.vn',
        role: 'member',
        password: 'GoodDeeds@2026',
      ),
    ];

    for (final u in defaultUsers) {
      await db.insert(
        tableUsers,
        u.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Khởi tạo dữ liệu mẫu ban đầu cho chiến dịch
  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    final defaultChallenges = [
      const ChallengeModel(
        id: 'ch_01',
        title: 'Dậy sớm trước 6:00 sáng',
        description: 'Chụp ảnh bàn học, đồng hồ hoặc app báo thức chứng minh bạn đã dậy và học bài trước 6h00.',
        rewardAmount: 20000,
        category: 'Kỷ luật',
        icon: 'wb_sunny',
      ),
      const ChallengeModel(
        id: 'ch_02',
        title: 'Gia sư dạy học cho trẻ em',
        description: 'Dạy kèm 1 buổi học (toán, tiếng Việt, tiếng Anh) cho các em nhỏ có hoàn cảnh khó khăn.',
        rewardAmount: 50000,
        category: 'Gia sư',
        icon: 'school',
      ),
      const ChallengeModel(
        id: 'ch_03',
        title: 'Giải 5 bài toán tư duy / code thuật toán',
        description: 'Chụp ảnh bài giải hoặc commit code trên nền tảng LeetCode/HackerRank rèn luyện tư duy.',
        rewardAmount: 30000,
        category: 'Học tập',
        icon: 'psychology',
      ),
      const ChallengeModel(
        id: 'ch_04',
        title: 'Chạy bộ 3km hoặc rèn luyện thể thao',
        description: 'Chụp ảnh màn hình ứng dụng Strava / Smartwatch ghi nhận hoạt động chạy bộ nâng cao sức khỏe.',
        rewardAmount: 25000,
        category: 'Sức khỏe',
        icon: 'directions_run',
      ),
    ];

    for (final ch in defaultChallenges) {
      await db.insert(tableChallenges, ch.toMap());
    }

    final initialTx = FundTransactionModel(
      id: 'tx_init_01',
      type: TransactionType.thu,
      amount: 2000000,
      title: 'Tài trợ mở quỹ từ Cựu sinh viên KTPM',
      category: 'Tài trợ mở quỹ',
      note: 'Khoản tài trợ ban đầu của cựu sinh viên khóa 60 cho GoodDeeds Fund',
      recipientOrSponsor: 'Cựu sinh viên Khoa CNTT',
      createdAt: now.subtract(const Duration(days: 10)),
    );
    await db.insert(tableFundTransactions, initialTx.toMap());
  }

  // ==========================================
  // 1. CRUD CHO BẢNG CHALLENGES
  // ==========================================
  Future<List<ChallengeModel>> getAllChallenges() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableChallenges);
    return maps.map((map) => ChallengeModel.fromMap(map)).toList();
  }

  Future<ChallengeModel?> getChallengeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableChallenges,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ChallengeModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertChallenge(ChallengeModel challenge) async {
    final db = await database;
    return await db.insert(
      tableChallenges,
      challenge.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // 2. CRUD CHO BẢNG PROOFS
  // ==========================================
  Future<List<ProofModel>> getAllProofs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProofs,
      orderBy: 'submittedAt DESC',
    );
    return maps.map((map) => ProofModel.fromMap(map)).toList();
  }

  Future<List<ProofModel>> getPendingProofs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProofs,
      where: 'status = ?',
      whereArgs: [ProofStatus.pending.name],
      orderBy: 'submittedAt DESC',
    );
    return maps.map((map) => ProofModel.fromMap(map)).toList();
  }

  Future<int> insertProof(ProofModel proof) async {
    final db = await database;
    return await db.insert(
      tableProofs,
      proof.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Hỗ trợ truyền cơ sở dữ liệu in-memory độc lập trong môi trường kiểm thử tự động.
  @visibleForTesting
  Future<void> setDatabaseForTesting(Database? testDb) async {
    _database = testDb;
  }

  /// Duyệt minh chứng & tự động cộng tiền THU vào quỹ (trả về kết quả chi tiết):
  /// 1. Kiểm tra tồn tại, trạng thái pending, số tiền thưởng > 0 và chống cộng trùng theo proofId
  /// 2. Truy vấn đúng danh mục (`category`) từ bảng `challenges`
  /// 3. Cập nhật trạng thái Proof sang 'approved' & tự động ghi nhận giao dịch THU đính kèm ảnh minh chứng
  /// 4. Tính toán số dư mới nhất ngay trong cùng SQLite transaction nguyên tử
  Future<ApprovalCreditResult> approveProofAndCreditFund(
    String proofId, {
    String? adminFeedback,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(
        tableProofs,
        where: 'id = ?',
        whereArgs: [proofId],
        limit: 1,
      );

      if (maps.isEmpty) {
        return const ApprovalCreditResult(
          approved: false,
          status: ApprovalCreditStatus.notFound,
          message: 'Không tìm thấy minh chứng cần phê duyệt.',
        );
      }

      final proof = ProofModel.fromMap(maps.first);

      if (!proof.isPending) {
        return const ApprovalCreditResult(
          approved: false,
          status: ApprovalCreditStatus.alreadyProcessed,
          message: 'Minh chứng này đã được xử lý trước đó.',
        );
      }

      if (proof.rewardAmount <= 0) {
        return const ApprovalCreditResult(
          approved: false,
          status: ApprovalCreditStatus.invalidRewardAmount,
          message: 'Số tiền thưởng của minh chứng phải lớn hơn 0.',
        );
      }

      // Chống cộng trùng tiền Thu nếu đã có giao dịch gắn với proofId này
      final existingTx = await txn.query(
        tableFundTransactions,
        columns: ['id'],
        where: 'proofId = ? AND type = ?',
        whereArgs: [proof.id, TransactionType.thu.name],
        limit: 1,
      );
      if (existingTx.isNotEmpty) {
        return const ApprovalCreditResult(
          approved: false,
          status: ApprovalCreditStatus.duplicateTransaction,
          message: 'Minh chứng này đã được cộng tiền Thu vào quỹ trước đó.',
        );
      }

      // Lấy đúng thông tin thử thách gốc để đồng bộ chính xác `category`
      ChallengeModel? challenge;
      final challengeMaps = await txn.query(
        tableChallenges,
        where: 'id = ?',
        whereArgs: [proof.challengeId],
        limit: 1,
      );
      if (challengeMaps.isNotEmpty) {
        challenge = ChallengeModel.fromMap(challengeMaps.first);
      }

      final normalizedFeedback =
          ProofApprovalCreditHelper.normalizeFeedback(adminFeedback);

      // Cập nhật trạng thái proof sang Approved (chỉ cập nhật khi vẫn đang Pending)
      final updatedCount = await txn.update(
        tableProofs,
        {
          'status': ProofStatus.approved.name,
          'adminFeedback': normalizedFeedback,
        },
        where: 'id = ? AND status = ?',
        whereArgs: [proofId, ProofStatus.pending.name],
      );

      if (updatedCount == 0) {
        return const ApprovalCreditResult(
          approved: false,
          status: ApprovalCreditStatus.alreadyProcessed,
          message: 'Minh chứng này đã được xử lý trước đó.',
        );
      }

      // Tự động sinh giao dịch THU chuẩn vào bảng `fund_transactions`
      final newTx = ProofApprovalCreditHelper.buildIncomeTransaction(
        proof: proof,
        challenge: challenge,
        adminFeedback: adminFeedback,
      );
      await txn.insert(tableFundTransactions, newTx.toMap());

      // Tính toán số dư quỹ mới nhất ngay trong transaction
      final incomeRes = await txn.rawQuery(
        'SELECT SUM(amount) as total FROM $tableFundTransactions WHERE type = ?',
        [TransactionType.thu.name],
      );
      final expenseRes = await txn.rawQuery(
        'SELECT SUM(amount) as total FROM $tableFundTransactions WHERE type = ?',
        [TransactionType.chi.name],
      );
      final totalIncome = (incomeRes.first['total'] as num?)?.toDouble() ?? 0.0;
      final totalExpense =
          (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;

      return ApprovalCreditResult(
        approved: true,
        status: ApprovalCreditStatus.credited,
        message:
            'Đã duyệt minh chứng của ${proof.memberName} và tự động cộng quỹ thành công.',
        transaction: newTx,
        newBalance: totalIncome - totalExpense,
      );
    });
  }

  /// Duyệt minh chứng (tương thích ngược trả về bool):
  /// 1. Cập nhật trạng thái Proof sang 'approved'
  /// 2. Tự động sinh bản ghi THU tương ứng trong bảng `fund_transactions`
  Future<bool> approveProof(String proofId, {String? adminFeedback}) async {
    final result = await approveProofAndCreditFund(
      proofId,
      adminFeedback: adminFeedback,
    );
    return result.approved;
  }

  /// Từ chối minh chứng kèm lý do
  Future<bool> rejectProof(String proofId, {required String reason}) async {
    final db = await database;
    final count = await db.update(
      tableProofs,
      {
        'status': ProofStatus.rejected.name,
        'adminFeedback': reason,
      },
      where: 'id = ? AND status = ?',
      whereArgs: [proofId, ProofStatus.pending.name],
    );
    return count > 0;
  }

  // ==========================================
  // 3. CRUD CHO BẢNG FUND_TRANSACTIONS (SỔ QUỸ)
  // ==========================================
  Future<List<FundTransactionModel>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFundTransactions,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => FundTransactionModel.fromMap(map)).toList();
  }

  Future<int> insertTransaction(FundTransactionModel tx) async {
    final db = await database;
    return await db.insert(
      tableFundTransactions,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $tableFundTransactions WHERE type = ?
    ''', [TransactionType.thu.name]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $tableFundTransactions WHERE type = ?
    ''', [TransactionType.chi.name]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (fromDate != null) {
      whereClauses.add('createdAt >= ?');
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClauses.add('createdAt <= ?');
      whereArgs.add(toDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      tableFundTransactions,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => FundTransactionModel.fromMap(map)).toList();
  }

  // ==========================================
  // 4. CRUD CHO BẢNG USERS (TÀI KHOẢN & PHÂN QUYỀN)
  // ==========================================
  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableUsers);
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> authenticateUser(String account, String password) async {
    final db = await database;
    final cleanAccount = account.trim().toLowerCase();
    final cleanPassword = password.trim();

    final List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      where: 'LOWER(email) = ? OR studentId = ?',
      whereArgs: [cleanAccount, cleanAccount],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final user = UserModel.fromMap(maps.first);

    // Xác thực mật khẩu: chỉ khớp chính xác mật khẩu đang lưu trong CSDL
    if (user.password == cleanPassword) {
      return user;
    }
    return null;
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateUserPassword(String userId, String newPassword) async {
    final db = await database;
    return await db.update(
      tableUsers,
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
