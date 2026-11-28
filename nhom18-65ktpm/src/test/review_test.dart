import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketnoitinhnguyenvienxemay/core/theme.dart';
import 'package:ketnoitinhnguyenvienxemay/features/review/review_rules.dart';
import 'package:ketnoitinhnguyenvienxemay/features/review/widgets/review_form.dart';
import 'package:ketnoitinhnguyenvienxemay/repositories/auth_repository.dart';

void main() {
  test('validateRating chỉ nhận 1..5 sao', () {
    expect(validateRating(null), isNotNull);
    expect(validateRating(0), isNotNull);
    expect(validateRating(6), isNotNull);
    expect(validateRating(1), isNull);
    expect(validateRating(5), isNull);
  });

  test('validateReviewComment giới hạn 500 ký tự, cho phép bỏ trống', () {
    expect(validateReviewComment(null), isNull);
    expect(validateReviewComment(''), isNull);
    expect(validateReviewComment('a' * 500), isNull);
    expect(validateReviewComment('a' * 501), isNotNull);
  });

  Future<void> pumpForm(
    WidgetTester tester,
    Future<void> Function(int, String?) onSubmit,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ReviewForm(shopName: 'Sửa xe A', onSubmit: onSubmit),
        ),
      ),
    );
  }

  testWidgets('ReviewForm báo lỗi khi chưa chọn sao và không gửi', (
    tester,
  ) async {
    var calls = 0;
    await pumpForm(tester, (_, _) async => calls++);

    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pump();

    expect(find.text('Vui lòng chọn số sao trước khi gửi'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('ReviewForm gửi số sao đã chọn và nội dung', (tester) async {
    int? sentRating;
    String? sentComment;
    await pumpForm(tester, (rating, comment) async {
      sentRating = rating;
      sentComment = comment;
    });

    await tester.tap(find.byTooltip('4 sao'));
    await tester.enterText(find.byType(TextField), 'Thợ nhiệt tình');
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pump();

    expect(sentRating, 4);
    expect(sentComment, 'Thợ nhiệt tình');
  });

  testWidgets('ReviewForm hiện lỗi mạng từ repository', (tester) async {
    await pumpForm(tester, (_, _) async {
      throw const AppException('Không thể kết nối mạng, vui lòng thử lại sau.');
    });

    await tester.tap(find.byTooltip('5 sao'));
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pump();

    expect(
      find.text('Không thể kết nối mạng, vui lòng thử lại sau.'),
      findsOneWidget,
    );
  });
}
