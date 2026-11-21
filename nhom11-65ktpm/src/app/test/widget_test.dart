import 'package:flutter_test/flutter_test.dart';
import 'package:chailish/main.dart';

void main() {
  testWidgets('ChaiLishApp renders HomeScreen with title', (WidgetTester tester) async {
    await tester.pumpWidget(const ChaiLishApp());
    expect(find.text('ChaiLish - 学中文'), findsOneWidget);
    expect(find.text('Tính Năng Cốt Lõi'), findsOneWidget);
  });
}
