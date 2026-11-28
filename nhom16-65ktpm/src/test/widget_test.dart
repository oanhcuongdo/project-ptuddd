import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/main.dart';

void main() {
  testWidgets('App renders GoodDeedsFund title smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GoodDeedsFundApp());
    expect(find.text('GoodDeeds Fund'), findsOneWidget);
  });
}
