/// Dữ liệu mẫu dùng chung cho toàn bộ giao diện prototype.
/// Thành viên từng module sẽ thay dần dữ liệu này bằng Riverpod Provider + Firestore.
class MockMember {
  const MockMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.role,
    required this.isHost,
    required this.isOnline,
    required this.contributedAmount,
    required this.targetAmount,
    required this.currentCycleStatus,
    required this.streakWeeks,
  });

  final String id;
  final String name;
  final String initials;
  final String role;
  final bool isHost;
  final bool isOnline;
  final int contributedAmount;
  final int targetAmount;
  final String currentCycleStatus; // 'confirmed' | 'pending' | 'unpaid'
  final int streakWeeks;
}

class MockReceiptRequest {
  const MockReceiptRequest({
    required this.id,
    required this.memberName,
    required this.memberInitials,
    required this.cycleLabel,
    required this.amount,
    required this.submittedAt,
    required this.moodEmoji,
    required this.note,
    required this.momoTransId,
    required this.status,
  });

  final String id;
  final String memberName;
  final String memberInitials;
  final String cycleLabel;
  final int amount;
  final String submittedAt;
  final String moodEmoji;
  final String note;
  final String momoTransId;
  final String status; // 'pending' | 'approved' | 'rejected'
}

class MockChecklistItem {
  MockChecklistItem({
    required this.id,
    required this.title,
    required this.groupLabel,
    required this.assignee,
    required this.isDone,
    required this.hasProofPhoto,
    required this.isPacking,
  });

  final String id;
  final String title;
  final String groupLabel;
  String? assignee;
  bool isDone;
  bool hasProofPhoto;
  final bool isPacking;
}

class MockActivity {
  const MockActivity({
    required this.id,
    required this.dayIndex,
    required this.timeRange,
    required this.title,
    required this.category,
    required this.estimatedCost,
    required this.status, // 'done' | 'ongoing' | 'conflict' | 'upcoming'
    required this.address,
  });

  final String id;
  final int dayIndex;
  final String timeRange;
  final String title;
  final String category;
  final String estimatedCost;
  final String status;
  final String address;
}

class MockBudgetEnvelope {
  const MockBudgetEnvelope({
    required this.category,
    required this.planned,
    required this.spent,
    required this.iconName,
  });

  final String category;
  final int planned;
  final int spent;
  final String iconName;
}

class MockExpense {
  const MockExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.payerName,
    required this.amount,
    required this.dateTime,
    required this.splitCount,
  });

  final String id;
  final String title;
  final String category;
  final String payerName;
  final int amount;
  final String dateTime;
  final int splitCount;
}

class MockTripData {
  MockTripData._();

  static const String tripName = 'Đà Lạt 4N3Đ';
  static const String tripDestination = 'TP. Đà Lạt, Lâm Đồng';
  static const String tripDateRange = '15/11 – 18/11/2026';
  static const String inviteCode = 'DL-2026-G8';
  static const int daysUntilTrip = 14;
  static const int totalTargetFund = 8450000;
  static const int currentSavedFund = 5070000;
  static const int perMemberCycleAmount = 212000;
  static const String currentCycleLabel = 'Kỳ 6/10';
  static const String currentCycleDue = 'CN 22/11';

  static const String momoFundName = 'Quỹ Đà Lạt 4N3Đ - Nhóm 8';
  static const String momoFundLink = 'https://me.momo.vn/quy-nhom-dl-g8';
  static const bool isMomoLinked = true;

  /// Đồng bộ 4 thành viên khớp trang bìa Đề cương v3 (Nhóm 8 - K65 KTPM)
  static const List<MockMember> members = [
    MockMember(
      id: 'm1',
      name: 'Đỗ Đình An',
      initials: 'ĐA',
      role: 'Trưởng nhóm',
      isHost: true,
      isOnline: true,
      contributedAmount: 1484000,
      targetAmount: 2112500,
      currentCycleStatus: 'confirmed',
      streakWeeks: 6,
    ),
    MockMember(
      id: 'm2',
      name: 'Nguyễn Xuân Bình',
      initials: 'XB',
      role: 'Thành viên',
      isHost: false,
      isOnline: true,
      contributedAmount: 1272000,
      targetAmount: 2112500,
      currentCycleStatus: 'pending',
      streakWeeks: 5,
    ),
    MockMember(
      id: 'm3',
      name: 'Đỗ Tùng Khánh',
      initials: 'TK',
      role: 'Thành viên',
      isHost: false,
      isOnline: false,
      contributedAmount: 1272000,
      targetAmount: 2112500,
      currentCycleStatus: 'pending',
      streakWeeks: 5,
    ),
    MockMember(
      id: 'm4',
      name: 'Hồ Thế Dũng',
      initials: 'TD',
      role: 'Thành viên',
      isHost: false,
      isOnline: true,
      contributedAmount: 1042000,
      targetAmount: 2112500,
      currentCycleStatus: 'unpaid',
      streakWeeks: 4,
    ),
  ];

  static const List<MockReceiptRequest> receiptRequests = [
    MockReceiptRequest(
      id: 'r1',
      memberName: 'Nguyễn Xuân Bình',
      memberInitials: 'XB',
      cycleLabel: 'Kỳ 6/10',
      amount: 212000,
      submittedAt: 'Hôm nay • 15:20',
      moodEmoji: '🔥',
      note: 'Nhịn 2 ly trà sữa góp quỹ đúng hạn!',
      momoTransId: 'MM2026112588412',
      status: 'pending',
    ),
    MockReceiptRequest(
      id: 'r2',
      memberName: 'Đỗ Tùng Khánh',
      memberInitials: 'TK',
      cycleLabel: 'Kỳ 6/10',
      amount: 212000,
      submittedAt: 'Hôm nay • 14:05',
      moodEmoji: '😎',
      note: 'Đã nạp đủ tuần 6 qua Quỹ nhóm MoMo',
      momoTransId: 'MM2026112577109',
      status: 'pending',
    ),
    MockReceiptRequest(
      id: 'r3',
      memberName: 'Đỗ Đình An',
      memberInitials: 'ĐA',
      cycleLabel: 'Kỳ 6/10',
      amount: 212000,
      submittedAt: 'Hôm qua • 20:10',
      moodEmoji: '🚀',
      note: 'Trưởng nhóm gương mẫu chốt sớm',
      momoTransId: 'MM2026112460321',
      status: 'approved',
    ),
  ];

  static List<MockChecklistItem> initialChecklist() => [
        // Việc theo mốc thời gian
        MockChecklistItem(
          id: 't1',
          title: 'Đặt vé xe giường nằm khứ hồi',
          groupLabel: 'Trước 30 ngày',
          assignee: 'Đình An',
          isDone: true,
          hasProofPhoto: true,
          isPacking: false,
        ),
        MockChecklistItem(
          id: 't2',
          title: 'Đặt cọc Homestay Đồi Thông',
          groupLabel: 'Trước 30 ngày',
          assignee: 'Xuân Bình',
          isDone: true,
          hasProofPhoto: true,
          isPacking: false,
        ),
        MockChecklistItem(
          id: 't3',
          title: 'Liên hệ thuê 4 xe máy tại Đà Lạt',
          groupLabel: 'Trước 14 ngày',
          assignee: 'Tùng Khánh',
          isDone: false,
          hasProofPhoto: false,
          isPacking: false,
        ),
        MockChecklistItem(
          id: 't4',
          title: 'Chốt bảo hiểm du lịch & danh sách quán ăn',
          groupLabel: 'Trước 14 ngày',
          assignee: null,
          isDone: false,
          hasProofPhoto: false,
          isPacking: false,
        ),
        MockChecklistItem(
          id: 't5',
          title: 'Kiểm tra dự báo thời tiết & xác nhận lại phòng',
          groupLabel: 'Trước 3 ngày',
          assignee: 'Thế Dũng',
          isDone: false,
          hasProofPhoto: false,
          isPacking: false,
        ),
        // Hành lý & đồ dùng chung
        MockChecklistItem(
          id: 'p1',
          title: 'Lều 4 người + bạt lót',
          groupLabel: 'Cắm trại & Ngoài trời',
          assignee: 'Đình An',
          isDone: true,
          hasProofPhoto: true,
          isPacking: true,
        ),
        MockChecklistItem(
          id: 'p2',
          title: 'Đèn pin sạc dự phòng',
          groupLabel: 'Cắm trại & Ngoài trời',
          assignee: 'Xuân Bình',
          isDone: false,
          hasProofPhoto: false,
          isPacking: true,
        ),
        MockChecklistItem(
          id: 'p3',
          title: 'Thuốc say xe & băng gạc y tế',
          groupLabel: 'Y tế & Điện tử',
          assignee: 'Tùng Khánh',
          isDone: false,
          hasProofPhoto: false,
          isPacking: true,
        ),
        MockChecklistItem(
          id: 'p4',
          title: 'Ổ cắm điện nối dài 4 lỗ',
          groupLabel: 'Y tế & Điện tử',
          assignee: null,
          isDone: false,
          hasProofPhoto: false,
          isPacking: true,
        ),
      ];

  static const List<MockActivity> activities = [
    MockActivity(
      id: 'a1',
      dayIndex: 0,
      timeRange: '07:30 – 08:30',
      title: 'Bánh mì xíu mại Hoàng Diệu',
      category: 'Ăn uống',
      estimatedCost: '160.000đ',
      status: 'done',
      address: '26 Hoàng Diệu, P.5, Đà Lạt',
    ),
    MockActivity(
      id: 'a2',
      dayIndex: 0,
      timeRange: '09:30 – 11:30',
      title: 'Đồi Chè Cầu Đất',
      category: 'Tham quan',
      estimatedCost: 'Miễn phí',
      status: 'ongoing',
      address: 'Xuân Trường, TP. Đà Lạt',
    ),
    MockActivity(
      id: 'a3',
      dayIndex: 0,
      timeRange: '14:00 – 15:30',
      title: 'Cà phê Túi Mơ To',
      category: 'Ăn uống',
      estimatedCost: '240.000đ',
      status: 'conflict',
      address: 'Hẻm 31 Sào Nam, P.11, Đà Lạt',
    ),
    MockActivity(
      id: 'a4',
      dayIndex: 0,
      timeRange: '19:00 – 20:30',
      title: 'Lẩu Gà Lá É Tao Ngộ',
      category: 'Ăn uống',
      estimatedCost: '680.000đ',
      status: 'upcoming',
      address: '5 Đường 3/4, P.3, Đà Lạt',
    ),
    MockActivity(
      id: 'a5',
      dayIndex: 1,
      timeRange: '08:00 – 10:30',
      title: 'Săn mây Đồi Đa Phú',
      category: 'Tham quan',
      estimatedCost: '120.000đ',
      status: 'upcoming',
      address: 'P.7, TP. Đà Lạt',
    ),
  ];

  static const List<MockBudgetEnvelope> envelopes = [
    MockBudgetEnvelope(category: 'Lưu trú', planned: 3200000, spent: 2960000, iconName: 'hotel'),
    MockBudgetEnvelope(category: 'Ăn uống', planned: 2400000, spent: 1680000, iconName: 'restaurant'),
    MockBudgetEnvelope(category: 'Di chuyển', planned: 1600000, spent: 1200000, iconName: 'two_wheeler'),
    MockBudgetEnvelope(category: 'Vé tham quan', planned: 750000, spent: 340000, iconName: 'confirmation_number'),
    MockBudgetEnvelope(category: 'Dự phòng', planned: 500000, spent: 0, iconName: 'shield'),
  ];

  static const List<MockExpense> expenses = [
    MockExpense(
      id: 'e1',
      title: 'Lẩu Gà Lá É Tao Ngộ',
      category: 'Ăn uống',
      payerName: 'Đỗ Đình An',
      amount: 680000,
      dateTime: '15/11/2026 • 19:45',
      splitCount: 4,
    ),
    MockExpense(
      id: 'e2',
      title: 'Homestay Đồi Thông',
      category: 'Lưu trú',
      payerName: 'Nguyễn Xuân Bình',
      amount: 2960000,
      dateTime: '15/11/2026 • 14:10',
      splitCount: 4,
    ),
    MockExpense(
      id: 'e3',
      title: 'Thuê xe máy 4 chiếc',
      category: 'Di chuyển',
      payerName: 'Đỗ Tùng Khánh',
      amount: 1200000,
      dateTime: '15/11/2026 • 09:00',
      splitCount: 4,
    ),
  ];

  static String formatVnd(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return '${value < 0 ? '-' : ''}${buf.toString()}đ';
  }
}
