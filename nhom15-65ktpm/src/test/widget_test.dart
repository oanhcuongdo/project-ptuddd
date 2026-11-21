import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/shared/widgets/kid_button.dart';

void main() {
  testWidgets('KidButton renders label and triggers callback on tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KidButton(
            onPressed: () => tapped = true,
            label: 'Bắt Đầu',
          ),
        ),
      ),
    );

    expect(find.text('Bắt Đầu'), findsOneWidget);
    await tester.tap(find.text('Bắt Đầu'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
