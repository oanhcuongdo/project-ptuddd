import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/core/services/auth_service.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';
import 'package:gooddeeds_fund/data/repositories/challenge_repository.dart';
import 'package:gooddeeds_fund/features/challenges/challenge_list_screen.dart';

class _InMemoryChallengeRepository implements IChallengeRepository {
  final List<ChallengeModel> _items = [
    const ChallengeModel(
      id: 'ch_01',
      title: 'Dậy sớm trước 6:00 sáng',
      description: 'Chụp ảnh bàn học kèm đồng hồ.',
      rewardAmount: 20000,
      category: 'Kỷ luật',
      icon: 'wb_sunny',
    ),
    const ChallengeModel(
      id: 'ch_02',
      title: 'Gia sư dạy học cho trẻ em',
      description: 'Dạy kèm 1 buổi học cho trẻ em khó khăn.',
      rewardAmount: 50000,
      category: 'Gia sư',
      icon: 'school',
    ),
  ];

  @override
  Future<List<ChallengeModel>> getChallenges() async => List.of(_items);

  @override
  Future<ChallengeModel?> getChallengeById(String id) async {
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<int> addChallenge(ChallengeModel challenge) async {
    final idx = _items.indexWhere((e) => e.id == challenge.id);
    if (idx >= 0) {
      _items[idx] = challenge;
    } else {
      _items.add(challenge);
    }
    return 1;
  }
}

void main() {
  group('ChallengeListScreen Widget Tests', () {
    tearDown(() {
      AuthService.instance.logout();
    });

    testWidgets('Thành viên thường chỉ xem, tìm kiếm được và không thấy nút Tạo/Sửa',
        (WidgetTester tester) async {
      AuthService.instance.quickLogin(AuthService.demoAccounts[1]); // Member
      final repo = _InMemoryChallengeRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChallengeListScreen(challengeRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dậy sớm trước 6:00 sáng'), findsOneWidget);
      expect(find.text('Gia sư dạy học cho trẻ em'), findsOneWidget);

      // Không có nút Tạo mới / Edit cho Member
      expect(find.text('Tạo mới'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.text('Nộp ảnh'), findsOneWidget);

      // Lọc theo danh mục Gia sư
      await tester.tap(find.widgetWithText(ChoiceChip, 'Gia sư'));
      await tester.pumpAndSettle();

      expect(find.text('Dậy sớm trước 6:00 sáng'), findsNothing);
      expect(find.text('Gia sư dạy học cho trẻ em'), findsOneWidget);
    });

    testWidgets('Admin thấy nút Tạo mới và Sửa, thêm được thử thách mới',
        (WidgetTester tester) async {
      AuthService.instance.quickLogin(AuthService.demoAccounts[0]); // Admin
      final repo = _InMemoryChallengeRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChallengeListScreen(challengeRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tạo mới'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      // Bấm Tạo mới
      await tester.tap(find.text('Tạo mới'));
      await tester.pumpAndSettle();

      expect(find.text('Tạo Thử Thách Mới'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Tên thử thách *'), 'Đọc 20 trang sách');
      await tester.enterText(
          find.widgetWithText(TextField, 'Mô tả & Thể lệ *'),
          'Chụp ảnh trang sách đang đọc kèm ghi chú.');
      await tester.enterText(
          find.widgetWithText(TextField, 'Mức tài trợ vào Quỹ (VNĐ) *'),
          '35000');

      final submitBtn = find.text('Tạo Thử Thách');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Đọc 20 trang sách'), findsOneWidget);
    });
  });
}
