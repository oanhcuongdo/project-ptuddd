import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';
import 'package:gooddeeds_fund/features/challenges/challenge_detail_screen.dart';

void main() {
  group('ChallengeDetailScreen Widget Tests (Task 2)', () {
    const testChallenge = ChallengeModel(
      id: 'ch_test_01',
      title: 'Dậy sớm trước 6:00 sáng học bài',
      description: 'Chụp ảnh bàn học kèm đồng hồ rõ mốc thời gian.',
      rewardAmount: 20000,
      category: 'Kỷ luật',
      icon: 'alarm',
    );

    testWidgets('Hiển thị đầy đủ thông tin chi tiết thử thách và mức thưởng',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChallengeDetailScreen(challenge: testChallenge),
        ),
      );

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Chi Tiết Thử Thách'), findsOneWidget);

      // Kiểm tra tiêu đề thử thách & danh mục
      expect(find.text('Dậy sớm trước 6:00 sáng học bài'), findsOneWidget);
      expect(find.text('KỶ LUẬT'), findsOneWidget);

      // Kiểm tra mức thưởng
      expect(find.text('+20.000\u00a0đ'), findsWidgets);

      // Kiểm tra thể lệ & tiêu chuẩn AI OCR
      expect(find.text('Thể Lệ & Các Bước Thực Hiện'), findsOneWidget);
      expect(find.text('Tiêu Chuẩn Ảnh Chụp (AI OCR)'), findsOneWidget);

      // Kiểm tra nút CTA
      expect(find.text('Tham Gia & Nộp Minh Chứng'), findsOneWidget);
    });

    testWidgets('Bấm nút CTA gọi callback onJoinNow thành công',
        (WidgetTester tester) async {
      var joined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChallengeDetailScreen(
            challenge: testChallenge,
            onJoinNow: () => joined = true,
          ),
        ),
      );

      final ctaButton = find.text('Tham Gia & Nộp Minh Chứng');
      expect(ctaButton, findsOneWidget);

      await tester.tap(ctaButton);
      await tester.pumpAndSettle();

      expect(joined, isTrue);
    });
  });
}
