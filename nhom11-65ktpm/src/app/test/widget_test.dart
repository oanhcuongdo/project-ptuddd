import 'package:flutter_test/flutter_test.dart';
import 'package:chailish/main.dart';

void main() {
  testWidgets('ChaiLishApp renders HomeScreen with title', (WidgetTester tester) async {
    await tester.pumpWidget(const ChaiLishApp());
    await tester.pumpAndSettle();
    expect(find.text('学中文 · Học tiếng Trung mỗi ngày'), findsOneWidget);
    expect(find.text('Tính Năng Cốt Lõi'), findsOneWidget);
    expect(find.text('Trợ Lý AI Ôn Bài'), findsOneWidget);
  });
}
