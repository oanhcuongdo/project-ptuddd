import 'package:chailish/core/theme/app_theme.dart';
import 'package:chailish/features/dev/dev_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu dev hiện trạng thái hợp đồng và tạo được dữ liệu giả', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.lightTheme, home: const DevMenuScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Chưa đăng nhập'), findsOneWidget);
    expect(find.textContaining('0 sự kiện'), findsOneWidget);
    // Thẻ đầu không bị thanh tiêu đề che.
    final appBarBottom = tester.getBottomLeft(find.text('Menu dev')).dy;
    expect(tester.getTopLeft(find.text('Tài khoản')).dy, greaterThan(appBarBottom));

    await tester.tap(find.byKey(const Key('dev-generate')));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.byKey(const Key('dev-progress'))).data!;
    expect(text, isNot(startsWith('0 sự kiện')));
    expect(text, contains('streak'));

    await tester.scrollUntilVisible(find.text('Hợp đồng giữa các tính năng'), 300);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('GIẢ'), findsWidgets);
  });
}
