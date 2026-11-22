import 'package:flutter_test/flutter_test.dart';
import 'package:buddytalk/app/buddytalk_app.dart';
import 'package:buddytalk/app/router/routes/index.dart';

void main() {
  setUpAll(() {
    registerAllRoutes();
  });

  testWidgets('BuddyTalkApp mở MainLayout và chuyển sang màn hình Đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(const BuddyTalkApp());
    await tester.pumpAndSettle();

    expect(find.text('BuddyTalk'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);

    await tester.tap(find.text('Đăng nhập / Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
  });
}
